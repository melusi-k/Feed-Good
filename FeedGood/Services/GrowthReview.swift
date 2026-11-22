import Foundation

/// A projection of existing `JournalEntry` photos for one plant's growth review.
/// Never a second history store: every call reads the current records, so edits
/// and deletions are reflected on the next render by construction.
enum GrowthReview {
    /// Photo-bearing journal entries for one plant, newest first.
    /// Equal dates fall back to the entry UUID so ordering is deterministic and
    /// independent of input order. Entries without photos and entries belonging
    /// to any other plant can never enter the review.
    static func entries(plantID: UUID, from journalEntries: [JournalEntry]) -> [JournalEntry] {
        journalEntries
            .filter { $0.plant?.id == plantID && $0.photoData != nil }
            .sorted {
                if $0.date != $1.date { return $0.date > $1.date }
                return $0.id.uuidString < $1.id.uuidString
            }
    }

    /// Orders two selected observations as earlier/later for comparison.
    /// Returns nil unless exactly two different entries from the same plant are
    /// selected, so a comparison can never be built from one photo, from
    /// nothing, or across plants.
    static func comparison(_ selected: [JournalEntry]) -> (earlier: JournalEntry, later: JournalEntry)? {
        guard selected.count == 2, selected[0].id != selected[1].id,
              let plantID = selected[0].plant?.id, selected[1].plant?.id == plantID else { return nil }
        let sorted = selected.sorted {
            if $0.date != $1.date { return $0.date < $1.date }
            return $0.id.uuidString < $1.id.uuidString
        }
        return (earlier: sorted[0], later: sorted[1])
    }
}
