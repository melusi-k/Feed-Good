import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct CareOpportunityPersistenceTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    @Test func opportunityPersistsItsImmutableIdentityAndOptionalCompletionLink() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: date("2026-12-01T09:00:00Z"),
            plant: plant
        )
        context.insert(task)
        let event = CareEvent(task: task, completedAt: date("2026-12-01T09:05:00Z"))
        context.insert(event)
        let due = task.dueDate
        let opportunity = CareOpportunity(
            taskID: task.id,
            plantID: plant.id,
            scheduledDueAt: due,
            status: .completed,
            careEventID: event.id,
            createdAt: date("2026-11-25T12:00:00Z"),
            updatedAt: date("2026-12-01T09:05:00Z")
        )
        context.insert(opportunity)
        try context.save()

        let opportunityID = opportunity.id
        let fetched = try #require(
            context.fetch(FetchDescriptor<CareOpportunity>()).first { $0.id == opportunityID }
        )
        #expect(fetched.taskID == task.id)
        #expect(fetched.plantID == plant.id)
        #expect(fetched.scheduledDueAt == due)
        #expect(fetched.status == .completed)
        #expect(fetched.careEventID == event.id)
    }

    @Test func v4StoreMigratesToV5WithoutReconstructingHistoricalOpportunities() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("v4-garden.store")

        let plantID = UUID()
        let taskID = UUID()
        let eventID = UUID()
        let due = date("2026-11-01T09:00:00Z")
        let completed = date("2026-10-25T09:00:00Z")

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV4.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let plant = Plant(id: plantID, name: "Legacy Fern")
            let task = CareTask(
                id: taskID,
                kind: .watering,
                intervalDays: 7,
                dueDate: due,
                plant: plant
            )
            let event = CareEvent(
                id: eventID,
                taskID: taskID,
                taskTitle: "Watering",
                completedAt: completed,
                note: "Historical event",
                plant: plant
            )
            context.insert(plant)
            context.insert(task)
            context.insert(event)
            try context.save()
        }

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: FeedGoodMigrationPlan.self,
                configurations: [configuration]
            )
            let context = ModelContext(container)
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let tasks = try context.fetch(FetchDescriptor<CareTask>())
            let events = try context.fetch(FetchDescriptor<CareEvent>())
            let opportunities = try context.fetch(FetchDescriptor<CareOpportunity>())

            #expect(plants.count == 1)
            #expect(plants.first?.id == plantID)
            #expect(tasks.count == 1)
            #expect(tasks.first?.id == taskID)
            #expect(tasks.first?.dueDate == due)
            #expect(events.count == 1)
            #expect(events.first?.id == eventID)
            #expect(events.first?.completedAt == completed)
            #expect(opportunities.isEmpty)
        }
    }
}
