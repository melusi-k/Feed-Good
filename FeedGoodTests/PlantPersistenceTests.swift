import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct PlantPersistenceTests {
    @Test func profileEditsPhotoAndGrowingContextSurviveStoreReopen() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let schema = Schema([Plant.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: folder.appendingPathComponent("plants.store")
        )
        let plantID: UUID

        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let plant = Plant(name: "Monstera")
            plantID = plant.id
            context.insert(plant)

            var draft = PlantProfileDraft(plant: plant)
            draft.name = "  Monty  "
            draft.species = " Monstera deliciosa "
            draft.notes = " New leaf unfurling "
            draft.growingEnvironment = .balcony
            draft.lightCondition = .indirect
            draft.applying(to: plant)
            plant.photoData = Data([0x01, 0x02, 0x03])
            try context.save()
        }

        do {
            let reopenedContainer = try ModelContainer(for: schema, configurations: configuration)
            let reopenedContext = ModelContext(reopenedContainer)
            let stored = try reopenedContext.fetch(FetchDescriptor<Plant>())
            #expect(stored.count == 1)
            let reloaded = try #require(stored.first { $0.id == plantID })
            #expect(reloaded.name == "Monty")
            #expect(reloaded.species == "Monstera deliciosa")
            #expect(reloaded.notes == "New leaf unfurling")
            #expect(reloaded.photoData == Data([0x01, 0x02, 0x03]))
            #expect(reloaded.growingEnvironment == .balcony)
            #expect(reloaded.lightCondition == .indirect)
        }
    }

    @Test func newPlantsHaveNoAssumedGrowingContext() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Plant.self, configurations: configuration)
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()

        let stored = try #require(context.fetch(FetchDescriptor<Plant>()).first)
        #expect(stored.growingEnvironment == .unspecified)
        #expect(stored.lightCondition == .unspecified)
    }

    @Test func deletingPlantRemovesItFromStore() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Plant.self, configurations: configuration)
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()
        context.delete(plant)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Plant>()).isEmpty)
    }

    @Test func archivedStateSurvivesStoreReopen() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }

        let schema = Schema([Plant.self])
        let configuration = ModelConfiguration(
            schema: schema,
            url: folder.appendingPathComponent("plants.store")
        )
        let plantID: UUID
        let archivedDate = Date(timeIntervalSince1970: 1_700_000_000)

        do {
            let container = try ModelContainer(for: schema, configurations: configuration)
            let context = ModelContext(container)
            let plant = Plant(name: "Monstera", archivedAt: archivedDate)
            plantID = plant.id
            context.insert(plant)
            try context.save()
        }

        do {
            let reopenedContainer = try ModelContainer(for: schema, configurations: configuration)
            let reopenedContext = ModelContext(reopenedContainer)
            let stored = try reopenedContext.fetch(FetchDescriptor<Plant>())
            let reloaded = try #require(stored.first { $0.id == plantID })
            #expect(reloaded.archivedAt == archivedDate)
        }
    }

    @Test func legacyStoreMigratesPlantAndRelatedRecordsWithArchiveStateDefaultingToActive() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("legacy-garden.store")

        let plantID = UUID()
        let taskID = UUID()
        let eventID = UUID()
        let journalID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_650_000_000)
        let completedAt = Date(timeIntervalSince1970: 1_660_000_000)
        let dueDate = Date(timeIntervalSince1970: 1_670_000_000)

        // Produce a real on-disk store using the immutable pre-archive model
        // graph. This is deliberately not created with the current schema.
        do {
            let legacySchema = Schema(versionedSchema: FeedGoodSchemaV1.self)
            let legacyConfiguration = ModelConfiguration(schema: legacySchema, url: storeURL)
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: [legacyConfiguration]
            )
            let context = ModelContext(legacyContainer)
            let plant = FeedGoodSchemaV1.Plant(
                id: plantID,
                name: "Legacy Monstera",
                species: "Monstera deliciosa",
                notes: "A saved observation",
                growingEnvironmentRaw: "balcony",
                lightConditionRaw: "indirect",
                photoData: Data([0x01, 0x02, 0x03]),
                createdAt: createdAt
            )
            let task = FeedGoodSchemaV1.CareTask(
                id: taskID,
                kindRaw: "watering",
                intervalDays: 9,
                dueDate: dueDate,
                isEnabled: true,
                reminderEnabled: true,
                plant: plant
            )
            let event = FeedGoodSchemaV1.CareEvent(
                id: eventID,
                taskID: taskID,
                taskTitle: "Watering",
                completedAt: completedAt,
                note: "Completed before archive support",
                plant: plant
            )
            let journal = FeedGoodSchemaV1.JournalEntry(
                id: journalID,
                date: completedAt,
                note: "Older journal note",
                photoData: Data([0x04, 0x05]),
                milestoneRaw: "newLeaf",
                plant: plant
            )
            context.insert(plant)
            context.insert(task)
            context.insert(event)
            context.insert(journal)
            try context.save()
        }

        // Open that same store with the exact schema and migration plan used
        // by the production app. Existing plants must become active by default.
        do {
            let currentSchema = Schema(versionedSchema: FeedGoodSchemaV3.self)
            let currentConfiguration = ModelConfiguration(schema: currentSchema, url: storeURL)
            let migratedContainer = try ModelContainer(
                for: currentSchema,
                migrationPlan: FeedGoodMigrationPlan.self,
                configurations: [currentConfiguration]
            )
            let context = ModelContext(migratedContainer)
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let plant = try #require(plants.first { $0.id == plantID })

            #expect(plants.count == 1)
            #expect(plant.name == "Legacy Monstera")
            #expect(plant.species == "Monstera deliciosa")
            #expect(plant.notes == "A saved observation")
            #expect(plant.growingEnvironment == .balcony)
            #expect(plant.lightCondition == .indirect)
            #expect(plant.photoData == Data([0x01, 0x02, 0x03]))
            #expect(plant.createdAt == createdAt)
            #expect(plant.archivedAt == nil)

            let tasks = try context.fetch(FetchDescriptor<CareTask>())
            let events = try context.fetch(FetchDescriptor<CareEvent>())
            let entries = try context.fetch(FetchDescriptor<JournalEntry>())
            #expect(tasks.count == 1)
            #expect(tasks.first?.id == taskID)
            #expect(tasks.first?.plant?.id == plantID)
            #expect(tasks.first?.intervalDays == 9)
            #expect(events.count == 1)
            #expect(events.first?.id == eventID)
            #expect(events.first?.plant?.id == plantID)
            #expect(events.first?.note == "Completed before archive support")
            #expect(entries.count == 1)
            #expect(entries.first?.id == journalID)
            #expect(entries.first?.plant?.id == plantID)
            #expect(entries.first?.photoData == Data([0x04, 0x05]))
            #expect(entries.first?.milestoneRaw == "newLeaf")

            // The full V1-V3 chain leaves an existing plant tagless, and tags
            // work immediately after migration.
            #expect(plant.tags?.isEmpty != false)
            #expect(try context.fetch(FetchDescriptor<PlantTag>()).isEmpty)
            let tag = try #require(try PlantTagStore.tag(named: "Legacy", context: context))
            tag.plants = [plant]
            try context.save()
            #expect(try context.fetch(FetchDescriptor<PlantTag>()).count == 1)
            #expect(plant.tags?.map(\.name) == ["Legacy"])
        }
    }

}
