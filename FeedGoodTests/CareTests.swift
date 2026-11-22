import Foundation
import SwiftData
import Testing
@testable import FeedGood

struct CareScheduleTests {
    private func calendar(_ zone: String) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    @Test func dateStatesRespectLocalDayBoundaries() {
        let calendar = calendar("Africa/Johannesburg")
        let now = ISO8601DateFormatter().date(from: "2026-11-21T00:01:00+02:00")!
        let lastNight = ISO8601DateFormatter().date(from: "2026-11-20T23:59:00+02:00")!
        let tonight = ISO8601DateFormatter().date(from: "2026-11-21T23:59:00+02:00")!
        #expect(CareSchedule.state(for: lastNight, now: now, calendar: calendar) == .overdue)
        #expect(CareSchedule.state(for: tonight, now: now, calendar: calendar) == .due)
        #expect(CareSchedule.state(for: CareSchedule.nextDate(after: now, intervalDays: 1, calendar: calendar), now: now, calendar: calendar) == .upcoming)
    }

    @Test func calendarDaysAcrossDSTAndYearBoundary() {
        let calendar = calendar("America/New_York")
        let beforeDST = ISO8601DateFormatter().date(from: "2026-03-07T09:00:00-05:00")!
        let afterDST = CareSchedule.nextDate(after: beforeDST, intervalDays: 1, calendar: calendar)
        #expect(calendar.component(.hour, from: afterDST) == 9)
        #expect(afterDST.timeIntervalSince(beforeDST) == 23 * 3600)
        let december = ISO8601DateFormatter().date(from: "2026-12-31T09:00:00-05:00")!
        let january = CareSchedule.nextDate(after: december, intervalDays: 1, calendar: calendar)
        #expect(calendar.component(.year, from: january) == 2027)
        #expect(calendar.component(.day, from: january) == 1)
    }

    @Test func sameInstantCanBeDueOrOverdueInDifferentZones() {
        let due = ISO8601DateFormatter().date(from: "2026-11-21T00:30:00Z")!
        let now = ISO8601DateFormatter().date(from: "2026-11-21T08:30:00Z")!
        #expect(CareSchedule.state(for: due, now: now, calendar: calendar("Africa/Johannesburg")) == .due)
        #expect(CareSchedule.state(for: due, now: now, calendar: calendar("America/Los_Angeles")) == .overdue)
    }

    @Test func zeroIntervalCannotProduceSameDay() {
        let calendar = calendar("UTC")
        let now = Date(timeIntervalSince1970: 0)
        #expect(CareSchedule.nextDate(after: now, intervalDays: 0, calendar: calendar).timeIntervalSince(now) == 86400)
    }
}

@MainActor
struct CarePersistenceTests {
    @Test func diskReopenKeepsEventsWithCorrectPlantAndCascadeDeletion() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("care.store")
        let schema = Schema([Plant.self, CareTask.self, CareEvent.self])
        let configuration = ModelConfiguration(schema: schema, url: url)
        let firstID: UUID
        let secondID: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let first = Plant(name: "Fern")
            let second = Plant(name: "Aloe")
            firstID = first.id; secondID = second.id
            context.insert(first); context.insert(second)
            let task = CareTask(kind: .watering, intervalDays: 3, dueDate: .now, plant: first)
            context.insert(task)
            try context.save()
            let time = Date(timeIntervalSince1970: 1_800_000_000)
            try CareRecorder.complete(task, note: " Soil was dry ", at: time, in: context)
            #expect(task.dueDate == CareSchedule.nextDate(after: time, intervalDays: 3))
            // Deleting a routine must preserve the plant's history.
            context.delete(task)
            try context.save()
        }
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let events = try context.fetch(FetchDescriptor<CareEvent>())
            #expect(events.count == 1)
            #expect(events.first?.plant?.id == firstID)
            #expect(events.first?.note == "Soil was dry")
            #expect(events.first?.taskTitle == "Watering")
            #expect(events.first?.completedAt == Date(timeIntervalSince1970: 1_800_000_000))
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let other = try #require(plants.first { $0.id == secondID })
            #expect((other.careEvents ?? []).isEmpty)
            let first = try #require(plants.first { $0.id == firstID })
            let task = CareTask(kind: .custom, customTitle: "Check leaves", intervalDays: 2, dueDate: .now, plant: first)
            context.insert(task)
            try context.save()
            context.delete(first)
            try context.save()
            #expect(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
            #expect(try context.fetch(FetchDescriptor<CareTask>()).isEmpty)
            #expect(try context.fetch(FetchDescriptor<Plant>()).map(\.id) == [secondID])
        }
    }

}
