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

/// V2 adds the optional Plant.archivedAt attribute; nil
/// represents an active plant and is the migration default for existing data.
/// Frozen at the V3 bump: these nested copies capture the exact V2 shape so
/// the V2 model checksum stays distinct from V3. Referencing the live types
/// here would pull PlantTag into V2's resolved model (via Plant.tags) and
/// crash migration setup with "Duplicate version checksums detected."
enum FeedGoodSchemaV2: VersionedSchema {
    static var versionIdentifier = Schema.Version(2, 0, 0)
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
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV2.CareTask.plant) var careTasks: [FeedGoodSchemaV2.CareTask]? = []
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV2.CareEvent.plant) var careEvents: [FeedGoodSchemaV2.CareEvent]? = []
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV2.JournalEntry.plant) var journalEntries: [FeedGoodSchemaV2.JournalEntry]? = []
        var createdAt: Date
        var archivedAt: Date?

        init(
            id: UUID = UUID(),
            name: String,
            species: String = "",
            notes: String = "",
            growingEnvironmentRaw: String = "unspecified",
            lightConditionRaw: String = "unspecified",
            photoData: Data? = nil,
            createdAt: Date = .now,
            archivedAt: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.species = species
            self.notes = notes
            self.growingEnvironmentRaw = growingEnvironmentRaw
            self.lightConditionRaw = lightConditionRaw
            self.photoData = photoData
            self.createdAt = createdAt
            self.archivedAt = archivedAt
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
        var plant: FeedGoodSchemaV2.Plant?

        init(
            id: UUID = UUID(),
            kindRaw: String = "watering",
            customTitle: String = "",
            intervalDays: Int = 7,
            dueDate: Date = Date.now,
            isEnabled: Bool = true,
            reminderEnabled: Bool = false,
            plant: FeedGoodSchemaV2.Plant
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
        var plant: FeedGoodSchemaV2.Plant?

        init(
            id: UUID = UUID(),
            taskID: UUID,
            taskTitle: String,
            completedAt: Date = .now,
            note: String = "",
            plant: FeedGoodSchemaV2.Plant
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
        var plant: FeedGoodSchemaV2.Plant?

        init(
            id: UUID = UUID(),
            date: Date = Date.now,
            note: String,
            photoData: Data? = nil,
            milestoneRaw: String? = nil,
            plant: FeedGoodSchemaV2.Plant
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

/// Frozen V3 model graph. Do not reference the live models here: V4 adds
/// QuietPeriod relationships to Plant and must not change the V3 checksum.
/// These nested types preserve the exact persisted V3 shape, including tags
/// and JournalEntry.changeKindRaw.
enum FeedGoodSchemaV3: VersionedSchema {
    static var versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self, PlantTag.self]
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
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV3.CareTask.plant) var careTasks: [FeedGoodSchemaV3.CareTask]? = []
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV3.CareEvent.plant) var careEvents: [FeedGoodSchemaV3.CareEvent]? = []
        @Relationship(deleteRule: .cascade, inverse: \FeedGoodSchemaV3.JournalEntry.plant) var journalEntries: [FeedGoodSchemaV3.JournalEntry]? = []
        @Relationship var tags: [FeedGoodSchemaV3.PlantTag]? = []
        var createdAt: Date
        var archivedAt: Date?

        init(
            id: UUID = UUID(),
            name: String,
            species: String = "",
            notes: String = "",
            growingEnvironmentRaw: String = "unspecified",
            lightConditionRaw: String = "unspecified",
            photoData: Data? = nil,
            createdAt: Date = .now,
            archivedAt: Date? = nil
        ) {
            self.id = id
            self.name = name
            self.species = species
            self.notes = notes
            self.growingEnvironmentRaw = growingEnvironmentRaw
            self.lightConditionRaw = lightConditionRaw
            self.photoData = photoData
            self.createdAt = createdAt
            self.archivedAt = archivedAt
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
        var plant: FeedGoodSchemaV3.Plant?

        init(
            id: UUID = UUID(),
            kindRaw: String = "watering",
            customTitle: String = "",
            intervalDays: Int = 7,
            dueDate: Date = .now,
            isEnabled: Bool = true,
            reminderEnabled: Bool = false,
            plant: FeedGoodSchemaV3.Plant
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
        var plant: FeedGoodSchemaV3.Plant?

        init(
            id: UUID = UUID(),
            taskID: UUID,
            taskTitle: String,
            completedAt: Date = .now,
            note: String = "",
            plant: FeedGoodSchemaV3.Plant
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
        var changeKindRaw: String? = nil
        var plant: FeedGoodSchemaV3.Plant?

        init(
            id: UUID = UUID(),
            date: Date = .now,
            note: String,
            photoData: Data? = nil,
            milestoneRaw: String? = nil,
            changeKindRaw: String? = nil,
            plant: FeedGoodSchemaV3.Plant
        ) {
            self.id = id
            self.date = date
            self.note = note
            self.photoData = photoData
            self.milestoneRaw = milestoneRaw
            self.changeKindRaw = changeKindRaw
            self.plant = plant
        }
    }

    @Model
    final class PlantTag {
        var id: UUID = UUID()
        var name: String = ""
        var normalizedName: String = ""
        @Relationship(inverse: \FeedGoodSchemaV3.Plant.tags) var plants: [FeedGoodSchemaV3.Plant]? = []

        init(id: UUID = UUID(), name: String, normalizedName: String) {
            self.id = id
            self.name = name
            self.normalizedName = normalizedName
        }
    }
}

/// V4 is the frozen Quiet Period schema. Do not add models or properties here:
/// existing V4 stores must continue to resolve against this exact model graph.
enum FeedGoodSchemaV4: VersionedSchema {
    static var versionIdentifier = Schema.Version(4, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self, PlantTag.self, QuietPeriod.self, QuietPeriodTaskSnapshot.self]
    }
}

/// V5 is frozen at the original scheduled-opportunity shape. Keep its nested
/// model immutable so existing V5 stores can migrate to V6 without checksum drift.
enum FeedGoodSchemaV5: VersionedSchema {
    static var versionIdentifier = Schema.Version(5, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self, PlantTag.self, QuietPeriod.self, QuietPeriodTaskSnapshot.self, CareOpportunity.self]
    }

    @Model
    final class CareOpportunity {
        var id: UUID = UUID()
        var taskID: UUID
        var plantID: UUID
        var scheduledDueAt: Date
        var statusRaw: String = "open"
        var careEventID: UUID?
        var createdAt: Date
        var updatedAt: Date

        init(
            id: UUID = UUID(),
            taskID: UUID,
            plantID: UUID,
            scheduledDueAt: Date,
            statusRaw: String = "open",
            careEventID: UUID? = nil,
            createdAt: Date = .now,
            updatedAt: Date = .now
        ) {
            self.id = id
            self.taskID = taskID
            self.plantID = plantID
            self.scheduledDueAt = scheduledDueAt
            self.statusRaw = statusRaw
            self.careEventID = careEventID
            self.createdAt = createdAt
            self.updatedAt = updatedAt
        }
    }
}

/// V6 adds the mutable effective due boundary. Existing V5 opportunities keep
/// their IDs and original due instant; migration initializes effectiveDueAt
/// from scheduledDueAt rather than reconstructing any historical care.
enum FeedGoodSchemaV6: VersionedSchema {
    static var versionIdentifier = Schema.Version(6, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self, PlantTag.self, QuietPeriod.self, QuietPeriodTaskSnapshot.self, CareOpportunity.self]
    }
}

