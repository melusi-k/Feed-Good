import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class JournalMilestoneTests: XCTestCase {
    private var schema: Schema { Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]) }
    private func memory() throws -> ModelContainer { try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }

    func testMilestoneOnlyDraftCanSaveEditAndClearWithoutChangingNote() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Test fern"); context.insert(plant)
        XCTAssertTrue(JournalDraft(milestone: .newLeaf).isValid)
        try JournalStore.save(JournalDraft(milestone: .newLeaf), plant: plant, entry: nil, context: context)
        let entry = try XCTUnwrap(context.fetch(FetchDescriptor<JournalEntry>()).first)
        let id = entry.id
        XCTAssertEqual(entry.milestone, .newLeaf)
        XCTAssertTrue(entry.note.isEmpty)
        try JournalStore.save(JournalDraft(date: entry.date, note: "Kept note", milestone: .flowering), plant: plant, entry: entry, context: context)
        XCTAssertEqual(entry.id, id)
        XCTAssertEqual(entry.milestone, .flowering)
        try JournalStore.save(JournalDraft(date: entry.date, note: entry.note), plant: plant, entry: entry, context: context)
        XCTAssertNil(entry.milestoneRaw)
        XCTAssertEqual(entry.note, "Kept note")
        XCTAssertThrowsError(try JournalStore.save(JournalDraft(), plant: plant, entry: entry, context: context))
        XCTAssertEqual(entry.note, "Kept note")
    }

    func testArchiveV2RoundTripAndMilestoneConflictAreLossless() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Fern"); context.insert(plant)
        try JournalStore.save(JournalDraft(milestone: .repotting), plant: plant, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let data = try JournalArchive.export(plants: [plant], entries: entries)
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        XCTAssertEqual(archive.version, 2)
        XCTAssertEqual(archive.entries.first?.milestoneRaw, "repotting")
        let destination = try memory(); let recovery = ModelContext(destination)
        XCTAssertEqual(try JournalArchive.recover(data, context: recovery), 1)
        let entry = try XCTUnwrap(recovery.fetch(FetchDescriptor<JournalEntry>()).first)
        XCTAssertEqual(entry.milestone, .repotting)
        XCTAssertEqual(try JournalArchive.recover(data, context: recovery), 0)
        entry.milestoneRaw = JournalMilestone.recovery.rawValue; try recovery.save()
        XCTAssertThrowsError(try JournalArchive.recover(data, context: recovery))
        XCTAssertEqual(entry.milestone, .recovery)
        XCTAssertEqual(try recovery.fetch(FetchDescriptor<JournalEntry>()).count, 1)
    }

    func testLegacyV1WithoutMilestoneDecodesAsNilAndRecovers() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Legacy fern"); context.insert(plant)
        let entry = JournalEntry(note: "Legacy note", plant: plant); context.insert(entry); try context.save()
        let exported = try JournalArchive.export(plants: [plant], entries: [entry])
        var object = try XCTUnwrap(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        object["version"] = 1
        var records = try XCTUnwrap(object["entries"] as? [[String: Any]])
        records[0].removeValue(forKey: "milestoneRaw"); object["entries"] = records
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: legacy)
        XCTAssertNil(decoded.entries.first?.milestoneRaw)
        let destination = try memory(); let recovery = ModelContext(destination)
        XCTAssertEqual(try JournalArchive.recover(legacy, context: recovery), 1)
        let restored = try XCTUnwrap(recovery.fetch(FetchDescriptor<JournalEntry>()).first)
        XCTAssertNil(restored.milestoneRaw)
        XCTAssertEqual(restored.note, "Legacy note")
    }

    func testUnknownMilestoneAndMislabelledV1RejectBeforeWrites() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let entry = JournalEntry(note: "Kept", milestoneRaw: "newLeaf", plant: plant); context.insert(entry); try context.save()
        var archive = try JSONDecoder().decode(JournalArchive.self, from: JournalArchive.export(plants: [plant], entries: [entry]))
        archive.entries[0].milestoneRaw = "unknown"
        let destination = try memory(); let recovery = ModelContext(destination)
        XCTAssertThrowsError(try JournalArchive.recover(JSONEncoder().encode(archive), context: recovery))
        XCTAssertTrue(try recovery.fetch(FetchDescriptor<Plant>()).isEmpty)
        archive.entries[0].milestoneRaw = "newLeaf"; archive.version = 1
        XCTAssertThrowsError(try archive.validate())
        archive.version = 3
        XCTAssertThrowsError(try archive.validate())
    }

    func testMilestonePersistsAfterDiskReopen() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let config = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("milestone.store"))
        do {
            let container = try ModelContainer(for: schema, configurations: config); let context = ModelContext(container)
            let plant = Plant(name: "Fern"); context.insert(plant)
            try JournalStore.save(JournalDraft(note: "Observed", milestone: .newLeaf), plant: plant, entry: nil, context: context)
        }
        do {
            let container = try ModelContainer(for: schema, configurations: config); let context = ModelContext(container)
            let entry = try XCTUnwrap(context.fetch(FetchDescriptor<JournalEntry>()).first)
            XCTAssertEqual(entry.milestone, .newLeaf)
            XCTAssertEqual(entry.note, "Observed")
            XCTAssertEqual(entry.plant?.name, "Fern")
        }
    }
}
