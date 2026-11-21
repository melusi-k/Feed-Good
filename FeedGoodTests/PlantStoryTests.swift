import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class PlantStoryTests: XCTestCase {
    private func memory() throws -> ModelContainer {
        let schema = Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    func testMixedSourcesNewestFirstAndPlantIsolation() throws {
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
        XCTAssertEqual(items.map(\.id), ["journal.\(newest.id.uuidString)", "care.\(event.id.uuidString)", "journal.\(old.id.uuidString)"])
        XCTAssertEqual(items.count, 3)
        if case .journal(let entry) = items[0] { XCTAssertEqual(entry.milestone, .newLeaf) } else { XCTFail("Expected milestone observation") }
    }

    func testEqualDatesUseNamespacedStableIDsIndependentOfInputOrder() throws {
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
        XCTAssertEqual(first.map(\.id), second.map(\.id))
        XCTAssertEqual(Set(first.map(\.id)).count, 3)
        XCTAssertEqual(first.map(\.id), first.map(\.id).sorted())
    }

    func testEmptyAndSingleSourceStories() {
        let plant = Plant(name: "Fern")
        XCTAssertTrue(PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: []).isEmpty)
        let entry = JournalEntry(note: "Only note", plant: plant)
        let task = CareTask(kind: .pruning, intervalDays: 5, dueDate: .now, plant: plant)
        let care = CareEvent(task: task)
        XCTAssertEqual(PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: [entry]).count, 1)
        XCTAssertEqual(PlantStory.items(plantID: plant.id, careEvents: [care], journalEntries: []).count, 1)
    }

    func testSourceEditAndDeleteReprojectWithoutDuplicatingOrLosingOtherRecords() throws {
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
        XCTAssertEqual(try project().count, 2)
        try JournalStore.save(JournalDraft(date: Date(timeIntervalSince1970: 300), note: "After", milestone: .flowering), plant: plant, entry: entry, context: context)
        XCTAssertEqual(try project().first?.id, "journal.\(entry.id.uuidString)")
        XCTAssertEqual(entry.note, "After")
        XCTAssertEqual(try context.fetch(FetchDescriptor<JournalEntry>()).count, 2)
        try JournalStore.delete(entry, context: context)
        XCTAssertEqual(try project().map(\.id), ["care.\(event.id.uuidString)"])
        // The current care UI is read-only. Exercise underlying source changes,
        // without adding or pretending to offer a care-history edit/delete UI.
        event.note = "Corrected source"; event.completedAt = Date(timeIntervalSince1970: 400); try context.save()
        if case .care(let updated) = try XCTUnwrap(project().first) { XCTAssertEqual(updated.note, "Corrected source") } else { XCTFail("Expected care event") }
        context.delete(event); try context.save()
        XCTAssertTrue(try project().isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<JournalEntry>()).map(\.id), [unrelated.id])
        XCTAssertEqual(try context.fetch(FetchDescriptor<CareTask>()).count, 1)
    }
}
