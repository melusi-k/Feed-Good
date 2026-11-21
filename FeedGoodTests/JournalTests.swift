import XCTest
import SwiftData
import UIKit
@testable import FeedGood

@MainActor
final class JournalTests: XCTestCase {
    private var schema: Schema { Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]) }
    private func memory() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func samplePhoto() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 3, height: 3)).image { context in
            context.cgContext.setFillColor(UIColor.systemGreen.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 3, height: 3))
        }.pngData()!
    }

    func testDraftNeedsANoteOrPhoto() {
        XCTAssertFalse(JournalDraft(note: " \n ").isValid)
        XCTAssertTrue(JournalDraft(note: "New leaf").isValid)
        XCTAssertTrue(JournalDraft(photoData: Data([1])).isValid)
    }

    func testDiskReopenAssociationEditDeleteAndCascade() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let config = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("journal.store"))
        let firstID: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container)
            let first = Plant(name: "Fern"); let second = Plant(name: "Aloe")
            firstID = first.id
            context.insert(first); context.insert(second)
            try JournalStore.save(JournalDraft(note: " First leaf "), plant: first, entry: nil, context: context)
            let saved = try XCTUnwrap(context.fetch(FetchDescriptor<JournalEntry>()).first)
            XCTAssertEqual(saved.note, "First leaf")
            try JournalStore.save(JournalDraft(note: "Second leaf"), plant: first, entry: saved, context: context)
        }
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container)
            let entries = try context.fetch(FetchDescriptor<JournalEntry>())
            XCTAssertEqual(entries.count, 1)
            XCTAssertEqual(entries.first?.plant?.id, firstID)
            XCTAssertEqual(entries.first?.note, "Second leaf")
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let first = try XCTUnwrap(plants.first { $0.id == firstID })
            XCTAssertEqual(first.journalEntries?.count, 1)
            XCTAssertTrue((plants.first { $0.id != firstID }?.journalEntries ?? []).isEmpty)
            try JournalStore.delete(try XCTUnwrap(entries.first), context: context)
            XCTAssertTrue(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
            try JournalStore.save(JournalDraft(note: "One more"), plant: first, entry: nil, context: context)
            context.delete(first); try context.save()
            XCTAssertTrue(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
            XCTAssertEqual(try context.fetch(FetchDescriptor<Plant>()).count, 1)
        }
    }

    func testArchiveRecoverIsAdditiveIdempotentAndPreservesExistingDetails() throws {
        let source = try memory(); let context = ModelContext(source)
        let fern = Plant(name: "Fern"); context.insert(fern)
        try JournalStore.save(JournalDraft(note: "A new leaf"), plant: fern, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let data = try JournalArchive.export(plants: [fern], entries: entries)
        let destination = try memory(); let recovery = ModelContext(destination)
        XCTAssertEqual(try JournalArchive.recover(data, context: recovery), 1)
        let restored = try XCTUnwrap(recovery.fetch(FetchDescriptor<Plant>()).first)
        restored.name = "My renamed fern"; try recovery.save()
        XCTAssertEqual(try JournalArchive.recover(data, context: recovery), 0)
        XCTAssertEqual(restored.name, "My renamed fern")
        XCTAssertEqual(try recovery.fetch(FetchDescriptor<JournalEntry>()).first?.plant?.id, fern.id)
        XCTAssertEqual(try recovery.fetch(FetchDescriptor<JournalEntry>()).count, 1)
    }

    func testVersionTwoRoundTripIncludesProfilePhotosCareTasksAndCareHistory() throws {
        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(name: "Fern", species: "Nephrolepis", photoData: samplePhoto())
        sourceContext.insert(plant)
        let dueDate = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 9,
            dueDate: dueDate,
            isEnabled: false,
            reminderEnabled: true,
            plant: plant
        )
        sourceContext.insert(task)
        let event = CareEvent(task: task, completedAt: dueDate.addingTimeInterval(-86_400), note: "Checked soil first")
        sourceContext.insert(event)
        try JournalStore.save(JournalDraft(note: "New frond", photoData: samplePhoto()), plant: plant, entry: nil, context: sourceContext)

        let data = try JournalArchive.export(
            plants: [plant],
            entries: sourceContext.fetch(FetchDescriptor<JournalEntry>()),
            careTasks: [task],
            careEvents: [event]
        )
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: data)
        XCTAssertEqual(decoded.version, 2)
        XCTAssertEqual(decoded.careTasks?.count, 1)
        XCTAssertEqual(decoded.careEvents?.count, 1)

        let destination = try memory()
        let destinationContext = ModelContext(destination)
        XCTAssertEqual(try JournalArchive.recover(data, context: destinationContext), 1)

        let restoredPlant = try XCTUnwrap(destinationContext.fetch(FetchDescriptor<Plant>()).first)
        XCTAssertEqual(restoredPlant.id, plant.id)
        XCTAssertEqual(restoredPlant.name, "Fern")
        XCTAssertEqual(restoredPlant.photoData, plant.photoData)

        let restoredTask = try XCTUnwrap(destinationContext.fetch(FetchDescriptor<CareTask>()).first)
        XCTAssertEqual(restoredTask.id, task.id)
        XCTAssertEqual(restoredTask.intervalDays, 9)
        XCTAssertEqual(restoredTask.dueDate, dueDate)
        XCTAssertFalse(restoredTask.isEnabled)
        XCTAssertTrue(restoredTask.reminderEnabled)
        XCTAssertEqual(restoredTask.plant?.id, plant.id)

        let restoredEvent = try XCTUnwrap(destinationContext.fetch(FetchDescriptor<CareEvent>()).first)
        XCTAssertEqual(restoredEvent.id, event.id)
        XCTAssertEqual(restoredEvent.taskID, task.id)
        XCTAssertEqual(restoredEvent.taskTitle, task.title)
        XCTAssertEqual(restoredEvent.note, "Checked soil first")
        XCTAssertEqual(restoredEvent.plant?.id, plant.id)

        let restoredEntry = try XCTUnwrap(destinationContext.fetch(FetchDescriptor<JournalEntry>()).first)
        XCTAssertEqual(restoredEntry.photoData, try XCTUnwrap(sourceContext.fetch(FetchDescriptor<JournalEntry>()).first?.photoData))
    }

    func testVersionOneJournalArchiveRemainsImportable() throws {
        let plant = Plant(name: "Legacy fern")
        let entry = JournalArchive.EntryRecord(id: UUID(), plantID: plant.id, date: .now, note: "Legacy note", photoData: nil)
        var legacy = JournalArchive(
            plants: [JournalArchive.PlantRecord(id: plant.id, name: plant.name, species: "", notes: "", createdAt: plant.createdAt)],
            entries: [entry],
            careTasks: nil,
            careEvents: nil
        )
        legacy.version = 1
        let data = try JSONEncoder().encode(legacy)

        let destination = try memory()
        let context = ModelContext(destination)
        XCTAssertEqual(try JournalArchive.recover(data, context: context), 1)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Plant>()).first?.name, "Legacy fern")
        XCTAssertEqual(try context.fetch(FetchDescriptor<JournalEntry>()).first?.note, "Legacy note")
        XCTAssertTrue(try context.fetch(FetchDescriptor<CareTask>()).isEmpty)
        XCTAssertTrue(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
    }

    func testArchivePreviewShowsNewAndAlreadyPresentRecordCounts() throws {
        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(name: "Fern")
        sourceContext.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        sourceContext.insert(task)
        let event = CareEvent(task: task, note: "Checked soil")
        sourceContext.insert(event)
        try JournalStore.save(JournalDraft(note: "New frond"), plant: plant, entry: nil, context: sourceContext)

        let data = try JournalArchive.export(
            plants: [plant],
            entries: sourceContext.fetch(FetchDescriptor<JournalEntry>()),
            careTasks: [task],
            careEvents: [event]
        )
        let destination = try memory()
        let destinationContext = ModelContext(destination)
        destinationContext.insert(Plant(id: plant.id, name: "Existing fern"))
        try destinationContext.save()

        let preview = try JournalArchive.preview(data, context: destinationContext)
        XCTAssertEqual(preview.version, 2)
        XCTAssertEqual(preview.plantsToAdd, 0)
        XCTAssertEqual(preview.plantsAlreadyPresent, 1)
        XCTAssertEqual(preview.entriesToAdd, 1)
        XCTAssertEqual(preview.entriesAlreadyPresent, 0)
        XCTAssertEqual(preview.careTasksToAdd, 1)
        XCTAssertEqual(preview.careEventsToAdd, 1)
        XCTAssertTrue(preview.confirmationMessage.contains("any conflict"))
    }

    func testArchiveConflictAndMalformedReferencesRejectBeforeWrites() throws {
        let container = try memory(); let context = ModelContext(container)
        let fern = Plant(name: "Fern"); context.insert(fern)
        try JournalStore.save(JournalDraft(note: "Original"), plant: fern, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        var archive = try JSONDecoder().decode(JournalArchive.self, from: JournalArchive.export(plants: [fern], entries: entries))
        archive.entries[0].note = "Conflicting"
        XCTAssertThrowsError(try JournalArchive.recover(JSONEncoder().encode(archive), context: context))
        XCTAssertEqual(entries.first?.note, "Original")
        archive.entries[0].plantID = UUID()
        XCTAssertThrowsError(try JournalArchive.recover(JSONEncoder().encode(archive), context: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<Plant>()).count, 1)
        archive.version = 999
        XCTAssertThrowsError(try archive.validate())
        archive.version = 2
        archive.entries[0].plantID = fern.id
        archive.entries[0].photoData = Data([1, 2, 3])
        XCTAssertThrowsError(try archive.validate())
    }

    func testCareRecordConflictsRejectWithoutChangingExistingRecords() throws {
        let container = try memory()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        context.insert(task)
        let event = CareEvent(task: task, note: "Original")
        context.insert(event)
        try context.save()

        let data = try JournalArchive.export(plants: [plant], entries: [], careTasks: [task], careEvents: [event])
        var archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        archive.careTasks?[0].intervalDays = 12

        XCTAssertThrowsError(try JournalArchive.recover(JSONEncoder().encode(archive), context: context))
        XCTAssertEqual(try context.fetch(FetchDescriptor<CareTask>()).first?.intervalDays, 7)
        XCTAssertEqual(try context.fetch(FetchDescriptor<CareEvent>()).first?.note, "Original")
    }
}
