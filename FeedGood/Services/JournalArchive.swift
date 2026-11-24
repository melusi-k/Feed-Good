import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum JournalArchiveError: LocalizedError, Equatable {
    case invalidRecord, unsupportedVersion, tooLarge, conflictingRecord, unsavedChanges
    var errorDescription: String? {
        switch self {
        case .invalidRecord: return "This archive has an invalid record, plant reference or photo. Nothing was imported."
        case .unsupportedVersion: return "This archive version isn't supported. Nothing was imported."
        case .tooLarge: return "This archive exceeds the 25 MB or 1,000-record safety limit. Nothing was imported."
        case .conflictingRecord: return "A record has the same ID but different content. Nothing was imported; existing records are unchanged."
        case .unsavedChanges: return "Save or discard pending changes before recovering an archive. Your unsaved changes have been preserved."
        }
    }
}


struct JournalArchivePreview: Equatable {
    let version: Int
    let plantsToAdd: Int
    let plantsAlreadyPresent: Int
    let entriesToAdd: Int
    let entriesAlreadyPresent: Int
    let careTasksToAdd: Int
    let careTasksAlreadyPresent: Int
    let careEventsToAdd: Int
    let careEventsAlreadyPresent: Int
    let quietPeriodsToAdd: Int = 0
    let quietPeriodsAlreadyPresent: Int = 0
    let quietPeriodSnapshotsToAdd: Int = 0
    let quietPeriodSnapshotsAlreadyPresent: Int = 0

    var confirmationMessage: String {
        """
        Archive version \(version)
        Plants: \(plantsToAdd) to add, \(plantsAlreadyPresent) already present
        Journal entries: \(entriesToAdd) to add, \(entriesAlreadyPresent) already present
        Care routines: \(careTasksToAdd) to add, \(careTasksAlreadyPresent) already present
        Care history: \(careEventsToAdd) to add, \(careEventsAlreadyPresent) already present
        Quiet Periods: \(quietPeriodsToAdd) to add, \(quietPeriodsAlreadyPresent) already present
        Quiet Period task snapshots: \(quietPeriodSnapshotsToAdd) to add, \(quietPeriodSnapshotsAlreadyPresent) already present

        Existing plant records are preserved. Archive timestamps are restored for new plants; existing same-ID plants keep their current state. Existing journal and care records are checked for identical content; any conflict stops recovery before changes are saved.
        """
    }
}

/// Version 1 is journal-only, version 2 adds the complete garden record and tags, and version 3 adds Quiet Period history. Optional record keys preserve decoding of older archives.
struct JournalArchive: Codable {
    var version = 3
    var plants: [PlantRecord]
    var entries: [EntryRecord]
    var careTasks: [CareTaskRecord]?
    var careEvents: [CareEventRecord]?
    // Optional so pre-tag archives decode with no tags.
    var tags: [TagRecord]?
    var quietPeriods: [QuietPeriodRecord]?
    var quietPeriodTaskSnapshots: [QuietPeriodTaskSnapshotRecord]?

    struct PlantRecord: Codable {
        var id: UUID
        var name: String
        var species: String
        var notes: String
        var createdAt: Date
        var photoData: Data? = nil
        // Optional keys keep archives created before growing context decodable.
        var growingEnvironmentRaw: String? = nil
        var lightConditionRaw: String? = nil
        // Optional so version 1 and pre-archive version 2 files decode as active plants.
        var archivedAt: Date? = nil
    }

    struct EntryRecord: Codable, Equatable {
        var id: UUID
        var plantID: UUID
        var date: Date
        var note: String
        var photoData: Data?
        var milestoneRaw: String? = nil
        // Optional so archives written before plant change records decode as ordinary entries.
        var changeKindRaw: String? = nil
    }

    struct TagRecord: Codable, Equatable {
        var id: UUID
        var name: String
        var normalizedName: String
        var plantIDs: [UUID]
    }

