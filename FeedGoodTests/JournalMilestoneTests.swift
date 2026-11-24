import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct JournalMilestoneTests {
    private var schema: Schema { Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self, QuietPeriod.self, QuietPeriodTaskSnapshot.self]) }
    private func memory() throws -> ModelContainer { try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true)) }

    @Test func milestoneOnlyDraftCanSaveEditAndClearWithoutChangingNote() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Test fern"); context.insert(plant)
        #expect(JournalDraft(milestone: .newLeaf).isValid)
        try JournalStore.save(JournalDraft(milestone: .newLeaf), plant: plant, entry: nil, context: context)
        let entry = try #require(context.fetch(FetchDescriptor<JournalEntry>()).first)
        let id = entry.id
        #expect(entry.milestone == .newLeaf)
        #expect(entry.note.isEmpty)
        try JournalStore.save(JournalDraft(date: entry.date, note: "Kept note", milestone: .flowering), plant: plant, entry: entry, context: context)
        #expect(entry.id == id)
        #expect(entry.milestone == .flowering)
        try JournalStore.save(JournalDraft(date: entry.date, note: entry.note), plant: plant, entry: entry, context: context)
        #expect(entry.milestoneRaw == nil)
        #expect(entry.note == "Kept note")
        #expect(throws: (any Error).self) { try JournalStore.save(JournalDraft(), plant: plant, entry: entry, context: context) }
        #expect(entry.note == "Kept note")
    }

    @Test func archiveV2RoundTripAndMilestoneConflictAreLossless() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Fern"); context.insert(plant)
        try JournalStore.save(JournalDraft(milestone: .repotting), plant: plant, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let data = try JournalArchive.export(plants: [plant], entries: entries)
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(archive.version == 2)
        #expect(archive.entries.first?.milestoneRaw == "repotting")
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: recovery) == 1)
        let entry = try #require(recovery.fetch(FetchDescriptor<JournalEntry>()).first)
        #expect(entry.milestone == .repotting)
        #expect(try JournalArchive.recover(data, context: recovery) == 0)
        entry.milestoneRaw = JournalMilestone.recovery.rawValue; try recovery.save()
        #expect(throws: (any Error).self) { try JournalArchive.recover(data, context: recovery) }
        #expect(entry.milestone == .recovery)
        #expect(try recovery.fetch(FetchDescriptor<JournalEntry>()).count == 1)
    }

    @Test func legacyV1WithoutMilestoneDecodesAsNilAndRecovers() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Legacy fern"); context.insert(plant)
        let entry = JournalEntry(note: "Legacy note", plant: plant); context.insert(entry); try context.save()
        let exported = try JournalArchive.export(plants: [plant], entries: [entry])
        var object = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        object["version"] = 1
        var records = try #require(object["entries"] as? [[String: Any]])
        records[0].removeValue(forKey: "milestoneRaw"); object["entries"] = records
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: legacy)
        #expect(decoded.entries.first?.milestoneRaw == nil)
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(try JournalArchive.recover(legacy, context: recovery) == 1)
        let restored = try #require(recovery.fetch(FetchDescriptor<JournalEntry>()).first)
        #expect(restored.milestoneRaw == nil)
        #expect(restored.note == "Legacy note")
    }

    @Test func unknownMilestoneAndMislabelledV1RejectBeforeWrites() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let entry = JournalEntry(note: "Kept", milestoneRaw: "newLeaf", plant: plant); context.insert(entry); try context.save()
        var archive = try JSONDecoder().decode(JournalArchive.self, from: JournalArchive.export(plants: [plant], entries: [entry]))
        archive.entries[0].milestoneRaw = "unknown"
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(throws: (any Error).self) { try JournalArchive.recover(JSONEncoder().encode(archive), context: recovery) }
        #expect(try recovery.fetch(FetchDescriptor<Plant>()).isEmpty)
        archive.entries[0].milestoneRaw = "newLeaf"; archive.version = 1
        #expect(throws: (any Error).self) { try archive.validate() }
        archive.version = 3
        #expect(throws: (any Error).self) { try archive.validate() }
    }

    @Test func milestonePersistsAfterDiskReopen() throws {
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
            let entry = try #require(context.fetch(FetchDescriptor<JournalEntry>()).first)
            #expect(entry.milestone == .newLeaf)
            #expect(entry.note == "Observed")
            #expect(entry.plant?.name == "Fern")
        }
    }
}