enum FeedGoodMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [FeedGoodSchemaV1.self, FeedGoodSchemaV2.self, FeedGoodSchemaV3.self, FeedGoodSchemaV4.self, FeedGoodSchemaV5.self, FeedGoodSchemaV6.self]
    }

    static var stages: [MigrationStage] {
        [
            MigrationStage.lightweight(fromVersion: FeedGoodSchemaV1.self, toVersion: FeedGoodSchemaV2.self),
            MigrationStage.lightweight(fromVersion: FeedGoodSchemaV2.self, toVersion: FeedGoodSchemaV3.self),
            MigrationStage.lightweight(fromVersion: FeedGoodSchemaV3.self, toVersion: FeedGoodSchemaV4.self),
            MigrationStage.custom(
                fromVersion: FeedGoodSchemaV4.self,
                toVersion: FeedGoodSchemaV5.self,
                willMigrate: { _ in },
                didMigrate: { context in
                    let migrationDate = Date.now
                    let tasks = try context.fetch(FetchDescriptor<CareTask>())
                    for task in tasks {
                        guard task.isEnabled,
                              let plant = task.plant,
                              plant.archivedAt == nil else { continue }
                        context.insert(FeedGoodSchemaV5.CareOpportunity(
                            taskID: task.id,
                            plantID: plant.id,
                            scheduledDueAt: task.dueDate,
                            createdAt: migrationDate,
                            updatedAt: migrationDate
                        ))
                    }
                    try context.save()
                }
            ),
            MigrationStage.custom(
                fromVersion: FeedGoodSchemaV5.self,
                toVersion: FeedGoodSchemaV6.self,
                willMigrate: { _ in },
                didMigrate: { context in
                    for opportunity in try context.fetch(FetchDescriptor<CareOpportunity>()) {
                        opportunity.effectiveDueAt = opportunity.scheduledDueAt
                    }
                    try context.save()
                }
            )
        ]
    }
}
