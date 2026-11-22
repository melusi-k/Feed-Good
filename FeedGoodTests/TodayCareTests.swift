import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct TodayCareTests {
    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    private func makeContext() throws -> ModelContext {
        let schema = Schema([Plant.self, CareTask.self, CareEvent.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        return ModelContext(container)
    }

    @Test func groupsOverdueDueAndUpcomingAndHidesFarFutureAndPaused() throws {
        let context = try makeContext()
        let calendar = calendar("Africa/Johannesburg")
        let now = date("2026-11-21T10:00:00+02:00")
        let plant = Plant(name: "Fern")
        context.insert(plant)
        func add(_ title: String, _ due: String, enabled: Bool = true) {
            let task = CareTask(kind: .custom, customTitle: title, intervalDays: 3, dueDate: date(due), plant: plant)
            task.isEnabled = enabled
            context.insert(task)
        }
        add("overdue", "2026-11-19T09:00:00+02:00")
        add("today-late", "2026-11-21T23:30:00+02:00")
        add("soon", "2026-11-25T09:00:00+02:00")
        add("edge", "2026-11-28T20:00:00+02:00")
        add("far", "2026-11-29T09:00:00+02:00")
        add("paused", "2026-11-20T09:00:00+02:00", enabled: false)
        try context.save()

        let tasks = try context.fetch(FetchDescriptor<CareTask>())
        let items = TodayCare.items(from: tasks, now: now, calendar: calendar)
        #expect(items.map(\.task.title) == ["overdue", "today-late", "soon", "edge"])
        #expect(items.map(\.state) == [.overdue, .due, .upcoming, .upcoming])
    }

    @Test func sameTaskIsDueOrOverdueDependingOnTimeZone() throws {
        let context = try makeContext()
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 2, dueDate: date("2026-11-21T00:30:00Z"), plant: plant)
        context.insert(task)
        try context.save()
        let now = date("2026-11-21T08:30:00Z")
        #expect(TodayCare.items(from: [task], now: now, calendar: calendar("Africa/Johannesburg")).first?.state == .due)
        #expect(TodayCare.items(from: [task], now: now, calendar: calendar("America/Los_Angeles")).first?.state == .overdue)
    }

    @Test func recordingCareFromTodayWritesHistoryAndLeavesTodaysList() throws {
        let context = try makeContext()
        let calendar = calendar("UTC")
        let now = date("2026-11-21T10:00:00Z")
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 10, dueDate: date("2026-11-20T10:00:00Z"), plant: plant)
        context.insert(task)
        try context.save()

        #expect(TodayCare.items(from: [task], now: now, calendar: calendar).map(\.state) == [.overdue])
        try CareRecorder.complete(task, note: "", at: now, in: context, calendar: calendar)

        #expect(try context.fetch(FetchDescriptor<CareEvent>()).count == 1)
        #expect(plant.careEvents?.count == 1)
        // Next care is 10 days out, past the 7 day window, so Today no longer lists it.
        #expect(TodayCare.items(from: [task], now: now, calendar: calendar).isEmpty)
    }

    @Test func plantsWithoutTasksAndOrphanedTasksProduceNoItems() throws {
        let context = try makeContext()
        context.insert(Plant(name: "Cactus"))
        try context.save()
        #expect(TodayCare.items(from: [], now: .now).isEmpty)
    }

    @Test func ordersSameDayByPlantName() throws {
        let context = try makeContext()
        let calendar = calendar("UTC")
        let now = date("2026-11-21T10:00:00Z")
        let due = date("2026-11-21T12:00:00Z")
        let zinnia = Plant(name: "Zinnia")
        let basil = Plant(name: "basil")
        context.insert(zinnia); context.insert(basil)
        let a = CareTask(kind: .watering, intervalDays: 2, dueDate: due, plant: zinnia)
        let b = CareTask(kind: .watering, intervalDays: 2, dueDate: due, plant: basil)
        context.insert(a); context.insert(b)
        try context.save()
        #expect(TodayCare.items(from: [a, b], now: now, calendar: calendar).map(\.plant.name) == ["basil", "Zinnia"])
    }

    @Test func groupsByPlantCapsShownRowsAndKeepsAllCounted() throws {
        let context = try makeContext()
        let calendar = calendar("UTC")
        let now = date("2026-11-21T10:00:00Z")
        let due = date("2026-11-21T12:00:00Z")
        let fern = Plant(name: "Fern")
        let lily = Plant(name: "Lily")
        context.insert(fern); context.insert(lily)
        var tasks: [CareTask] = []
        for index in 0..<5 {
            let task = CareTask(kind: .custom, customTitle: "Fern task \(index)", intervalDays: 7, dueDate: due.addingTimeInterval(Double(index)), plant: fern)
            context.insert(task); tasks.append(task)
        }
        let lilyTask = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: lily)
        context.insert(lilyTask); tasks.append(lilyTask)
        try context.save()

        let groups = TodayCare.groups(from: TodayCare.items(from: tasks, now: now, calendar: calendar), perPlant: 3)
        #expect(groups.map(\.plant.name) == ["Fern", "Lily"])
        #expect(groups[0].items.count == 5)
        #expect(groups[0].shown.map(\.task.title) == ["Fern task 0", "Fern task 1", "Fern task 2"])
        #expect(groups[0].hiddenCount == 2)
        #expect(groups[1].hiddenCount == 0)
    }

    @Test func groupsOfNoItemsIsEmptyAndCapIsAtLeastOne() throws {
        #expect(TodayCare.groups(from: []).isEmpty)
        let context = try makeContext()
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 2, dueDate: .now, plant: plant)
        context.insert(task)
        try context.save()
        let groups = TodayCare.groups(from: TodayCare.items(from: [task]), perPlant: 0)
        #expect(groups.first?.shown.count == 1)
    }
}
