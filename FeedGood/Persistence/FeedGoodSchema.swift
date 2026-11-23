import Foundation
import SwiftData

/// The persisted model graph shipped before plant archiving was introduced.
/// Keep this schema immutable: it is the source of truth for migration from
/// existing installs that do not yet contain Plant.archivedAt.
enum FeedGoodSchemaV1: VersionedSchema {
    static var versionIdentifier = Schema.Version(1, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]
    }

    @Model
    final class Plant {
        var id: UUID
        var name: String
        var species: String
        var notes: String
        var growingEnvironmentRaw: String = "unspecified"
        var lightConditionRaw: String = "unspecified"
        @Attribute(.externalStorage) var photoData: Data?
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV1.CareTask.plant) var careTasks: [FeedGoodSchemaV1.CareTask]? = []
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV1.CareEvent.plant) var careEvents: [FeedGoodSchemaV1.CareEvent]? = []
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV1.JournalEntry.plant) var journalEntries: [FeedGoodSchemaV1.JournalEntry]? = []
        var createdAt: Date

        init(
            id: UUID = UUID(),
            name: String,
            species: String = "",
            notes: String = "",
            growingEnvironmentRaw: String = "unspecified",
            lightConditionRaw: String = "unspecified",
            photoData: Data? = nil,
            createdAt: Date = .now
        ) {
            self.id = id
            self.name = name
            self.species = species
            self.notes = notes
            self.growingEnvironmentRaw = growingEnvironmentRaw
            self.lightConditionRaw = lightConditionRaw
            self.photoData = photoData
            self.createdAt = createdAt
        }
    }

    @Model
    final class CareTask {
        var id: UUID = UUID()
        var kindRaw: String = "watering"
        var customTitle: String = ""
        var intervalDays: Int = 7
        var dueDate: Date = Date.now
        var isEnabled: Bool = true
        var reminderEnabled: Bool = false
        var plant: FeedGoodSchemaV1.Plant?

        init(
            id: UUID = UUID(),
            kindRaw: String = "watering",
            customTitle: String = "",
            intervalDays: Int = 7,
            dueDate: Date = .now,
            isEnabled: Bool = true,
            reminderEnabled: Bool = false,
            plant: FeedGoodSchemaV1.Plant
        ) {
            self.id = id
            self.kindRaw = kindRaw
            self.customTitle = customTitle
            self.intervalDays = intervalDays
            self.dueDate = dueDate
            self.isEnabled = isEnabled
            self.reminderEnabled = reminderEnabled
            self.plant = plant
        }
    }

    @Model
    final class CareEvent {
        var id: UUID = UUID()
        var taskID: UUID = UUID()
        var taskTitle: String = ""
        var completedAt: Date = Date.now
        var note: String = ""
        var plant: FeedGoodSchemaV1.Plant?

        init(
            id: UUID = UUID(),
            taskID: UUID,
            taskTitle: String,
            completedAt: Date = .now,
            note: String = "",
            plant: FeedGoodSchemaV1.Plant
        ) {
            self.id = id
            self.taskID = taskID
            self.taskTitle = taskTitle
            self.completedAt = completedAt
            self.note = note
            self.plant = plant
        }
    }

    @Model
    final class JournalEntry {
        var id: UUID = UUID()
        var date: Date = Date.now
        var note: String = ""
        @Attribute(.externalStorage) var photoData: Data?
        var milestoneRaw: String? = nil
        var plant: FeedGoodSchemaV1.Plant?

        init(
            id: UUID = UUID(),
            date: Date = .now,
            note: String,
            photoData: Data? = nil,
            milestoneRaw: String? = nil,
            plant: FeedGoodSchemaV1.Plant
        ) {
            self.id = id
            self.date = date
            self.note = note
            self.photoData = photoData
            self.milestoneRaw = milestoneRaw
            self.plant = plant
        }
    }
}

/// Current schema. V2 adds the optional Plant.archivedAt attribute; nil
/// represents an active plant and is the migration default for existing data.
enum FeedGoodSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]
    }
}

enum FeedGoodMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FeedGoodSchemaV1.self, FeedGoodSchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [MigrationStage.lightweight(fromVersion: FeedGoodSchemaV1.self, toVersion: FeedGoodSchemaV2.self)]
    }
}
