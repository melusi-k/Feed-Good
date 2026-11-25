import Foundation

/// A read-only snapshot of existing records, not a new identity or progress store.
struct GardenProfileSummary: Equatable {
    let plantCount: Int
    let careEventCount: Int
    let journalEntryCount: Int

    @MainActor
    init(plants: [Plant], careEvents: [CareEvent], journalEntries: [JournalEntry]) {
        let plantIDs = Set(plants.map(\.id))
        plantCount = plantIDs.count
        careEventCount = careEvents.filter { event in
            event.plant.map { plantIDs.contains($0.id) } ?? false
        }.count
        journalEntryCount = journalEntries.filter { entry in
            entry.plant.map { plantIDs.contains($0.id) } ?? false
        }.count
    }
}
