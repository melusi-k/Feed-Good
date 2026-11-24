import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct PlantStoryTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema([
            Plant.self, CareTask.self, CareEvent.self, JournalEntry.self,
            QuietPeriod.self, QuietPeriodTaskSnapshot.self
        ])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func mixedSourcesNewestFirstAndPlantIsolation() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); let other = Plant(name: "Aloe")
        context.insert(plant); context.insert(other)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        let otherTask = CareTask(kind: .feeding, intervalDays: 7, dueDate: .now, plant: other)
        context.insert(task); context.insert(otherTask)
        let old = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "Old", plant: plant)
        let event = CareEvent(task: task, completedAt: Date(timeIntervalSince1970: 200))
        let newest = JournalEntry(date: Date(timeIntervalSince1970: 300), note: "New", milestoneRaw: "newLeaf", plant: plant)
        let excluded = CareEvent(task: otherTask, completedAt: Date(timeIntervalSince1970: 400))
        for entry in [old, newest] { context.insert(entry) }; context.insert(event); context.insert(excluded); try context.save()
        let items = PlantStory.items(plantID: plant.id, careEvents: [excluded, event], journalEntries: [old, newest])
        #expect(items.map(\.id) == ["journal.\(newest.id.uuidString)", "care.\(event.id.uuidString)", "journal.\(old.id.uuidString)"])
        #expect(items.count == 3)
        if case .journal(let entry) = items[0] { #expect(entry.milestone == .newLeaf) } else { Issue.record("Expected milestone observation") }
    }

    @Test func equalDatesUseNamespacedStableIDsIndependentOfInputOrder() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 1, dueDate: .now, plant: plant); context.insert(task)
        let date = Date(timeIntervalSince1970: 10)
        let a = JournalEntry(date: date, note: "A", plant: plant)
        let b = JournalEntry(date: date, note: "B", plant: plant)
        let care = CareEvent(task: task, completedAt: date)
        // Same UUID across source kinds must not collide in the combined list.
        care.id = a.id
        let first = PlantStory.items(plantID: plant.id, careEvents: [care], journalEntries: [a, b])
        let second = PlantStory.items(plantID: plant.id, careEvents: [care], journalEntries: [b, a])
        #expect(first.map(\.id) == second.map(\.id))
        #expect(Set(first.map(\.id)).count == 3)
        #expect(first.map(\.id) == first.map(\.id).sorted())
    }

    @Test func emptyAndSingleSourceStories() {
        let plant = Plant(name: "Fern")
        #expect(PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: []).isEmpty)
        let entry = JournalEntry(note: "Only note", plant: plant)
        let task = CareTask(kind: .pruning, intervalDays: 5, dueDate: .now, plant: plant)
        let care = CareEvent(task: task)
        #expect(PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: [entry]).count == 1)
        #expect(PlantStory.items(plantID: plant.id, careEvents: [care], journalEntries: []).count == 1)
    }

    @Test func removedTaskQuietPeriodSnapshotRemainsInPlantStory() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .distantFuture, plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: .now, statusRaw: QuietPeriodStatus.active.rawValue, activatedAt: .now, plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(taskID: task.id, taskTitleSnapshot: task.title, quietPeriod: period)
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        try QuietPeriodTaskIntegration.markDeleted(taskID: task.id, at: Date(timeIntervalSince1970: 500), in: context)
        context.delete(task)
        try context.save()

        let items = PlantStory.items(
            plantID: plant.id,
            careEvents: [],
            journalEntries: [],
            quietPeriodSnapshots: try context.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>())
        )
        #expect(items.count == 1)
        if case .quietPeriod(let retained) = try #require(items.first) {
            #expect(retained.taskID == task.id)
            #expect(retained.taskTitleSnapshot == "Watering")
            #expect(retained.membershipStatusRaw == QuietPeriodMembershipStatus.removed.rawValue)
        } else {
            Issue.record("Expected retained Quiet Period audit item")
        }
    }

    @Test func equalDatesUseNamespacedStableIDsIndependentOfInputOrder() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 1, dueDate: .now, plant: plant); context.insert(task)
        let date = Date(timeIntervalSince1970: 10)
        let a = JournalEntry(date: date, note: "A", plant: plant)
        let b = JournalEntry(date: date, note: "B", plant: plant)
        let care = CareEvent(task: task, completedAt: date)
        // Same UUID across source kinds must not collide in the combined list.
        care.id = a.id
        let first = PlantStory.items(plantID: plant.id, careEvents: [care], journalEntries: [a, b])
        let second = PlantStory.items(plantID: plant.id, careEvents: [care], journalEntries: [b, a])
        #expect(first.map(\.id) == second.map(\.id))
        #expect(Set(first.map(\.id)).count == 3)
        #expect(first.map(\.id) == first.map(\.id).sorted())
    }

    @Test func sourceEditAndDeleteReprojectWithoutDuplicatingOrLosingOtherRecords() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let other = Plant(name: "Aloe"); context.insert(other)
        let task = CareTask(kind: .watering, intervalDays: 1, dueDate: .now, plant: plant); context.insert(task)
        let event = CareEvent(task: task, completedAt: Date(timeIntervalSince1970: 200), note: "Care kept"); context.insert(event)
        let entry = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "Before", plant: plant); context.insert(entry)
        let unrelated = JournalEntry(note: "Other plant kept", plant: other); context.insert(unrelated); try context.save()
        func project() throws -> [PlantStoryItem] {
            PlantStory.items(plantID: plant.id, careEvents: try context.fetch(FetchDescriptor<CareEvent>()), journalEntries: try context.fetch(FetchDescriptor<JournalEntry>()))
        }
        #expect(try project().count == 2)
        try JournalStore.save(JournalDraft(date: Date(timeIntervalSince1970: 300), note: "After", milestone: .flowering), plant: plant, entry: entry, context: context)
        #expect(try project().first?.id == "journal.\(entry.id.uuidString)")
        #expect(entry.note == "After")
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).count == 2)
        try JournalStore.delete(entry, context: context)
        #expect(try project().map(\.id) == ["care.\(event.id.uuidString)"])
        // The current care UI is read-only. Exercise underlying source changes,
        // without adding or pretending to offer a care-history edit/delete UI.
        event.note = "Corrected source"; event.completedAt = Date(timeIntervalSince1970: 400); try context.save()
        if case .care(let updated) = try #require(project().first) { #expect(updated.note == "Corrected source") } else { Issue.record("Expected care event") }
        context.delete(event); try context.save()
        #expect(try project().isEmpty)
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).map(\.id) == [unrelated.id])
        #expect(try context.fetch(FetchDescriptor<CareTask>()).count == 1)
    }
}
