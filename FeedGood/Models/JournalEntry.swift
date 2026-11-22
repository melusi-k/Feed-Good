import Foundation
import SwiftData

enum JournalMilestone: String, CaseIterable, Identifiable {
    case newLeaf, flowering, repotting, recovery
    var id: String { rawValue }
    var title: String {
        switch self {
        case .newLeaf: return "New leaf"
        case .flowering: return "Flowering"
        case .repotting: return "Repotting"
        case .recovery: return "Recovery"
        }
    }
}

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var date: Date = Date.now
    var note: String = ""
    @Attribute(.externalStorage) var photoData: Data?
    var milestoneRaw: String? = nil
    var milestone: JournalMilestone? { milestoneRaw.flatMap(JournalMilestone.init(rawValue:)) }
    var plant: Plant?

    init(id: UUID = UUID(), date: Date = .now, note: String, photoData: Data? = nil, milestoneRaw: String? = nil, plant: Plant) {
        self.id = id; self.date = date
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoData = photoData; self.milestoneRaw = milestoneRaw; self.plant = plant
    }
}

struct JournalDraft {
    var date = Date.now
    var note = ""
    var photoData: Data?
    var milestone: JournalMilestone? = nil
    var isValid: Bool { milestone != nil || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil }
}

@MainActor
enum JournalStore {
    static func save(_ draft: JournalDraft, plant: Plant, entry: JournalEntry?, context: ModelContext) throws {
        guard draft.isValid else { throw JournalArchiveError.invalidRecord }
        let record = entry ?? JournalEntry(note: draft.note, plant: plant)
        if entry == nil { context.insert(record) }
        record.plant = plant
        record.date = draft.date; record.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        record.photoData = draft.photoData
        record.milestoneRaw = draft.milestone?.rawValue
        do { try context.save() }
        catch { context.rollback(); throw error }
    }

    static func delete(_ entry: JournalEntry, context: ModelContext) throws {
        context.delete(entry)
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
