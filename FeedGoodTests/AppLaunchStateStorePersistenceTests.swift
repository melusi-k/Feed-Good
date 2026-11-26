import Foundation
import SwiftData
import Testing
@testable import FeedGood

/// Exercises launch eligibility against a real on-disk SwiftData store using
/// the same schema/configuration shape as FeedGoodApp, rather than a mocked
/// Boolean. The temporary URL keeps the test isolated from a developer's data.
@MainActor
struct AppLaunchStateStorePersistenceTests {
    private func makeStoreURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppLaunchStateStorePersistenceTests.\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("default.store")
    }

    private func makeConfiguration(at url: URL) -> (Schema, ModelConfiguration) {
        let schema = Schema(versionedSchema: FeedGoodSchemaV6.self)
        let configuration = ModelConfiguration(schema: schema, url: url)
        return (schema, configuration)
    }

    @Test func existingEmptyGardenStoreSuppressesOnboarding() throws {
        let storeURL = try makeStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }
        let (schema, configuration) = makeConfiguration(at: storeURL)

        // ModelContainer creates the persistent store even when the garden is empty.
        let container = try ModelContainer(
            for: schema,
            migrationPlan: FeedGoodMigrationPlan.self,
            configurations: [configuration]
        )
        #expect(FileManager.default.fileExists(atPath: configuration.url.path))
        #expect(try ModelContext(container).fetch(FetchDescriptor<Plant>()).isEmpty)

        let defaults = UserDefaults(suiteName: "AppLaunchStateStorePersistenceTests.empty.\(UUID().uuidString)")!
        let launchState = AppLaunchStateStore(
            defaults: defaults,
            hasExistingPersistentStore: FileManager.default.fileExists(atPath: configuration.url.path)
        )
        launchState.bootstrap(versionIdentity: "0.1.46 (46)")

        #expect(launchState.shouldPresentOnboarding == false)
        #expect(defaults.bool(forKey: AppLaunchStateStore.onboardingCompletedKey))
    }

    @Test func existingGardenStoreIsRecognisedAndAllUserRecordsRemainReadable() throws {
        let storeURL = try makeStoreURL()
        defer { try? FileManager.default.removeItem(at: storeURL.deletingLastPathComponent()) }
        let (schema, configuration) = makeConfiguration(at: storeURL)

        let plantID = UUID()
        let taskID = UUID()
        let eventID = UUID()
        let journalID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let completedAt = Date(timeIntervalSince1970: 1_710_000_000)

        // Write a representative garden using the app's current production schema.
        do {
            let container = try ModelContainer(
                for: schema,
                migrationPlan: FeedGoodMigrationPlan.self,
                configurations: [configuration]
            )
            let context = ModelContext(container)
            let plant = Plant(
                id: plantID,
                name: "Launch migration Monstera",
                species: "Monstera deliciosa",
                notes: "Keep this garden data",
                createdAt: createdAt
            )
            let task = CareTask(
                id: taskID,
                kind: .watering,
                intervalDays: 9,
                dueDate: completedAt,
                plant: plant
            )
            let event = CareEvent(
                id: eventID,
                taskID: taskID,
                taskTitle: "Watering",
                completedAt: completedAt,
                note: "Existing care history",
                plant: plant
            )
            let journal = JournalEntry(
                id: journalID,
                date: completedAt,
                note: "Existing journal entry",
                photoData: Data([0x10, 0x20, 0x30]),
                plant: plant
            )
            context.insert(plant)
            context.insert(task)
            context.insert(event)
            context.insert(journal)
            try context.save()
        }

        #expect(FileManager.default.fileExists(atPath: configuration.url.path))

        let defaults = UserDefaults(suiteName: "AppLaunchStateStorePersistenceTests.populated.\(UUID().uuidString)")!
        let launchState = AppLaunchStateStore(
            defaults: defaults,
            hasExistingPersistentStore: FileManager.default.fileExists(atPath: configuration.url.path)
        )
        launchState.bootstrap(versionIdentity: "0.1.46 (46)")
        #expect(launchState.shouldPresentOnboarding == false)

        // Reopen the same on-disk store after bootstrap and verify every
        // representative record and relationship is still intact.
        let reopenedContainer = try ModelContainer(
            for: schema,
            migrationPlan: FeedGoodMigrationPlan.self,
            configurations: [configuration]
        )
        let context = ModelContext(reopenedContainer)
        let plants = try context.fetch(FetchDescriptor<Plant>())
        let tasks = try context.fetch(FetchDescriptor<CareTask>())
        let events = try context.fetch(FetchDescriptor<CareEvent>())
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())

        #expect(plants.count == 1)
        #expect(plants.first?.id == plantID)
        #expect(plants.first?.name == "Launch migration Monstera")
        #expect(plants.first?.notes == "Keep this garden data")
        #expect(plants.first?.createdAt == createdAt)
        #expect(tasks.count == 1)
        #expect(tasks.first?.id == taskID)
        #expect(tasks.first?.plant?.id == plantID)
        #expect(tasks.first?.intervalDays == 9)
        #expect(events.count == 1)
        #expect(events.first?.id == eventID)
        #expect(events.first?.plant?.id == plantID)
        #expect(events.first?.note == "Existing care history")
        #expect(entries.count == 1)
        #expect(entries.first?.id == journalID)
        #expect(entries.first?.plant?.id == plantID)
        #expect(entries.first?.photoData == Data([0x10, 0x20, 0x30]))
    }
}
