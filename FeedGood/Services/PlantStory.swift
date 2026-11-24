import Foundation

/// A projection of existing source records, never a second history store.
enum PlantStoryItem: Identifiable {
    case care(CareEvent)
    case journal(JournalEntry)
    case quietPeriod(QuietPeriodTaskSnapshot)

    var id: String {
        switch self {
        case .care(let event): return "care.\(event.id.uuidString)"
        case .journal(let entry): return "journal.\(entry.id.uuidString)"
        case .quietPeriod(let snapshot): return "quiet-period.\(snapshot.id.uuidString)"
        }
    }
    var date: Date {
        switch self {
        case .care(let event): return event.completedAt
        case .journal(let entry): return entry.date
        case .quietPeriod(let snapshot):
            if snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue,
               let endedAt = snapshot.quietPeriod?.endedAt {
                return endedAt
            }
            return snapshot.updatedAt
        }
    }
}

enum PlantStory {
    /// Most recent first; namespaced stable IDs break equal-date ties reproducibly.
    static func items(
        plantID: UUID,
        careEvents: [CareEvent],
        journalEntries: [JournalEntry],
        quietPeriodSnapshots: [QuietPeriodTaskSnapshot] = []
    ) -> [PlantStoryItem] {
        let care = careEvents.filter { $0.plant?.id == plantID }.map(PlantStoryItem.care)
        let journal = journalEntries.filter { $0.plant?.id == plantID }.map(PlantStoryItem.journal)
        let quietPeriods = quietPeriodSnapshots.filter { $0.quietPeriod?.plant?.id == plantID }.map(PlantStoryItem.quietPeriod)
        return (care + journal + quietPeriods).sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.id < $1.id
        }
    }
}
