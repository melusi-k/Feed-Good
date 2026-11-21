import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class JournalTests: XCTestCase {
    private var schema: Schema { Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]) }
    private func memory() throws -> ModelContainer { try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }

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
        archive.version = 1; archive.entries[0].plantID = fern.id; archive.entries[0].photoData = Data([1, 2, 3])
        XCTAssertThrowsError(try archive.validate())
    }
}
