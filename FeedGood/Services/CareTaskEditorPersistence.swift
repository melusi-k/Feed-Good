import Foundation
import SwiftData

enum CareTaskEditorPersistenceError: Error, Equatable {
    case plantUnavailable
    case archivedPlant
    case taskUnavailable
    case taskBelongsToAnotherPlant
}

/// Saves routine edits in an isolated context so a failed editor save cannot
/// roll back unrelated pending work in the shared view context.
@MainActor
enum CareTaskEditorPersistence {
    @discardableResult
    static func save(
        plantID: UUID,
        taskID: UUID?,
        kind: CareKind,
        customTitle: String,
        intervalDays: Int,
        dueDate: Date,
        isEnabled: Bool,
        reminderEnabled: Bool,
        in container: ModelContainer,
        now: Date = .now,
        saveContext: (ModelContext) throws -> Void = { try $0.save() }
    ) throws -> [CareReminder] {
        let writeContext = ModelContext(container)
        let plantDescriptor = FetchDescriptor<Plant>(
            predicate: #Predicate { $0.id == plantID }
        )
        guard let plant = try writeContext.fetch(plantDescriptor).first else {
            throw CareTaskEditorPersistenceError.plantUnavailable
        }
        guard plant.archivedAt == nil else {
            throw CareTaskEditorPersistenceError.archivedPlant
        }

        let record: CareTask
        if let taskID {
            let taskDescriptor = FetchDescriptor<CareTask>(
                predicate: #Predicate { $0.id == taskID }
            )
            guard let existing = try writeContext.fetch(taskDescriptor).first else {
                throw CareTaskEditorPersistenceError.taskUnavailable
            }
            guard existing.plant?.id == plantID else {
                throw CareTaskEditorPersistenceError.taskBelongsToAnotherPlant
            }
            record = existing
        } else {
            record = CareTask(
                kind: kind,
                intervalDays: intervalDays,
                dueDate: dueDate,
                plant: plant
            )
            writeContext.insert(record)
        }

        record.kindRaw = kind.rawValue
        record.customTitle = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        record.intervalDays = max(1, intervalDays)
        record.dueDate = dueDate
        record.isEnabled = isEnabled
        record.reminderEnabled = reminderEnabled

        // Build the post-commit reminder projection before saving. The caller
        // receives it only if persistence succeeds, so failure cannot trigger
        // reminder reconciliation from an uncommitted draft.
        let allTasks = try writeContext.fetch(FetchDescriptor<CareTask>())
        let reminders = CareReminderScheduler.reminders(for: allTasks, now: now)
        try saveContext(writeContext)
        return reminders
    }
}
