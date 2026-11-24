import Foundation
import SwiftData

/// Transactional reversible archive for a plant. Archive is a persisted collection
/// state, never deletion: the plant and every task, event, journal entry, photo and
/// milestone stay exactly as they were.
@MainActor
enum PlantArchive {
    /// Marks the plant archived at `date`. Idempotent: archiving an already-archived
    /// plant keeps its original archive date. A failed save restores only this
    /// property and leaves unrelated pending context edits untouched.
    static func archive(
        _ plant: Plant,
        at date: Date = .now,
        in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard plant.archivedAt == nil else { return }
        let periods = plant.quietPeriods ?? []
        let periodState = periods.map { ($0, $0.statusRaw, $0.endedAt) }
        let taskDueDates = (plant.careTasks ?? []).map { ($0, $0.dueDate) }
        do {
            for period in periods {
                try QuietPeriodLifecycle.endForArchive(
                    period,
                    at: date,
                    in: context,
                    save: { _ in }
                )
            }
            plant.archivedAt = date
            try save(context)
        } catch {
            plant.archivedAt = nil
            for (period, status, endedAt) in periodState {
                period.statusRaw = status
                period.endedAt = endedAt
            }
            for (task, dueDate) in taskDueDates { task.dueDate = dueDate }
            throw error
        }
    }

    /// Returns the same plant identity and records to the active collection.
    /// Idempotent: restoring an active plant is a no-op. A failed save restores
    /// the prior archive timestamp without rolling back unrelated pending edits.
    static func restore(
        _ plant: Plant,
        in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard plant.archivedAt != nil else { return }
        let previous = plant.archivedAt
        plant.archivedAt = nil
        do {
            try save(context)
        } catch {
            plant.archivedAt = previous
            throw error
        }
    }

    static func isArchived(_ plant: Plant) -> Bool { plant.archivedAt != nil }
}