    struct CareTaskRecord: Codable, Equatable {
        var id: UUID
        var plantID: UUID
        var kindRaw: String
        var customTitle: String
        var intervalDays: Int
        var dueDate: Date
        var isEnabled: Bool
        var reminderEnabled: Bool
    }

    struct CareEventRecord: Codable, Equatable {
        var id: UUID
        var plantID: UUID
        var taskID: UUID
        var taskTitle: String
        var completedAt: Date
        var note: String
    }

    struct QuietPeriodRecord: Codable, Equatable {
        var id: UUID
        var plantID: UUID
        var createdAt: Date
        var startAt: Date
        var endAt: Date?
        var statusRaw: String
        var reason: String?
        var activatedAt: Date?
        var endedAt: Date?
    }

    struct QuietPeriodTaskSnapshotRecord: Codable, Equatable {
        var id: UUID
        var quietPeriodID: UUID
        var taskID: UUID
        var taskTitleSnapshot: String
        var membershipStatusRaw: String
        var remainingCalendarDays: Int?
        var originalDueHour: Int?
        var originalDueMinute: Int?
        var originalDueSecond: Int?
        var frozenIntervalDays: Int?
        var nextCareOverrideAt: Date?
        var capturedAt: Date
        var updatedAt: Date
    }

    static let maxBytes = 25 * 1024 * 1024
    static let maxRecords = 1000

