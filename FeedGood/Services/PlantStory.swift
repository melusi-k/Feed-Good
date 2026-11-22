import Foundation

/// A projection of existing source records, never a second history store.
enum PlantStoryItem: Identifiable {
    case care(CareEvent)
    case journal(JournalEntry)

    var id: String {
        switch self {
        case .care(let event): return "care.\(event.id.uuidString)"
        case .journal(let entry): return "journal.\(entry.id.uuidString)"
        }
    }
    var date: Date {
        switch self {
        case .care(let event): return event.completedAt
        case .journal(let entry): return entry.date
        }
    }
}

enum PlantStory {
    /// Most recent first; namespaced stable IDs break equal-date ties reproducibly.
    static func items(plantID: UUID, careEvents: [CareEvent], journalEntries: [JournalEntry]) -> [PlantStoryItem] {
        let care = careEvents.filter { $0.plant?.id == plantID }.map(PlantStoryItem.care)
        let journal = journalEntries.filter { $0.plant?.id == plantID }.map(PlantStoryItem.journal)
        return (care + journal).sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.id < $1.id
        }
    }
}
