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
            let currentSchema = Schema(versionedSchema: FeedGoodSchemaV6.self)
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

    @Test func build52EraStoreOpensAndMigratesToCurrentSchema() throws {
        // Regression for the build-52 -> 54 launch crash: #105 added
        // JournalEntry.changeKindRaw to the live V2 model without a schema
        // version bump, so a store written by build 52 matched no versioned
        // schema and the app trapped in ModelContainer init. FeedGoodSchemaV2
        // is the frozen build-52 model graph (JournalEntry without
        // changeKindRaw, Plant without tags); writing a store with it and
        // reopening with the production schema and migration plan is exactly
        // the owner's upgrade path. The store must open, keep every record,
        // and gain nil changeKindRaw and no tags.
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("build-52-garden.store")

        let plantID = UUID()
        let journalID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_650_000_000)
        let writtenAt = Date(timeIntervalSince1970: 1_700_000_000)

        do {
            let legacySchema = Schema(versionedSchema: FeedGoodSchemaV2.self)
            let legacyConfiguration = ModelConfiguration(schema: legacySchema, url: storeURL)
            let legacyContainer = try ModelContainer(
                for: legacySchema,
                configurations: [legacyConfiguration]
            )
            let context = ModelContext(legacyContainer)
            let plant = FeedGoodSchemaV2.Plant(
                id: plantID,
                name: "Build 52 Fern",
                species: "Nephrolepis exaltata",
                createdAt: createdAt,
                archivedAt: nil
            )
            let journal = FeedGoodSchemaV2.JournalEntry(
                id: journalID,
                date: writtenAt,
                note: "Written on build 52",
                milestoneRaw: "newLeaf",
                plant: plant
            )
            context.insert(plant)
            context.insert(journal)
            try context.save()
        }

        do {
            let currentSchema = Schema(versionedSchema: FeedGoodSchemaV6.self)
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
            #expect(plant.name == "Build 52 Fern")
            #expect(plant.createdAt == createdAt)
            #expect(plant.tags?.isEmpty != false)

            let entries = try context.fetch(FetchDescriptor<JournalEntry>())
            let entry = try #require(entries.first { $0.id == journalID })
            #expect(entries.count == 1)
            #expect(entry.note == "Written on build 52")
            #expect(entry.milestoneRaw == "newLeaf")
            #expect(entry.changeKindRaw == nil)
            #expect(entry.plant?.id == plantID)
            #expect(try context.fetch(FetchDescriptor<PlantTag>()).isEmpty)
        }
    }


    @Test func version3StoreWithTagsMigratesToVersion5WithoutLosingRecords() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("v3-garden.store")

        let plantID = UUID()
        let taskID = UUID()
        let eventID = UUID()
        let journalID = UUID()
        let tagID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_710_000_000)
        let dueDate = Date(timeIntervalSince1970: 1_720_000_000)
        let completedAt = Date(timeIntervalSince1970: 1_730_000_000)

        // This fixture is written with the frozen V3 graph, including the
        // PlantTag relationship and the V3 JournalEntry change-kind field.
        do {
            let legacySchema = Schema(versionedSchema: FeedGoodSchemaV3.self)
            let configuration = ModelConfiguration(schema: legacySchema, url: storeURL)
            let container = try ModelContainer(for: legacySchema, configurations: [configuration])
            let context = ModelContext(container)
            let plant = FeedGoodSchemaV3.Plant(
                id: plantID,
                name: "V3 Monstera",
                species: "Monstera deliciosa",
                notes: "Written before Quiet Period support",
                growingEnvironmentRaw: "balcony",
                lightConditionRaw: "indirect",
                photoData: Data([0x10, 0x20]),
                createdAt: createdAt,
                archivedAt: nil
            )
            let task = FeedGoodSchemaV3.CareTask(
                id: taskID,
                kindRaw: "watering",
                intervalDays: 11,
                dueDate: dueDate,
                isEnabled: true,
                reminderEnabled: true,
                plant: plant
            )
            let event = FeedGoodSchemaV3.CareEvent(
                id: eventID,
                taskID: taskID,
                taskTitle: "Watering",
                completedAt: completedAt,
                note: "V3 care history",
                plant: plant
            )
            let journal = FeedGoodSchemaV3.JournalEntry(
                id: journalID,
                date: completedAt,
                note: "V3 journal",
                photoData: Data([0x30, 0x40]),
                milestoneRaw: "newLeaf",
                changeKindRaw: "repotted",
                plant: plant
            )
            let tag = FeedGoodSchemaV3.PlantTag(
                id: tagID,
                name: "Balcony",
                normalizedName: "balcony"
            )
            plant.tags = [tag]
            context.insert(plant)
            context.insert(task)
            context.insert(event)
            context.insert(journal)
            context.insert(tag)
            try context.save()
        }

        // Open the same on-disk V3 store with the production V5 schema and
        // complete V1 -> V2 -> V3 -> V4 -> V5 migration plan.
        do {
            let currentSchema = Schema(versionedSchema: FeedGoodSchemaV6.self)
            let configuration = ModelConfiguration(schema: currentSchema, url: storeURL)
            let container = try ModelContainer(
                for: currentSchema,
                migrationPlan: FeedGoodMigrationPlan.self,
                configurations: [configuration]
            )
            let context = ModelContext(container)
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let plant = try #require(plants.first { $0.id == plantID })

            #expect(plants.count == 1)
            #expect(plant.name == "V3 Monstera")
            #expect(plant.species == "Monstera deliciosa")
            #expect(plant.notes == "Written before Quiet Period support")
            #expect(plant.createdAt == createdAt)
            #expect(plant.archivedAt == nil)
            #expect(plant.photoData == Data([0x10, 0x20]))

            let tasks = try context.fetch(FetchDescriptor<CareTask>())
            #expect(tasks.count == 1)
            #expect(tasks.first?.id == taskID)
            #expect(tasks.first?.intervalDays == 11)
            #expect(tasks.first?.dueDate == dueDate)
            #expect(tasks.first?.plant?.id == plantID)

            let events = try context.fetch(FetchDescriptor<CareEvent>())
            #expect(events.count == 1)
            #expect(events.first?.id == eventID)
            #expect(events.first?.note == "V3 care history")
            #expect(events.first?.plant?.id == plantID)

            let entries = try context.fetch(FetchDescriptor<JournalEntry>())
            #expect(entries.count == 1)
            #expect(entries.first?.id == journalID)
            #expect(entries.first?.note == "V3 journal")
            #expect(entries.first?.photoData == Data([0x30, 0x40]))
            #expect(entries.first?.milestoneRaw == "newLeaf")
            #expect(entries.first?.changeKindRaw == "repotted")
            #expect(entries.first?.plant?.id == plantID)

            #expect(plant.tags?.map(\.id) == [tagID])
            #expect(plant.tags?.map(\.normalizedName) == ["balcony"])
            #expect(plant.quietPeriods?.isEmpty != false)
            #expect(try context.fetch(FetchDescriptor<QuietPeriod>()).isEmpty)
            #expect(try context.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>()).isEmpty)
        }
    }


    @Test func shippedTopLevelV3StoreMigratesToVersion5WithoutLosingRecords() throws {
        // CI creates this store by compiling the exact pre-PR #121 source and
        // writing it with its original top-level V3 SwiftData model types.
        let storeURL = URL(fileURLWithPath: "/tmp/feedgood-v3-fixture/garden.store")
        guard FileManager.default.fileExists(atPath: storeURL.path) else { return }

        let schema = Schema(versionedSchema: FeedGoodSchemaV6.self)
        let configuration = ModelConfiguration(schema: schema, url: storeURL)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: FeedGoodMigrationPlan.self,
            configurations: [configuration]
        )
        let context = ModelContext(container)

        let plants = try context.fetch(FetchDescriptor<Plant>())
        let plant = try #require(plants.first { $0.name == "Historical V3 Monstera" })
        #expect(plants.count == 1)
        #expect(plant.species == "Monstera deliciosa")
        #expect(plant.notes == "Created by the pre-PR #121 model graph")
        #expect(plant.growingEnvironment == .balcony)
        #expect(plant.lightCondition == .indirect)
        #expect(plant.photoData == Data([0x11, 0x22, 0x33]))
        #expect(plant.createdAt == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(plant.archivedAt == nil)
        #expect(plant.tags?.map(\.name) == ["V3 tag"])

        let tasks = try context.fetch(FetchDescriptor<CareTask>())
        #expect(tasks.count == 1)
        #expect(tasks.first?.kind == .watering)
        #expect(tasks.first?.intervalDays == 9)
        #expect(tasks.first?.dueDate == Date(timeIntervalSince1970: 1_710_000_000))
        #expect(tasks.first?.plant?.id == plant.id)

        let events = try context.fetch(FetchDescriptor<CareEvent>())
        #expect(events.count == 1)
        #expect(events.first?.taskTitle == "Watering")
        #expect(events.first?.note == "Historical care event")
        #expect(events.first?.completedAt == Date(timeIntervalSince1970: 1_705_000_000))
        #expect(events.first?.plant?.id == plant.id)

        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(entries.count == 1)
        #expect(entries.first?.note == "Historical journal entry")
        #expect(entries.first?.photoData == Data([0x44, 0x55]))
        #expect(entries.first?.milestoneRaw == "newLeaf")
        #expect(entries.first?.changeKindRaw == "repotted")
        #expect(entries.first?.plant?.id == plant.id)

        #expect(try context.fetch(FetchDescriptor<QuietPeriod>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>()).isEmpty)
    }


    @Test func checkInStoreCreatesEditsAndDeletesWithoutTouchingCare() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(versionedSchema: FeedGoodSchemaV7.self), configurations: configuration)
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let dueDate = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: dueDate, plant: plant)
        context.insert(task)
        try context.save()

        var draft = PlantCheckInDraft(
            observedAt: Date(timeIntervalSince1970: 1_700_000_000),
            signs: [.yellowing, .spots],
            note: "  Lower leaves have small marks  ",
            photoData: Data([0x01, 0x02])
        )
        try PlantCheckInStore.save(draft, for: plant, in: context)
        var records = try context.fetch(FetchDescriptor<PlantCheckIn>())
        #expect(records.count == 1)
        let checkIn = try #require(records.first)
        let checkInID = checkIn.id
        #expect(checkIn.plantID == plant.id)
        #expect(checkIn.signRawValues == ["spots", "yellowing"])
        #expect(checkIn.note == "Lower leaves have small marks")
        #expect(checkIn.photoData == Data([0x01, 0x02]))

        draft.observedAt = Date(timeIntervalSince1970: 1_710_000_000)
        draft.signs = [.wilting]
        draft.note = "Updated observation"
        draft.photoData = nil
        try PlantCheckInStore.save(draft, for: plant, editing: checkIn, in: context)
        records = try context.fetch(FetchDescriptor<PlantCheckIn>())
        #expect(records.count == 1)
        #expect(records.first?.id == checkInID)
        #expect(records.first?.signRawValues == ["wilting"])
        #expect(records.first?.note == "Updated observation")
        #expect(task.dueDate == dueDate)
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)

        try PlantCheckInStore.delete(checkIn, in: context)
        #expect(try context.fetch(FetchDescriptor<PlantCheckIn>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<CareTask>()).count == 1)
    }

    @Test func checkInStoreEnforcesPlantIsolationAndNotSureExclusivity() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(versionedSchema: FeedGoodSchemaV7.self), configurations: configuration)
        let context = ModelContext(container)
        let fern = Plant(name: "Fern")
        let aloe = Plant(name: "Aloe")
        context.insert(fern)
        context.insert(aloe)
        try context.save()

        let invalid = PlantCheckInDraft(signs: [.notSure, .yellowing])
        #expect(throws: PlantCheckInStoreError.invalidRecord) {
            try PlantCheckInStore.save(invalid, for: fern, in: context)
        }
        let valid = PlantCheckInDraft(signs: [.yellowing])
        try PlantCheckInStore.save(valid, for: fern, in: context)
        let record = try #require(context.fetch(FetchDescriptor<PlantCheckIn>()).first)
        #expect(throws: PlantCheckInStoreError.invalidRecord) {
            try PlantCheckInStore.save(valid, for: aloe, editing: record, in: context)
        }
        #expect(try context.fetch(FetchDescriptor<PlantCheckIn>()).count == 1)
    }

    @Test func checkInStoreRejectsNewRecordsForArchivedPlants() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(versionedSchema: FeedGoodSchemaV7.self), configurations: configuration)
        let context = ModelContext(container)
        let plant = Plant(name: "Fern", archivedAt: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(plant)
        try context.save()

        #expect(throws: PlantCheckInStoreError.archivedPlant) {
            try PlantCheckInStore.save(PlantCheckInDraft(signs: [.wilting]), for: plant, in: context)
        }
        #expect(try context.fetch(FetchDescriptor<PlantCheckIn>()).isEmpty)
    }

    @Test func v6StoreMigratesToV7WithoutChangingExistingPlantData() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("v6-garden.store")
        let plantID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_650_000_000)

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV6.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            context.insert(Plant(id: plantID, name: "Legacy Fern", notes: "Keep this note", createdAt: createdAt))
            try context.save()
        }

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV7.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, migrationPlan: FeedGoodMigrationPlan.self, configurations: [configuration])
            let context = ModelContext(container)
            let plants = try context.fetch(FetchDescriptor<Plant>())
            #expect(plants.count == 1)
            #expect(plants.first?.id == plantID)
            #expect(plants.first?.name == "Legacy Fern")
            #expect(plants.first?.notes == "Keep this note")
            #expect(plants.first?.createdAt == createdAt)
            #expect(try context.fetch(FetchDescriptor<PlantCheckIn>()).isEmpty)
        }
    }


    @Test func permanentlyDeletingPlantStagesAndRemovesItsCheckIns() throws {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(versionedSchema: FeedGoodSchemaV7.self), configurations: configuration)
        let context = ModelContext(container)
        let fern = Plant(name: "Fern")
        let aloe = Plant(name: "Aloe")
        context.insert(fern)
        context.insert(aloe)
        try context.save()

        try PlantCheckInStore.save(PlantCheckInDraft(signs: [.yellowing]), for: fern, in: context)
        try PlantCheckInStore.save(PlantCheckInDraft(signs: [.wilting]), for: aloe, in: context)
        try PlantCheckInStore.deleteAll(for: fern.id, in: context)
        context.delete(fern)
        try context.save()

        let remaining = try context.fetch(FetchDescriptor<PlantCheckIn>())
        #expect(remaining.count == 1)
        #expect(remaining.first?.plantID == aloe.id)
        #expect(try context.fetch(FetchDescriptor<Plant>()).map { $0.id } == [aloe.id])
    }

}
