import Foundation
import SwiftData

/// User-defined reminders to observe a plant, never horticultural advice.
enum CareKind: String, CaseIterable, Identifiable {
    case watering, feeding, pruning, custom
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CareDueState: String { case overdue, due, upcoming }

struct CareSchedule {
    static func nextDate(after date: Date, intervalDays: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: max(1, intervalDays), to: date) ?? date
    }

    static func state(for dueDate: Date, now: Date = .now, calendar: Calendar = .current) -> CareDueState {
        let due = calendar.startOfDay(for: dueDate)
        let today = calendar.startOfDay(for: now)
        if due < today { return .overdue }
        return due == today ? .due : .upcoming
    }
}

@Model
final class CareTask {
    var id: UUID = UUID()
    var kindRaw: String = "watering"
    var customTitle: String = ""
    var intervalDays: Int = 7
    var dueDate: Date = Date.now
    var isEnabled: Bool = true
    var reminderEnabled: Bool = false
    var plant: Plant?

    var kind: CareKind { CareKind(rawValue: kindRaw) ?? .custom }
    var title: String { kind == .custom ? customTitle : kind.title }

    init(
        id: UUID = UUID(),
        kind: CareKind,
        customTitle: String = "",
        intervalDays: Int,
        dueDate: Date,
        isEnabled: Bool = true,
        reminderEnabled: Bool = false,
        plant: Plant
    ) {
        self.id = id
        self.kindRaw = kind.rawValue
        self.customTitle = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        self.intervalDays = max(1, intervalDays)
        self.dueDate = dueDate
        self.isEnabled = isEnabled
        self.reminderEnabled = reminderEnabled
        self.plant = plant
    }
}

@Model
final class CareEvent {
    var id: UUID = UUID()
    var taskID: UUID = UUID()
    var taskTitle: String = ""
    var completedAt: Date = Date.now
    var note: String = ""
    var plant: Plant?

    init(task: CareTask, completedAt: Date = .now, note: String = "") {
        self.id = UUID()
        self.taskID = task.id
        self.taskTitle = task.title
        self.completedAt = completedAt
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.plant = task.plant
    }

    /// Restores a historical completion snapshot even when its original task
    /// has since been removed from the user's active care routine.
    init(
        id: UUID = UUID(),
        taskID: UUID,
        taskTitle: String,
        completedAt: Date = .now,
        note: String = "",
        plant: Plant
    ) {
        self.id = id
        self.taskID = taskID
        self.taskTitle = taskTitle
        self.completedAt = completedAt
        self.note = note
        self.plant = plant
    }
}

enum CareRecorderError: Error, Equatable {
    case archivedPlant
    case taskDisabled
}

@MainActor
enum CareRecorder {
    static func complete(
        _ task: CareTask,
        note: String,
        at date: Date = .now,
        in context: ModelContext,
        calendar: Calendar = .current,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        guard let plant = task.plant, plant.archivedAt == nil else {
            throw CareRecorderError.archivedPlant
        }
        guard task.isEnabled else { throw CareRecorderError.taskDisabled }

        let previousDate = task.dueDate
        let quietSnapshot = try QuietPeriodTaskIntegration.activeSnapshot(for: task.id, in: context)
        let previousFrozenInterval = quietSnapshot?.frozenIntervalDays
        let previousOverride = quietSnapshot?.nextCareOverrideAt
        let previousSnapshotUpdate = quietSnapshot?.updatedAt
        let isPaused = quietSnapshot != nil
        let opportunitySnapshot = try CareOpportunityLifecycle.snapshot(for: [task.id], in: context)
        let opportunity = try CareOpportunityLifecycle.ensureCurrent(for: task, at: date, in: context)

        if let quietSnapshot {
            quietSnapshot.frozenIntervalDays = max(1, task.intervalDays)
            quietSnapshot.nextCareOverrideAt = nil
            quietSnapshot.updatedAt = date
        }

        let event = CareEvent(task: task, completedAt: date, note: note)
        context.insert(event)

        if !isPaused {
            if let opportunity, date >= opportunity.effectiveDueAt {
                try CareOpportunityLifecycle.complete(opportunity, with: event.id, at: date)
            }
            let nextDueDate = CareSchedule.nextDate(
                after: date,
                intervalDays: task.intervalDays,
                calendar: calendar
            )
            if let opportunity,
               date < opportunity.effectiveDueAt,
               nextDueDate != previousDate {
                try CareOpportunityLifecycle.cancelOpen(
                    for: task.id,
                    scheduledDueAt: opportunity.scheduledDueAt,
                    at: date,
                    in: context
                )
            }
            task.dueDate = nextDueDate
            _ = try CareOpportunityLifecycle.ensureCurrent(for: task, at: date, in: context)
        }

        do {
            try save(context)
        } catch {
            task.dueDate = previousDate
            quietSnapshot?.frozenIntervalDays = previousFrozenInterval
            quietSnapshot?.nextCareOverrideAt = previousOverride
            if let previousSnapshotUpdate { quietSnapshot?.updatedAt = previousSnapshotUpdate }
            context.delete(event)
            CareOpportunityLifecycle.restore(opportunitySnapshot, in: context)
            throw error
        }
    }

    /// Corrects one recorded event's date or note. History-only policy: a
    /// correction never changes the active routine's due date or interval,
    /// and the task-title snapshot recorded at completion is preserved.
    static func update(
        _ event: CareEvent,
        completedAt: Date,
        note: String,
        in context: ModelContext,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        let previousDate = event.completedAt
        let previousNote = event.note
        event.completedAt = completedAt
        event.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        do { try save(context) }
        catch {
            event.completedAt = previousDate
            event.note = previousNote
            context.rollback()
            throw error
        }
    }

    /// Removes one recorded event. Unrelated events, tasks, plants and
    /// journal entries are untouched.
    static func delete(
        _ event: CareEvent,
        in context: ModelContext,
        at date: Date = .now,
        save: (ModelContext) throws -> Void = { try $0.save() }
    ) throws {
        try CareOpportunityLifecycle.reopen(linkedTo: event.id, at: date, in: context)
        context.delete(event)
        do { try save(context) }
        catch {
            // A delete that has not been processed crashes rollback() with
            // "ModelSnapshot must be initialized with a known-keys dictionary".
            context.processPendingChanges()
            context.rollback()
            throw error
        }
    }
}
