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

/// An explicit, user-recorded change in a plant's environment or care context (PRD-018).
/// A change record is a typed journal entry: it is never a care completion and never
/// generates a causal, diagnostic or health claim.
enum PlantChangeKind: String, CaseIterable, Identifiable {
    case movedLocation, repotted, potOrSoilChange, growLightStarted, growLightStopped, movedIndoorsOrOutdoors, custom
    var id: String { rawValue }
    var title: String {
        switch self {
        case .movedLocation: return "Moved location"
        case .repotted: return "Repotted"
        case .potOrSoilChange: return "Changed pot or soil"
        case .growLightStarted: return "Grow light started"
        case .growLightStopped: return "Grow light stopped"
        case .movedIndoorsOrOutdoors: return "Moved indoors or outdoors"
        case .custom: return "Custom change"
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
    var changeKindRaw: String? = nil
    var changeKind: PlantChangeKind? { changeKindRaw.flatMap(PlantChangeKind.init(rawValue:)) }
    var plant: Plant?

    init(id: UUID = UUID(), date: Date = .now, note: String, photoData: Data? = nil, milestoneRaw: String? = nil, changeKindRaw: String? = nil, plant: Plant) {
        self.id = id; self.date = date
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoData = photoData; self.milestoneRaw = milestoneRaw; self.changeKindRaw = changeKindRaw; self.plant = plant
    }
}

struct JournalDraft {
    var date = Date.now
    var note = ""
    var photoData: Data?
    var milestone: JournalMilestone? = nil
    var changeKind: PlantChangeKind? = nil
    var isValid: Bool {
        // A custom change needs its note: the kind alone carries no meaning.
        let hasChange = changeKind != nil && (changeKind != .custom || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        return milestone != nil || hasChange || !note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || photoData != nil
    }
}

@MainActor
enum JournalStore {
    static func save(_ draft: JournalDraft, plant: Plant, entry: JournalEntry?, context: ModelContext) throws {
        guard draft.isValid else { throw JournalArchiveError.invalidRecord }
        // A record is one kind: milestone observation or plant change, never both.
        guard !(draft.milestone != nil && draft.changeKind != nil) else { throw JournalArchiveError.invalidRecord }
        let record = entry ?? JournalEntry(note: draft.note, plant: plant)
        if entry == nil { context.insert(record) }
        record.date = draft.date; record.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        record.photoData = draft.photoData
        record.milestoneRaw = draft.milestone?.rawValue
        record.changeKindRaw = draft.changeKind?.rawValue
        do { try context.save() }
        catch { context.rollback(); throw error }
    }

    static func delete(_ entry: JournalEntry, context: ModelContext) throws {
        context.delete(entry)
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
