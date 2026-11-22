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
}
