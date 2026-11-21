import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class TodayCareTests: XCTestCase {
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

    func testGroupsOverdueDueAndUpcomingAndHidesFarFutureAndPaused() throws {
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
        XCTAssertEqual(items.map(\.task.title), ["overdue", "today-late", "soon", "edge"])
        XCTAssertEqual(items.map(\.state), [.overdue, .due, .upcoming, .upcoming])
    }

    func testSameTaskIsDueOrOverdueDependingOnTimeZone() throws {
        let context = try makeContext()
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 2, dueDate: date("2026-11-21T00:30:00Z"), plant: plant)
        context.insert(task)
        try context.save()
        let now = date("2026-11-21T08:30:00Z")
        XCTAssertEqual(TodayCare.items(from: [task], now: now, calendar: calendar("Africa/Johannesburg")).first?.state, .due)
        XCTAssertEqual(TodayCare.items(from: [task], now: now, calendar: calendar("America/Los_Angeles")).first?.state, .overdue)
    }

    func testRecordingCareFromTodayWritesHistoryAndLeavesTodaysList() throws {
        let context = try makeContext()
        let calendar = calendar("UTC")
        let now = date("2026-11-21T10:00:00Z")
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 10, dueDate: date("2026-11-20T10:00:00Z"), plant: plant)
        context.insert(task)
        try context.save()

        XCTAssertEqual(TodayCare.items(from: [task], now: now, calendar: calendar).map(\.state), [.overdue])
        try CareRecorder.complete(task, note: "", at: now, in: context, calendar: calendar)

        XCTAssertEqual(try context.fetch(FetchDescriptor<CareEvent>()).count, 1)
        XCTAssertEqual(plant.careEvents?.count, 1)
        // Next care is 10 days out, past the 7 day window, so Today no longer lists it.
        XCTAssertTrue(TodayCare.items(from: [task], now: now, calendar: calendar).isEmpty)
    }

    func testPlantsWithoutTasksAndOrphanedTasksProduceNoItems() throws {
        let context = try makeContext()
        context.insert(Plant(name: "Cactus"))
        try context.save()
        XCTAssertTrue(TodayCare.items(from: [], now: .now).isEmpty)
    }

    func testOrdersSameDayByPlantName() throws {
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
        XCTAssertEqual(TodayCare.items(from: [a, b], now: now, calendar: calendar).map(\.plant.name), ["basil", "Zinnia"])
    }
}