    @MainActor
    static func export(
        plants: [Plant],
        entries: [JournalEntry],
        careTasks: [CareTask] = [],
        careEvents: [CareEvent] = [],
        tags: [PlantTag] = [],
        quietPeriods: [QuietPeriod] = [],
        quietPeriodTaskSnapshots: [QuietPeriodTaskSnapshot] = []
    ) throws -> Data {
        let entryRecords = try entries.map { entry -> EntryRecord in
            guard let plantID = entry.plant?.id else { throw JournalArchiveError.invalidRecord }
            return EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData, milestoneRaw: entry.milestoneRaw, changeKindRaw: entry.changeKindRaw)
        }
        let taskRecords = try careTasks.map { task -> CareTaskRecord in
            guard let plantID = task.plant?.id else { throw JournalArchiveError.invalidRecord }
            return CareTaskRecord(
                id: task.id,
                plantID: plantID,
                kindRaw: task.kindRaw,
                customTitle: task.customTitle,
                intervalDays: task.intervalDays,
                dueDate: task.dueDate,
                isEnabled: task.isEnabled,
                reminderEnabled: task.reminderEnabled
            )
        }
        let eventRecords = try careEvents.map { event -> CareEventRecord in
            guard let plantID = event.plant?.id else { throw JournalArchiveError.invalidRecord }
            return CareEventRecord(
                id: event.id,
                plantID: plantID,
                taskID: event.taskID,
                taskTitle: event.taskTitle,
                completedAt: event.completedAt,
                note: event.note
            )
        }
        let plantRecords = plants.map {
            PlantRecord(
                id: $0.id, name: $0.name, species: $0.species, notes: $0.notes,
                createdAt: $0.createdAt, photoData: $0.photoData,
                growingEnvironmentRaw: $0.growingEnvironmentRaw,
                lightConditionRaw: $0.lightConditionRaw,
                archivedAt: $0.archivedAt
            )
        }
        let tagRecords = tags.map { tag in
            TagRecord(id: tag.id, name: tag.name, normalizedName: tag.normalizedName,
                      plantIDs: (tag.plants ?? []).map(\.id).sorted { $0.uuidString < $1.uuidString })
        }
        let quietPeriodRecords = try quietPeriods.map { period -> QuietPeriodRecord in
            guard let plantID = period.plant?.id else { throw JournalArchiveError.invalidRecord }
            return QuietPeriodRecord(
                id: period.id, plantID: plantID, createdAt: period.createdAt,
                startAt: period.startAt, endAt: period.endAt, statusRaw: period.statusRaw,
                reason: period.reason, activatedAt: period.activatedAt, endedAt: period.endedAt
            )
        }
        let snapshotRecords = try quietPeriodTaskSnapshots.map { snapshot -> QuietPeriodTaskSnapshotRecord in
            guard let periodID = snapshot.quietPeriod?.id else { throw JournalArchiveError.invalidRecord }
            return QuietPeriodTaskSnapshotRecord(
                id: snapshot.id, quietPeriodID: periodID, taskID: snapshot.taskID,
                taskTitleSnapshot: snapshot.taskTitleSnapshot, membershipStatusRaw: snapshot.membershipStatusRaw,
                remainingCalendarDays: snapshot.remainingCalendarDays,
                originalDueHour: snapshot.originalDueHour, originalDueMinute: snapshot.originalDueMinute,
                originalDueSecond: snapshot.originalDueSecond, frozenIntervalDays: snapshot.frozenIntervalDays,
                nextCareOverrideAt: snapshot.nextCareOverrideAt, capturedAt: snapshot.capturedAt, updatedAt: snapshot.updatedAt
            )
        }
        let archive = JournalArchive(
            plants: plantRecords,
            entries: entryRecords,
            careTasks: taskRecords,
            careEvents: eventRecords,
            tags: tagRecords,
            quietPeriods: quietPeriodRecords,
            quietPeriodTaskSnapshots: snapshotRecords
        )
        try archive.validate()
        let data = try JSONEncoder().encode(archive)
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        return data
    }

    func validate() throws {
        guard (1...3).contains(version) else { throw JournalArchiveError.unsupportedVersion }
        guard plants.count <= Self.maxRecords,
              entries.count <= Self.maxRecords,
              (careTasks?.count ?? 0) <= Self.maxRecords,
              (careEvents?.count ?? 0) <= Self.maxRecords,
              (tags?.count ?? 0) <= Self.maxRecords,
              (quietPeriods?.count ?? 0) <= Self.maxRecords,
              (quietPeriodTaskSnapshots?.count ?? 0) <= Self.maxRecords else {
            throw JournalArchiveError.tooLarge
        }
        let plantIDs = Set(plants.map(\.id))
        let periodRecords = quietPeriods ?? []
        let snapshotRecords = quietPeriodTaskSnapshots ?? []
        let periodIDs = Set(periodRecords.map(\.id))
        guard plantIDs.count == plants.count,
              Set(entries.map(\.id)).count == entries.count,
              Set((careTasks ?? []).map(\.id)).count == (careTasks ?? []).count,
              Set((careEvents ?? []).map(\.id)).count == (careEvents ?? []).count,
              periodIDs.count == periodRecords.count,
              Set(snapshotRecords.map(\.id)).count == snapshotRecords.count,
              plants.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw JournalArchiveError.invalidRecord
        }

        for plant in plants {
            if version == 1, plant.archivedAt != nil { throw JournalArchiveError.invalidRecord }
            if let data = plant.photoData, UIImage(data: data) == nil {
                throw JournalArchiveError.invalidRecord
            }
            if let raw = plant.growingEnvironmentRaw, GrowingEnvironment(rawValue: raw) == nil {
                throw JournalArchiveError.invalidRecord
            }
            if let raw = plant.lightConditionRaw, LightCondition(rawValue: raw) == nil {
                throw JournalArchiveError.invalidRecord
            }
        }
        for entry in entries {
            if version == 1, entry.milestoneRaw != nil { throw JournalArchiveError.invalidRecord }
            if version == 1, entry.changeKindRaw != nil { throw JournalArchiveError.invalidRecord }
            if let raw = entry.milestoneRaw, JournalMilestone(rawValue: raw) == nil { throw JournalArchiveError.invalidRecord }
            if let raw = entry.changeKindRaw, PlantChangeKind(rawValue: raw) == nil { throw JournalArchiveError.invalidRecord }
            // A record is one kind: milestone observation or plant change, never both. A custom change needs its note.
            if entry.milestoneRaw != nil, entry.changeKindRaw != nil { throw JournalArchiveError.invalidRecord }
            if entry.changeKindRaw == PlantChangeKind.custom.rawValue, entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                throw JournalArchiveError.invalidRecord
            }
            guard plantIDs.contains(entry.plantID),
                  !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.photoData != nil || entry.milestoneRaw != nil || entry.changeKindRaw != nil else {
                throw JournalArchiveError.invalidRecord
            }
            if let data = entry.photoData, UIImage(data: data) == nil {
                throw JournalArchiveError.invalidRecord
            }
        }
        for tag in tags ?? [] {
            let normalized = PlantTag.normalized(tag.name)
            guard normalized.isEmpty == false,
                  tag.normalizedName == normalized,
                  Set(tag.plantIDs).count == tag.plantIDs.count,
                  tag.plantIDs.allSatisfy(plantIDs.contains) else {
                throw JournalArchiveError.invalidRecord
            }
        }
        // Tag identity is stable: one record per id and per normalized name.
        let tagIDs = (tags ?? []).map(\.id)
        let tagNames = (tags ?? []).map(\.normalizedName)
        guard Set(tagIDs).count == tagIDs.count, Set(tagNames).count == tagNames.count else {
            throw JournalArchiveError.invalidRecord
        }
        for task in careTasks ?? [] {
            guard plantIDs.contains(task.plantID),
                  CareKind(rawValue: task.kindRaw) != nil,
                  task.intervalDays >= 1,
                  task.kindRaw != CareKind.custom.rawValue || !task.customTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw JournalArchiveError.invalidRecord
            }
        }
        for event in careEvents ?? [] {
            guard plantIDs.contains(event.plantID),
                  !event.taskTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                throw JournalArchiveError.invalidRecord
            }
        }
        if version < 3, !periodRecords.isEmpty || !snapshotRecords.isEmpty {
            throw JournalArchiveError.invalidRecord
        }
        let periodByID = Dictionary(uniqueKeysWithValues: periodRecords.map { ($0.id, $0) })
        for period in periodRecords {
            guard plantIDs.contains(period.plantID),
                  QuietPeriodStatus(rawValue: period.statusRaw) != nil,
                  period.endAt == nil || period.endAt! > period.startAt,
                  period.endedAt == nil || period.activatedAt != nil else {
                throw JournalArchiveError.invalidRecord
            }
        }
        let tasksByID = Dictionary((careTasks ?? []).map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for snapshot in snapshotRecords {
            guard periodIDs.contains(snapshot.quietPeriodID),
                  QuietPeriodMembershipStatus(rawValue: snapshot.membershipStatusRaw) != nil,
                  !snapshot.taskTitleSnapshot.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  snapshot.frozenIntervalDays == nil || snapshot.frozenIntervalDays! >= 1,
                  snapshot.originalDueHour.map({ (0...23).contains($0) }) ?? true,
                  snapshot.originalDueMinute.map({ (0...59).contains($0) }) ?? true,
                  snapshot.originalDueSecond.map({ (0...59).contains($0) }) ?? true else {
                throw JournalArchiveError.invalidRecord
            }
            if snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue,
               let period = periodByID[snapshot.quietPeriodID],
               period.statusRaw == QuietPeriodStatus.active.rawValue {
                guard let task = tasksByID[snapshot.taskID], task.plantID == period.plantID, task.isEnabled else {
                    throw JournalArchiveError.invalidRecord
                }
            }
        }
        for period in periodRecords where period.statusRaw == QuietPeriodStatus.active.rawValue {
            let active = snapshotRecords.filter { $0.quietPeriodID == period.id && $0.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue }
            guard !active.isEmpty else { throw JournalArchiveError.invalidRecord }
            guard Set(active.map(\.taskID)).count == active.count else { throw JournalArchiveError.invalidRecord }
        }
    }

    @MainActor
    static func preview(_ data: Data, context: ModelContext) throws -> JournalArchivePreview {
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        guard !context.hasChanges else { throw JournalArchiveError.unsavedChanges }
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        try archive.validate()

        let previewContext = ModelContext(context.container)
        let plantIDs = Set(try previewContext.fetch(FetchDescriptor<Plant>()).map(\.id))
        let entryIDs = Set(try previewContext.fetch(FetchDescriptor<JournalEntry>()).map(\.id))
        let taskIDs = Set(try previewContext.fetch(FetchDescriptor<CareTask>()).map(\.id))
        let eventIDs = Set(try previewContext.fetch(FetchDescriptor<CareEvent>()).map(\.id))
        let quietPeriodIDs = Set(try previewContext.fetch(FetchDescriptor<QuietPeriod>()).map(\.id))
        let quietPeriodSnapshotIDs = Set(try previewContext.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>()).map(\.id))
        let tasks = archive.careTasks ?? []
        let events = archive.careEvents ?? []

        return JournalArchivePreview(
            version: archive.version,
            plantsToAdd: archive.plants.filter { !plantIDs.contains($0.id) }.count,
            plantsAlreadyPresent: archive.plants.filter { plantIDs.contains($0.id) }.count,
            entriesToAdd: archive.entries.filter { !entryIDs.contains($0.id) }.count,
            entriesAlreadyPresent: archive.entries.filter { entryIDs.contains($0.id) }.count,
            careTasksToAdd: tasks.filter { !taskIDs.contains($0.id) }.count,
            careTasksAlreadyPresent: tasks.filter { taskIDs.contains($0.id) }.count,
            careEventsToAdd: events.filter { !eventIDs.contains($0.id) }.count,
            careEventsAlreadyPresent: events.filter { eventIDs.contains($0.id) }.count,
            quietPeriodsToAdd: (archive.quietPeriods ?? []).filter { !quietPeriodIDs.contains($0.id) }.count,
            quietPeriodsAlreadyPresent: (archive.quietPeriods ?? []).filter { quietPeriodIDs.contains($0.id) }.count,
            quietPeriodSnapshotsToAdd: (archive.quietPeriodTaskSnapshots ?? []).filter { !quietPeriodSnapshotIDs.contains($0.id) }.count,
            quietPeriodSnapshotsAlreadyPresent: (archive.quietPeriodTaskSnapshots ?? []).filter { quietPeriodSnapshotIDs.contains($0.id) }.count
        )
    }

    /// Additive and idempotent. All archive and conflict checks happen before the
    /// model context is changed; existing user-authored records are never overwritten.
    @MainActor
    static func recover(
        _ data: Data,
        context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws -> Int {
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        guard !context.hasChanges else { throw JournalArchiveError.unsavedChanges }
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        try archive.validate()

        // Isolate writes so a failed import cannot roll back unrelated unsaved UI edits.
        let recoveryContext = ModelContext(context.container)
        let existingPlants = try recoveryContext.fetch(FetchDescriptor<Plant>())
        let existingEntries = try recoveryContext.fetch(FetchDescriptor<JournalEntry>())
        let existingTasks = try recoveryContext.fetch(FetchDescriptor<CareTask>())
        let existingEvents = try recoveryContext.fetch(FetchDescriptor<CareEvent>())
        let existingQuietPeriods = try recoveryContext.fetch(FetchDescriptor<QuietPeriod>())
        let existingSnapshots = try recoveryContext.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>())

        let existingTags = try recoveryContext.fetch(FetchDescriptor<PlantTag>())
        var plants = Dictionary(uniqueKeysWithValues: existingPlants.map { ($0.id, $0) })
        let entries = Dictionary(uniqueKeysWithValues: existingEntries.map { ($0.id, $0) })
        let tasks = Dictionary(uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })
        let events = Dictionary(uniqueKeysWithValues: existingEvents.map { ($0.id, $0) })
        var tags = Dictionary(uniqueKeysWithValues: existingTags.map { ($0.id, $0) })
        let quietPeriods = Dictionary(uniqueKeysWithValues: existingQuietPeriods.map { ($0.id, $0) })
        let quietSnapshots = Dictionary(uniqueKeysWithValues: existingSnapshots.map { ($0.id, $0) })

        // Complete conflict validation before touching the context.
        for record in archive.entries {
            if let entry = entries[record.id] {
                guard let plantID = entry.plant?.id,
                      EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData, milestoneRaw: entry.milestoneRaw, changeKindRaw: entry.changeKindRaw) == record else {
                    throw JournalArchiveError.conflictingRecord
                }
            }
        }
        for record in archive.tags ?? [] {
            if let tag = tags[record.id] {
                guard TagRecord(id: tag.id, name: tag.name, normalizedName: tag.normalizedName,
                                plantIDs: (tag.plants ?? []).map(\.id).sorted { $0.uuidString < $1.uuidString }) == record else {
                    throw JournalArchiveError.conflictingRecord
                }
            }
        }
        for record in archive.careTasks ?? [] {
            if let task = tasks[record.id] {
                guard let plantID = task.plant?.id,
                      CareTaskRecord(
                        id: task.id, plantID: plantID, kindRaw: task.kindRaw, customTitle: task.customTitle,
                        intervalDays: task.intervalDays, dueDate: task.dueDate, isEnabled: task.isEnabled,
                        reminderEnabled: task.reminderEnabled
                      ) == record else {
                    throw JournalArchiveError.conflictingRecord
                }
            }
        }
        for record in archive.careEvents ?? [] {
            if let event = events[record.id] {
                guard let plantID = event.plant?.id,
                      CareEventRecord(
                        id: event.id, plantID: plantID, taskID: event.taskID, taskTitle: event.taskTitle,
                        completedAt: event.completedAt, note: event.note
                      ) == record else {
                    throw JournalArchiveError.conflictingRecord
                }
            }
        }
        for record in archive.quietPeriods ?? [] {
            if let period = quietPeriods[record.id] {
                guard let plantID = period.plant?.id,
                      QuietPeriodRecord(
                        id: period.id, plantID: plantID, createdAt: period.createdAt,
                        startAt: period.startAt, endAt: period.endAt, statusRaw: period.statusRaw,
                        reason: period.reason, activatedAt: period.activatedAt, endedAt: period.endedAt
                      ) == record else {
                    throw JournalArchiveError.conflictingRecord
                }
            }
        }
        for record in archive.quietPeriodTaskSnapshots ?? [] {
            if let snapshot = quietSnapshots[record.id] {
                guard let periodID = snapshot.quietPeriod?.id,
                      QuietPeriodTaskSnapshotRecord(
                        id: snapshot.id, quietPeriodID: periodID, taskID: snapshot.taskID,
                        taskTitleSnapshot: snapshot.taskTitleSnapshot, membershipStatusRaw: snapshot.membershipStatusRaw,
                        remainingCalendarDays: snapshot.remainingCalendarDays,
                        originalDueHour: snapshot.originalDueHour, originalDueMinute: snapshot.originalDueMinute,
                        originalDueSecond: snapshot.originalDueSecond, frozenIntervalDays: snapshot.frozenIntervalDays,
                        nextCareOverrideAt: snapshot.nextCareOverrideAt, capturedAt: snapshot.capturedAt, updatedAt: snapshot.updatedAt
                      ) == record else {
                    throw JournalArchiveError.conflictingRecord
                }
            }
        }

        var restoredEntries = 0
        do {
            for record in archive.plants where plants[record.id] == nil {
                let plant = Plant(
                    id: record.id, name: record.name, species: record.species, notes: record.notes,
                    growingEnvironment: GrowingEnvironment(rawValue: record.growingEnvironmentRaw ?? "") ?? .unspecified,
                    lightCondition: LightCondition(rawValue: record.lightConditionRaw ?? "") ?? .unspecified,
                    photoData: record.photoData,
                    createdAt: record.createdAt,
                    archivedAt: record.archivedAt
                )
                recoveryContext.insert(plant)
                plants[plant.id] = plant
            }
            for record in archive.tags ?? [] where tags[record.id] == nil {
                // The app's own duplicate policy applies on recovery: a local tag
                // with the same normalized name stands in for the archived one.
                if let existing = tags.values.first(where: { $0.normalizedName == record.normalizedName }) {
                    tags[record.id] = existing
                    continue
                }
                let tag = PlantTag(id: record.id, name: record.name)
                guard tag.normalizedName == record.normalizedName else { throw JournalArchiveError.invalidRecord }
                recoveryContext.insert(tag)
                tags[tag.id] = tag
            }
            // Assignments restore after every plant and tag exists, so archived and
            // restored plants keep their exact tag relationships.
            for record in archive.tags ?? [] {
                guard let tag = tags[record.id] else { throw JournalArchiveError.invalidRecord }
                for plantID in record.plantIDs {
                    guard let plant = plants[plantID] else { throw JournalArchiveError.invalidRecord }
                    if (tag.plants ?? []).contains(where: { $0.id == plantID }) == false {
                        tag.plants?.append(plant)
                    }
                }
            }
            for record in archive.entries where entries[record.id] == nil {
                guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
                recoveryContext.insert(JournalEntry(id: record.id, date: record.date, note: record.note, photoData: record.photoData, milestoneRaw: record.milestoneRaw, changeKindRaw: record.changeKindRaw, plant: plant))
                restoredEntries += 1
            }
            for record in archive.careTasks ?? [] where tasks[record.id] == nil {
                guard let plant = plants[record.plantID],
                      let kind = CareKind(rawValue: record.kindRaw) else {
                    throw JournalArchiveError.invalidRecord
                }
                let task = CareTask(
                    id: record.id,
                    kind: kind,
                    customTitle: record.customTitle,
                    intervalDays: record.intervalDays,
                    dueDate: record.dueDate,
                    isEnabled: record.isEnabled,
                    reminderEnabled: record.reminderEnabled,
                    plant: plant
                )
                recoveryContext.insert(task)
            }
            for record in archive.careEvents ?? [] where events[record.id] == nil {
                guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
                recoveryContext.insert(CareEvent(
                    id: record.id,
                    taskID: record.taskID,
                    taskTitle: record.taskTitle,
                    completedAt: record.completedAt,
                    note: record.note,
                    plant: plant
                ))
            }
            for record in archive.quietPeriods ?? [] where quietPeriods[record.id] == nil {
                guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
                let period = QuietPeriod(
                    id: record.id, createdAt: record.createdAt, startAt: record.startAt,
                    endAt: record.endAt, statusRaw: record.statusRaw, reason: record.reason,
                    activatedAt: record.activatedAt, endedAt: record.endedAt, plant: plant
                )
                recoveryContext.insert(period)
            }
            let periodLookup = Dictionary(uniqueKeysWithValues:
                (try recoveryContext.fetch(FetchDescriptor<QuietPeriod>())).map { ($0.id, $0) }
            )
            for record in archive.quietPeriodTaskSnapshots ?? [] where quietSnapshots[record.id] == nil {
                guard let period = periodLookup[record.quietPeriodID] else { throw JournalArchiveError.invalidRecord }
                let snapshot = QuietPeriodTaskSnapshot(
                    id: record.id, taskID: record.taskID, taskTitleSnapshot: record.taskTitleSnapshot,
                    membershipStatusRaw: record.membershipStatusRaw,
                    remainingCalendarDays: record.remainingCalendarDays,
                    originalDueHour: record.originalDueHour, originalDueMinute: record.originalDueMinute,
                    originalDueSecond: record.originalDueSecond, frozenIntervalDays: record.frozenIntervalDays,
                    nextCareOverrideAt: record.nextCareOverrideAt, capturedAt: record.capturedAt,
                    updatedAt: record.updatedAt, quietPeriod: period
                )
                recoveryContext.insert(snapshot)
            }
            try save(recoveryContext)
        } catch {
            recoveryContext.rollback()
            throw error
        }
        return restoredEntries
    }
}

struct JournalArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
