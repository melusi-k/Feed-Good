import Foundation

/// A small projection of Journal's existing records, not another store.
enum RecentJournal {
    static func entries(from entries: [JournalEntry], limit: Int = 3) -> [JournalEntry] {
        guard limit > 0 else { return [] }
        return Array(entries.filter { $0.plant != nil }.sorted {
            if $0.date != $1.date { return $0.date > $1.date }
            return $0.id.uuidString < $1.id.uuidString
        }.prefix(limit))
    }
}
