import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers
import UIKit

enum JournalArchiveError: LocalizedError {
    case invalidRecord, unsupportedVersion, tooLarge, conflictingEntry
    var errorDescription: String? {
        switch self {
        case .invalidRecord: return "This archive has an invalid entry, plant reference or photo. Nothing was imported."
        case .unsupportedVersion: return "This archive version isn't supported. Nothing was imported."
        case .tooLarge: return "This archive exceeds the 25 MB or 1,000-entry safety limit. Nothing was imported."
        case .conflictingEntry: return "An entry has the same ID but different content. Nothing was imported; existing entries are unchanged."
        }
    }
}

struct JournalArchive: Codable {
    var version = 2
    var plants: [PlantRecord]
    var entries: [EntryRecord]
    struct PlantRecord: Codable {
        var id: UUID; var name: String; var species: String; var notes: String; var createdAt: Date
    }
    struct EntryRecord: Codable, Equatable {
        var id: UUID; var plantID: UUID; var date: Date; var note: String; var photoData: Data?
        var milestoneRaw: String? = nil
    }
    static let maxBytes = 25 * 1024 * 1024

    @MainActor
    static func export(plants: [Plant], entries: [JournalEntry]) throws -> Data {
        let records = try entries.map { entry -> EntryRecord in
            guard let plantID = entry.plant?.id else { throw JournalArchiveError.invalidRecord }
            return EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData, milestoneRaw: entry.milestoneRaw)
        }
        let archive = JournalArchive(plants: plants.map { PlantRecord(id: $0.id, name: $0.name, species: $0.species, notes: $0.notes, createdAt: $0.createdAt) }, entries: records)
        try archive.validate()
        let data = try JSONEncoder().encode(archive)
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        return data
    }

    func validate() throws {
        guard version == 1 || version == 2 else { throw JournalArchiveError.unsupportedVersion }
        guard entries.count <= 1000, plants.count <= 1000 else { throw JournalArchiveError.tooLarge }
        let plantIDs = Set(plants.map(\.id))
        guard plantIDs.count == plants.count, Set(entries.map(\.id)).count == entries.count,
              plants.allSatisfy({ !$0.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) else { throw JournalArchiveError.invalidRecord }
        for entry in entries {
            if version == 1, entry.milestoneRaw != nil { throw JournalArchiveError.invalidRecord }
            if let raw = entry.milestoneRaw, JournalMilestone(rawValue: raw) == nil { throw JournalArchiveError.invalidRecord }
            guard plantIDs.contains(entry.plantID), !entry.note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || entry.photoData != nil || entry.milestoneRaw != nil else { throw JournalArchiveError.invalidRecord }
            if let data = entry.photoData { guard UIImage(data: data) != nil else { throw JournalArchiveError.invalidRecord } }
        }
    }

    @MainActor
    static func recover(_ data: Data, context: ModelContext) throws -> Int {
        guard data.count <= maxBytes else { throw JournalArchiveError.tooLarge }
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        try archive.validate()
        let existingPlants = try context.fetch(FetchDescriptor<Plant>())
        let existingEntries = try context.fetch(FetchDescriptor<JournalEntry>())
        var plants = Dictionary(uniqueKeysWithValues: existingPlants.map { ($0.id, $0) })
        let entries = Dictionary(uniqueKeysWithValues: existingEntries.map { ($0.id, $0) })
        // Complete conflict validation before touching the context.
        for record in archive.entries {
            if let entry = entries[record.id] {
                guard let plantID = entry.plant?.id,
                      EntryRecord(id: entry.id, plantID: plantID, date: entry.date, note: entry.note, photoData: entry.photoData, milestoneRaw: entry.milestoneRaw) == record else { throw JournalArchiveError.conflictingEntry }
            }
        }
        var restored = 0
        for record in archive.plants where plants[record.id] == nil {
            let plant = Plant(id: record.id, name: record.name, species: record.species, notes: record.notes, createdAt: record.createdAt)
            context.insert(plant); plants[plant.id] = plant
        }
        for record in archive.entries where entries[record.id] == nil {
            guard let plant = plants[record.plantID] else { throw JournalArchiveError.invalidRecord }
            context.insert(JournalEntry(id: record.id, date: record.date, note: record.note, photoData: record.photoData, milestoneRaw: record.milestoneRaw, plant: plant))
            restored += 1
        }
        do { try context.save() }
        catch { context.rollback(); throw error }
        return restored
    }
}

struct JournalArchiveDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }
    var data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws { data = configuration.file.regularFileContents ?? Data() }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}
