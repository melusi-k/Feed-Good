import Foundation
import Testing
@testable import FeedGood

struct GardenProfileSummaryTests {
    @Test @MainActor func emptyGardenHasNoInventedCounts() {
        let summary = GardenProfileSummary(plants: [], careEvents: [], journalEntries: [])
        #expect(summary.plantCount == 0)
        #expect(summary.careEventCount == 0)
        #expect(summary.journalEntryCount == 0)
    }

    @Test @MainActor func countsExistingGardenRecordsWithoutChangingThem() {
        let plant = Plant(name: "Profile fern", notes: "Bright indirect light")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: Date(timeIntervalSince1970: 0), plant: plant)
        let event = CareEvent(task: task)
        let entry = JournalEntry(note: "New frond", plant: plant)
        let summary = GardenProfileSummary(plants: [plant], careEvents: [event], journalEntries: [entry])
        #expect(summary.plantCount == 1)
        #expect(summary.careEventCount == 1)
        #expect(summary.journalEntryCount == 1)
        #expect(plant.notes == "Bright indirect light")
        #expect(task.dueDate == Date(timeIntervalSince1970: 0))
        #expect(entry.note == "New frond")
    }

    @Test @MainActor func excludesOrphansAndRecordsOutsideTheCurrentGarden() {
        let current = Plant(name: "Current")
        let other = Plant(name: "Other")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: Date(timeIntervalSince1970: 0), plant: other)
        let event = CareEvent(task: task)
        let entry = JournalEntry(note: "Outside current garden", plant: other)
        let orphan = JournalEntry(note: "No linked plant", plant: current)
        orphan.plant = nil
        let summary = GardenProfileSummary(plants: [current], careEvents: [event], journalEntries: [entry, orphan])
        #expect(summary.plantCount == 1)
        #expect(summary.careEventCount == 0)
        #expect(summary.journalEntryCount == 0)
    }

    @Test @MainActor func careActivityIsPlantScopedAndUsesHalfOpenPeriod() {
        let plant = Plant(name: "Fern")
        let otherPlant = Plant(name: "Other")
        let start = Date(timeIntervalSince1970: 1_000)
        let end = Date(timeIntervalSince1970: 2_000)
        let firstID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let secondID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let included = CareEvent(id: firstID, taskID: UUID(), taskTitle: "Watering", completedAt: start, note: "", plant: plant)
        let atEnd = CareEvent(id: UUID(), taskID: UUID(), taskTitle: "Watering", completedAt: end, note: "", plant: plant)
        let wrongPlant = CareEvent(id: UUID(), taskID: UUID(), taskTitle: "Feeding", completedAt: start, note: "", plant: otherPlant)

        let summary = PlantCareActivitySummary(
            plantID: plant.id,
            period: DateInterval(start: start, end: end),
            events: [atEnd, wrongPlant, included]
        )

        #expect(summary.eventCount == 1)
        #expect(summary.records.map(\.id) == [firstID])
        #expect(summary.earliestRecordedAt == start)
        #expect(summary.latestRecordedAt == start)
        #expect(summary.period.start == start)
        #expect(summary.period.end == end)
    }

    @Test @MainActor func careActivitySortsNewestFirstAndBreaksTiesByStableID() {
        let plant = Plant(name: "Fern")
        let instant = Date(timeIntervalSince1970: 1_500)
        let later = Date(timeIntervalSince1970: 1_600)
        let lowID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let highID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let first = CareEvent(id: highID, taskID: UUID(), taskTitle: "Feeding", completedAt: instant, note: "", plant: plant)
        let second = CareEvent(id: lowID, taskID: UUID(), taskTitle: "Watering", completedAt: instant, note: "", plant: plant)
        let newest = CareEvent(id: UUID(), taskID: UUID(), taskTitle: "Pruning", completedAt: later, note: "", plant: plant)

        let summary = PlantCareActivitySummary(
            plantID: plant.id,
            period: DateInterval(start: Date(timeIntervalSince1970: 1_000), end: Date(timeIntervalSince1970: 2_000)),
            events: [first, second, newest]
        )

        #expect(summary.records.map(\.id) == [newest.id, lowID, highID])
        #expect(summary.earliestRecordedAt == instant)
        #expect(summary.latestRecordedAt == later)
    }

    @Test func weekPeriodUsesInjectedCalendarAndTimeZone() {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 2
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let wednesday = calendar.date(from: DateComponents(year: 2026, month: 11, day: 25, hour: 12))!

        let period = PlantCareActivitySummary.week(containing: wednesday, calendar: calendar)

        #expect(period != nil)
        #expect(period.map { calendar.component(.weekday, from: $0.start) } == 2)
        #expect(period.map { calendar.dateComponents([.day], from: $0.start, to: $0.end).day } == 7)
    }

    @Test @MainActor func emptyCareActivityHasNoInventedTimestampsOrCounts() {
        let plant = Plant(name: "Sparse")
        let summary = PlantCareActivitySummary(
            plantID: plant.id,
            period: DateInterval(start: Date(timeIntervalSince1970: 0), end: Date(timeIntervalSince1970: 10)),
            events: []
        )

        #expect(summary.eventCount == 0)
        #expect(summary.records.isEmpty)
        #expect(summary.earliestRecordedAt == nil)
        #expect(summary.latestRecordedAt == nil)
    }
}
