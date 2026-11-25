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
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
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


@MainActor
struct CareEventCorrectionTests {
    private func memory() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: FeedGoodSchemaV5.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func fixedDate(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    @Test func correctionChangesDateAndNoteButNeverTheRoutine() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let dueBefore = fixedDate("2026-11-10T08:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: dueBefore, plant: plant)
        context.insert(task)
        let completedAt = fixedDate("2026-11-08T08:00:00Z")
        try CareRecorder.complete(task, note: "First water", at: completedAt, in: context, calendar: Calendar(identifier: .gregorian))
        let dueAfterCompletion = task.dueDate
        let event = try #require(plant.careEvents?.first)
        let corrected = fixedDate("2026-11-09T15:30:00Z")

        try CareRecorder.update(event, completedAt: corrected, note: " Corrected note ", in: context)

        #expect(event.completedAt == corrected)
        #expect(event.note == "Corrected note")
        #expect(event.taskTitle == "Watering")
        #expect(task.dueDate == dueAfterCompletion)
        #expect(task.intervalDays == 7)
    }

    @Test func correctingANonLatestEventAlsoLeavesTheRoutineUntouched() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .feeding, intervalDays: 14, dueDate: fixedDate("2026-11-01T08:00:00Z"), plant: plant)
        context.insert(task)
        let calendar = Calendar(identifier: .gregorian)
        try CareRecorder.complete(task, note: "Older", at: fixedDate("2026-10-20T08:00:00Z"), in: context, calendar: calendar)
        try CareRecorder.complete(task, note: "Latest", at: fixedDate("2026-11-03T08:00:00Z"), in: context, calendar: calendar)
        let dueAfterBoth = task.dueDate
        let older = try #require(plant.careEvents?.sorted { $0.completedAt < $1.completedAt }.first)

        try CareRecorder.update(older, completedAt: fixedDate("2026-10-21T08:00:00Z"), note: "Older corrected", in: context)

        #expect(task.dueDate == dueAfterBoth)
        #expect(older.taskTitle == "Feeding")
    }

    @Test func deletingOneEventLeavesUnrelatedRecordsIntact() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let watering = CareTask(kind: .watering, intervalDays: 7, dueDate: fixedDate("2026-11-01T08:00:00Z"), plant: plant)
        let feeding = CareTask(kind: .feeding, intervalDays: 14, dueDate: fixedDate("2026-11-02T08:00:00Z"), plant: plant)
        context.insert(watering)
        context.insert(feeding)
        let calendar = Calendar(identifier: .gregorian)
        try CareRecorder.complete(watering, note: "W", at: fixedDate("2026-10-28T08:00:00Z"), in: context, calendar: calendar)
        try CareRecorder.complete(feeding, note: "F", at: fixedDate("2026-10-29T08:00:00Z"), in: context, calendar: calendar)
        let dueWatering = watering.dueDate
        let dueFeeding = feeding.dueDate
        let doomed = try #require(plant.careEvents?.first { $0.taskID == watering.id })

        try CareRecorder.delete(doomed, in: context)

        let remaining = try context.fetch(FetchDescriptor<CareEvent>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.taskID == feeding.id)
        #expect(watering.dueDate == dueWatering)
        #expect(feeding.dueDate == dueFeeding)
        #expect(try context.fetch(FetchDescriptor<CareTask>()).count == 2)
        #expect(try context.fetch(FetchDescriptor<Plant>()).count == 1)
    }

    @Test func failedCorrectionSaveRollsBackToTheOriginalRecord() throws {
        enum InjectedSaveFailure: Error { case failed }
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: fixedDate("2026-11-10T08:00:00Z"), plant: plant)
        context.insert(task)
        let originalDate = fixedDate("2026-11-08T08:00:00Z")
        try CareRecorder.complete(task, note: "Original note", at: originalDate, in: context)
        let event = try #require(plant.careEvents?.first)

        #expect(throws: InjectedSaveFailure.self) {
            try CareRecorder.update(event, completedAt: fixedDate("2026-11-09T08:00:00Z"), note: "Changed", in: context) { _ in
                throw InjectedSaveFailure.failed
            }
        }

        #expect(event.completedAt == originalDate)
        #expect(event.note == "Original note")
        let persisted = try context.fetch(FetchDescriptor<CareEvent>())
        #expect(persisted.first?.completedAt == originalDate)
        #expect(persisted.first?.note == "Original note")
    }

    @Test func failedDeleteKeepsTheRecord() throws {
        enum InjectedSaveFailure: Error { case failed }
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: fixedDate("2026-11-10T08:00:00Z"), plant: plant)
        context.insert(task)
        try CareRecorder.complete(task, note: "Keep me", at: fixedDate("2026-11-08T08:00:00Z"), in: context)
        let event = try #require(plant.careEvents?.first)

        #expect(throws: InjectedSaveFailure.self) {
            try CareRecorder.delete(event, in: context) { _ in
                throw InjectedSaveFailure.failed
            }
        }

        #expect(try context.fetch(FetchDescriptor<CareEvent>()).count == 1)
    }

    @Test func correctedDateSurvivesDiskReopenAcrossTimeZones() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("care-correction.store")
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        let configuration = ModelConfiguration(schema: schema, url: url)
        let corrected = ISO8601DateFormatter().date(from: "2026-03-07T09:30:00-05:00")!
        let eventID: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let plant = Plant(name: "Fern")
            context.insert(plant)
            let task = CareTask(kind: .watering, intervalDays: 7, dueDate: corrected, plant: plant)
            context.insert(task)
            try CareRecorder.complete(task, note: "Before DST", at: corrected.addingTimeInterval(-86400), in: context)
            let event = try #require(plant.careEvents?.first)
            try CareRecorder.update(event, completedAt: corrected, note: "On the DST boundary", in: context)
            eventID = event.id
        }
        do {
            var newYork = Calendar(identifier: .gregorian)
            newYork.timeZone = TimeZone(identifier: "America/New_York")!
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let event = try #require(try context.fetch(FetchDescriptor<CareEvent>()).first)
            #expect(event.id == eventID)
            #expect(event.completedAt == corrected)
            #expect(event.note == "On the DST boundary")
            #expect(newYork.component(.hour, from: event.completedAt) == 9)
        }
    }
}
