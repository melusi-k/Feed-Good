import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct PlantTagTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func normalizationTrimsCollapsesAndFoldsCaseAndDiacritics() {
        #expect(PlantTag.trimmed("  balcony   plants ") == "balcony plants")
        #expect(PlantTag.normalized("  Fern  ") == "fern")
        #expect(PlantTag.normalized("FERN") == "fern")
        #expect(PlantTag.normalized("Café") == "cafe")
        #expect(PlantTag.normalized("   ") == "")
    }

    @Test func createDeduplicatesByNormalizedNameAndKeepsFirstSpelling() throws {
        let container = try memory(); let context = ModelContext(container)
        let first = try #require(try PlantTagStore.tag(named: "Fern", context: context))
        try context.save()
        #expect(try PlantTagStore.tag(named: " fern  ", context: context)?.id == first.id)
        #expect(try PlantTagStore.tag(named: "FERN", context: context)?.id == first.id)
        #expect(try context.fetch(FetchDescriptor<PlantTag>()).count == 1)
        #expect(first.name == "Fern")
        #expect(try PlantTagStore.tag(named: "   ", context: context) == nil)
    }

    @Test func renameKeepsIdentityOrMergesIntoExistingTag() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let fern = try #require(try PlantTagStore.tag(named: "Fern", context: context))
        let shade = try #require(try PlantTagStore.tag(named: "Shade", context: context))
        fern.plants = [plant]; shade.plants = []
        try context.save()
        // Plain rename: same tag, new name, assignments intact.
        try PlantTagStore.rename(fern, to: "True fern", context: context)
        #expect(fern.name == "True fern")
        #expect(fern.plants?.map(\.id) == [plant.id])
        #expect(try context.fetch(FetchDescriptor<PlantTag>()).count == 2)
        // Rename onto an existing normalized name merges: one tag survives with the plants.
        try PlantTagStore.rename(fern, to: "shade", context: context)
        let remaining = try context.fetch(FetchDescriptor<PlantTag>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.id == shade.id)
        #expect(remaining.first?.plants?.map(\.id) == [plant.id])
        #expect(throws: (any Error).self) { try PlantTagStore.rename(shade, to: "   ", context: context) }
    }

    @Test func deletingATagKeepsPlantsAndTheirRecords() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant); context.insert(task)
        let entry = JournalEntry(note: "Kept note", plant: plant); context.insert(entry)
        let tag = try #require(try PlantTagStore.tag(named: "Fern", context: context))
        tag.plants = [plant]; try context.save()
        try PlantTagStore.delete(tag, context: context)
        #expect(try context.fetch(FetchDescriptor<PlantTag>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<Plant>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<CareTask>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).count == 1)
    }

    @Test func filterUsesOrSemanticsAndClearRestoresEverything() throws {
        let container = try memory(); let context = ModelContext(container)
        let fern = Plant(name: "Fern"); let aloe = Plant(name: "Aloe"); let moss = Plant(name: "Moss")
        for p in [fern, aloe, moss] { context.insert(p) }
        let shade = try #require(try PlantTagStore.tag(named: "Shade", context: context))
        let gift = try #require(try PlantTagStore.tag(named: "Gift", context: context))
        shade.plants = [fern]; gift.plants = [aloe]; try context.save()
        let all = [fern, aloe, moss]
        #expect(PlantCollection.tagged(all, selectedTagIDs: []).count == 3)
        #expect(PlantCollection.tagged(all, selectedTagIDs: [shade.id]).map(\.name) == ["Fern"])
        // OR: any selected tag matches, so both tagged plants appear, untagged stay out.
        #expect(Set(PlantCollection.tagged(all, selectedTagIDs: [shade.id, gift.id]).map(\.name)) == ["Fern", "Aloe"])
    }

    @Test func archivedPlantsKeepTheirTags() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern", archivedAt: .now); context.insert(plant)
        let tag = try #require(try PlantTagStore.tag(named: "Fern", context: context))
        tag.plants = [plant]; try context.save()
        let archived = PlantCollection.archived(from: try context.fetch(FetchDescriptor<Plant>()), query: "", sort: .recentlyAdded)
        #expect(archived.count == 1)
        #expect(archived.first?.tags?.map(\.name) == ["Fern"])
        #expect(PlantCollection.tagged(archived, selectedTagIDs: [tag.id]).count == 1)
    }

    @Test func archiveRoundTripPreservesTagIdentityNamesAndAssignments() throws {
        let source = try memory(); let context = ModelContext(source)
        let fern = Plant(name: "Fern"); let aloe = Plant(name: "Aloe")
        context.insert(fern); context.insert(aloe)
        let shade = try #require(try PlantTagStore.tag(named: "Shade", context: context))
        shade.plants = [fern, aloe]; try context.save()
        let data = try JournalArchive.export(plants: [fern, aloe], entries: [], tags: [shade])
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(archive.tags?.first?.name == "Shade")
        #expect(archive.tags?.first?.normalizedName == "shade")
        #expect(Set(archive.tags?.first?.plantIDs ?? []) == [fern.id, aloe.id])
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: recovery) == 0)
        let restored = try #require(recovery.fetch(FetchDescriptor<PlantTag>()).first)
        #expect(restored.id == shade.id)
        #expect(Set(restored.plants?.map(\.id) ?? []) == [fern.id, aloe.id])
        // Identical content recovers as a no-op; a changed assignment conflicts.
        #expect(try JournalArchive.recover(data, context: recovery) == 0)
        restored.plants = [restored.plants?.first].compactMap { $0 }
        try recovery.save()
        #expect(throws: (any Error).self) { try JournalArchive.recover(data, context: recovery) }
    }

    @Test func archiveRejectsInvalidTagRecordsAndDecodesPreTagArchives() throws {
        let source = try memory(); let context = ModelContext(source)
        let fern = Plant(name: "Fern"); context.insert(fern)
        let tag = try #require(try PlantTagStore.tag(named: "Shade", context: context))
        tag.plants = [fern]; try context.save()
        let exported = try JournalArchive.export(plants: [fern], entries: [], tags: [tag])
        // Unknown plant reference inside a tag is rejected.
        var object = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        var records = try #require(object["tags"] as? [[String: Any]])
        records[0]["plantIDs"] = [UUID().uuidString]; object["tags"] = records
        let tampered = try JSONSerialization.data(withJSONObject: object)
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(throws: (any Error).self) { try JournalArchive.recover(tampered, context: recovery) }
        #expect(try recovery.fetch(FetchDescriptor<PlantTag>()).isEmpty)
        // Archives written before tags existed decode with no tags and recover cleanly.
        var legacyObject = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        legacyObject.removeValue(forKey: "tags")
        let legacy = try JSONSerialization.data(withJSONObject: legacyObject)
        let legacyDecoded = try JSONDecoder().decode(JournalArchive.self, from: legacy)
        #expect(legacyDecoded.tags == nil)
        #expect(try JournalArchive.recover(legacy, context: recovery) == 0)
        #expect(try recovery.fetch(FetchDescriptor<PlantTag>()).isEmpty)
        #expect(try recovery.fetch(FetchDescriptor<Plant>()).count == 1)
    }
}
