import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var date: Date = Date.now
    var note: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    var plant: Plant?

    init(id: UUID = UUID(), date: Date = .now, note: String, photoData: Data? = nil, plant: Plant) {
        self.id = id; self.date = date
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoData = photoData; self.plant = plant
    }
}

struct JournalDraft {
    var date = Date.now
    var note = ""
    var photoData: Data?
    var isValid: Bool { !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil }
}

@MainActor
enum JournalStore {
    static func save(_ draft: JournalDraft, plant: Plant, entry: JournalEntry?, context: ModelContext) throws {
        guard draft.isValid else { throw JournalArchiveError.invalidRecord }
        let record = entry ?? JournalEntry(note: draft.note, plant: plant)
        if entry == nil { context.insert(record) }
        record.date = draft.date; record.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        record.photoData = draft.photoData
        do { try context.save() }
        catch { context.rollback(); throw error }
    }

    static func delete(_ entry: JournalEntry, context: ModelContext) throws {
        context.delete(entry)
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
