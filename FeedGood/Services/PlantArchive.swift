import Foundation
import SwiftData

/// Transactional reversible archive for a plant. Archive is a persisted collection
/// state, never deletion: the plant and every task, event, journal entry, photo and
/// milestone stay exactly as they were.
enum PlantArchive {
    /// Marks the plant archived at `date`. Idempotent: archiving an already-archived
    /// plant keeps its original archive date. On a failed save the context rolls back
    /// and the plant stays active.
    static func archive(_ plant: Plant, at date: Date = .now, in context: ModelContext) throws {
        guard plant.archivedAt == nil else { return }
        plant.archivedAt = date
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Returns the same plant identity and records to the active collection.
    /// Idempotent: restoring an active plant is a no-op. On a failed save the
    /// context rolls back and the plant stays archived.
    static func restore(_ plant: Plant, in context: ModelContext) throws {
        guard plant.archivedAt != nil else { return }
        plant.archivedAt = nil
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    static func isArchived(_ plant: Plant) -> Bool { plant.archivedAt != nil }
}
