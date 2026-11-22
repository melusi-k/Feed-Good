import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum JournalArchiveError: LocalizedError {
    case invalidRecord, unsupportedVersion, tooLarge, conflictingRecord
    var errorDescription: String? {
        switch self {
        case .invalidRecord: return "This archive has an invalid record, plant reference or photo. Nothing was imported."
        case .unsupportedVersion: return "This archive version isn't supported. Nothing was imported."
        case .tooLarge: return "This archive exceeds the 25 MB or 1,000-record safety limit. Nothing was imported."
        case .conflictingRecord: return "A record has the same ID but different content. Nothing was imported; existing records are unchanged."
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

    var confirmationMessage: String {
        """
        Archive version \(version)
        Plants: \(plantsToAdd) to add, \(plantsAlreadyPresent) already present
        Journal entries: \(entriesToAdd) to add, \(entriesAlreadyPresent) already present
        Care routines: \(careTasksToAdd) to add, \(careTasksAlreadyPresent) already present
        Care history: \(careEventsToAdd) to add, \(careEventsAlreadyPresent) already present

        Existing plant records are preserved. Existing journal and care records are checked for identical content; any conflict stops recovery before changes are saved.
        """
    }
}

/// Version 1 is journal-only. Version 2 covers milestones plus the complete local garden record; care routines and history are optional extension keys.
struct JournalArchive: Codable {
    var version = 2
    var plants: [PlantRecord]
    var entries: [EntryRecord]
    var careTasks: [CareTaskRecord]?
    var careEvents: [CareEventRecord]?

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
    }

    struct EntryRecord: Codable, Equatable {
        var id: UUID
        var plantID: UUID
        var date: Date
        var note: String
        var photoData: Data?
        var milestoneRaw: String? = nil
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

    static let maxBytes = 25 * 1024 * 1024
    static let maxRecords = 1000

    @MainActor
    static func export(
        plants: [Plant],
        entries: [JournalEntry],
        careTasks: [CareTask] = [],
        careEvents: [CareEvent] = []
    ) throws -> Data {
        let entryRecords = try entries.map { entry -> EntryRecord in
            guard let plantID = entry.plant?.id else { throw JournalArchiveError.invalidRecord }
            return EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData, milestoneRaw: entry.milestoneRaw)
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
                lightConditionRaw: $0.lightConditionRaw
            )
        }
        let archive = JournalArchive(
            plants: plantRecords,
            entries: entryRecords,
            careTasks: taskRecords,
            careEvents: eventRecords
        )
        try archive.validate()
        let data = try JSONEncoder().encode(archive)
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        return data
    }

    func validate() throws {
        guard version == 1 || version == 2 else { throw JournalArchiveError.unsupportedVersion }
        guard plants.count <= Self.maxRecords,
              entries.count <= Self.maxRecords,
              (careTasks?.count ?? 0) <= Self.maxRecords,
              (careEvents?.count ?? 0) <= Self.maxRecords else {
            throw JournalArchiveError.tooLarge
        }
        let plantIDs = Set(plants.map(\.id))
        guard plantIDs.count == plants.count,
              Set(entries.map(\.id)).count == entries.count,
              Set((careTasks ?? []).map(\.id)).count == (careTasks ?? []).count,
              Set((careEvents ?? []).map(\.id)).count == (careEvents ?? []).count,
              plants.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else {
            throw JournalArchiveError.invalidRecord
        }

        for plant in plants {
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
            if let raw = entry.milestoneRaw, JournalMilestone(rawValue: raw) == nil { throw JournalArchiveError.invalidRecord }
            guard plantIDs.contains(entry.plantID),
                  !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.photoData != nil || entry.milestoneRaw != nil else {
                throw JournalArchiveError.invalidRecord
            }
            if let data = entry.photoData, UIImage(data: data) == nil {
                throw JournalArchiveError.invalidRecord
            }
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
    }

    @MainActor
    static func preview(_ data: Data, context: ModelContext) throws -> JournalArchivePreview {
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        try archive.validate()

        let plantIDs = Set(try context.fetch(FetchDescriptor<Plant>()).map(\.id))
        let entryIDs = Set(try context.fetch(FetchDescriptor<JournalEntry>()).map(\.id))
        let taskIDs = Set(try context.fetch(FetchDescriptor<CareTask>()).map(\.id))
        let eventIDs = Set(try context.fetch(FetchDescriptor<CareEvent>()).map(\.id))
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
            careEventsAlreadyPresent: events.filter { eventIDs.contains($0.id) }.count
        )
    }

    /// Additive and idempotent. All archive and conflict checks happen before the
    /// model context is changed; existing user-authored records are never overwritten.
    @MainActor
    static func recover(_ data: Data, context: ModelContext) throws -> Int {
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        try archive.validate()

        // Isolate writes so a failed import cannot roll back unrelated unsaved UI edits.
        let recoveryContext = ModelContext(context.container)
        let existingPlants = try recoveryContext.fetch(FetchDescriptor<Plant>())
        let existingEntries = try recoveryContext.fetch(FetchDescriptor<JournalEntry>())
        let existingTasks = try recoveryContext.fetch(FetchDescriptor<CareTask>())
        let existingEvents = try recoveryContext.fetch(FetchDescriptor<CareEvent>())

        var plants = Dictionary(uniqueKeysWithValues: existingPlants.map { ($0.id, $0) })
        let entries = Dictionary(uniqueKeysWithValues: existingEntries.map { ($0.id, $0) })
        let tasks = Dictionary(uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })
        let events = Dictionary(uniqueKeysWithValues: existingEvents.map { ($0.id, $0) })

        // Complete conflict validation before touching the context.
        for record in archive.entries {
            if let entry = entries[record.id] {
                guard let plantID = entry.plant?.id,
                      EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData, milestoneRaw: entry.milestoneRaw) == record else {
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

        var restoredEntries = 0
        do {
            for record in archive.plants where plants[record.id] == nil {
                let plant = Plant(
                    id: record.id, name: record.name, species: record.species, notes: record.notes,
                    photoData: record.photoData,
                    createdAt: record.createdAt,
                    growingEnvironment: GrowingEnvironment(rawValue: record.growingEnvironmentRaw ?? "") ?? .unspecified,
                    lightCondition: LightCondition(rawValue: record.lightConditionRaw ?? "") ?? .unspecified
                )
                recoveryContext.insert(plant)
                plants[plant.id] = plant
            }
            for record in archive.entries where entries[record.id] == nil {
                guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
                recoveryContext.insert(JournalEntry(id: record.id, date: record.date, note: record.note, photoData: record.photoData, milestoneRaw: record.milestoneRaw, plant: plant))
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
            try recoveryContext.save()
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
