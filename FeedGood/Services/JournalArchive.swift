import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum JournalArchiveError: LocalizedError {
    case invalidRecord, unsupportedVersion, tooLarge, conflictingEntry
    var errorDescription: String? {
        switch self {
        case .invalidRecord: return "This archive has an invalid record, plant reference or photo. Nothing was imported."
        case .unsupportedVersion: return "This archive version isn't supported. Nothing was imported."
        case .tooLarge: return "This archive exceeds the 25 MB or 1,000-record safety limit. Nothing was imported."
        case .conflictingEntry: return "A record has the same ID but different content. Nothing was imported; existing records are unchanged."
        }
    }
}

/// Version 1 is journal-only. Version 2 includes the complete local garden record.
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
    }

    struct EntryRecord: Codable, Equatable {
        var id: UUID
        var plantID: UUID
        var date: Date
        var note: String
        var photoData: Data?
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
            return EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData)
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
            PlantRecord(id: $0.id, name: $0.name, species: $0.species, notes: $0.notes, createdAt: $0.createdAt, photoData: $0.photoData)
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
        if version == 2, careTasks == nil || careEvents == nil {
            throw JournalArchiveError.invalidRecord
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
        }
        for entry in entries {
            guard plantIDs.contains(entry.plantID),
                  !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.photoData != nil else {
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

    /// Additive and idempotent. All archive and conflict checks happen before the
    /// model context is changed; existing user-authored records are never overwritten.
    @MainActor
    static func recover(_ data: Data, context: ModelContext) throws -> Int {
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        try archive.validate()

        let existingPlants = try context.fetch(FetchDescriptor<Plant>())
        let existingEntries = try context.fetch(FetchDescriptor<JournalEntry>())
        let existingTasks = try context.fetch(FetchDescriptor<CareTask>())
        let existingEvents = try context.fetch(FetchDescriptor<CareEvent>())

        var plants = Dictionary(uniqueKeysWithValues: existingPlants.map { ($0.id, $0) })
        let entries = Dictionary(uniqueKeysWithValues: existingEntries.map { ($0.id, $0) })
        let tasks = Dictionary(uniqueKeysWithValues: existingTasks.map { ($0.id, $0) })
        let events = Dictionary(uniqueKeysWithValues: existingEvents.map { ($0.id, $0) })

        // Complete conflict validation before touching the context.
        for record in archive.entries {
            if let entry = entries[record.id] {
                guard let plantID = entry.plant?.id,
                      EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData) == record else {
                    throw JournalArchiveError.conflictingEntry
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
                    throw JournalArchiveError.conflictingEntry
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
                    throw JournalArchiveError.conflictingEntry
                }
            }
        }

        var restoredEntries = 0
        do {
            for record in archive.plants where plants[record.id] == nil {
                let plant = Plant(
                    id: record.id, name: record.name, species: record.species, notes: record.notes,
                    photoData: record.photoData, createdAt: record.createdAt
                )
                context.insert(plant)
                plants[plant.id] = plant
            }
            for record in archive.entries where entries[record.id] == nil {
                guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
                context.insert(JournalEntry(id: record.id, date: record.date, note: record.note, photoData: record.photoData, plant: plant))
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
                context.insert(task)
            }
            for record in archive.careEvents ?? [] where events[record.id] == nil {
                guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
                context.insert(CareEvent(
                    id: record.id,
                    taskID: record.taskID,
                    taskTitle: record.taskTitle,
                    completedAt: record.completedAt,
                    note: record.note,
                    plant: plant
                ))
            }
            try context.save()
        } catch {
            context.rollback()
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
