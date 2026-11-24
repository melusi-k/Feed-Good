import Foundation
import SwiftData
import Testing
@testable import FeedGood

/// This file is copied into a worktree at the exact pre-PR #121 commit by CI.
/// It therefore compiles against the shipped top-level V3 model types and
/// writes a genuine store using that historical model graph.
@MainActor
struct LegacyV3FixtureGeneratorTests {
    @Test func generateStoreUsingShippedV3ModelGraph() throws {
        let folder = URL(fileURLWithPath: "/tmp/feedgood-v3-fixture", isDirectory: true)
        try? FileManager.default.removeItem(at: folder)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let storeURL = folder.appendingPathComponent("garden.store")

        let plantID = UUID()
        let taskID = UUID()
        let eventID = UUID()
        let journalID = UUID()
        let tagID = UUID()
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let dueDate = Date(timeIntervalSince1970: 1_710_000_000)
        let completedAt = Date(timeIntervalSince1970: 1_705_000_000)

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV3.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)

            let plant = Plant(
                id: plantID,
                name: "Historical V3 Monstera",
                species: "Monstera deliciosa",
                notes: "Created by the pre-PR #121 model graph",
                growingEnvironment: .balcony,
                lightCondition: .indirect,
                photoData: Data([0x11, 0x22, 0x33]),
                createdAt: createdAt,
                archivedAt: nil
            )
            let task = CareTask(
                id: taskID,
                kind: .watering,
                intervalDays: 9,
                dueDate: dueDate,
                isEnabled: true,
                reminderEnabled: true,
                plant: plant
            )
            let event = CareEvent(
                id: eventID,
                taskID: taskID,
                taskTitle: "Watering",
                completedAt: completedAt,
                note: "Historical care event",
                plant: plant
            )
            let journal = JournalEntry(
                id: journalID,
                date: completedAt,
                note: "Historical journal entry",
                photoData: Data([0x44, 0x55]),
                milestoneRaw: "newLeaf",
                changeKindRaw: "repotted",
                plant: plant
            )
            let tag = PlantTag(id: tagID, name: "V3 tag")
            plant.tags = [tag]

            context.insert(plant)
            context.insert(task)
            context.insert(event)
            context.insert(journal)
            context.insert(tag)
            try context.save()
        }

        #expect(FileManager.default.fileExists(atPath: storeURL.path))
    }
}
