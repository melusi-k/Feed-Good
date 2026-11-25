import Foundation
import SwiftData

enum CareOpportunityLifecycleError: Error, Equatable {
    case taskHasNoPlant
    case archivedPlant
    case invalidLifecycleState
    case duplicateCurrentOpportunity
    case opportunityAlreadyResolved
}

/// Captures only opportunity mutations so a failed compound save can restore
/// the exact pre-transaction identities and lifecycle values.
struct CareOpportunityLifecycleSnapshot {
    struct State {
        let record: CareOpportunity
        let statusRaw: String
        let careEventID: UUID?
        let effectiveDueAt: Date
        let updatedAt: Date
    }

    let taskIDs: Set<UUID>
    let states: [State]
}

@MainActor
enum CareOpportunityLifecycle {
    /// Creates the one opportunity for a task's current due instant if it does
    /// not already exist. Older reopened opportunities remain independent history.
    @discardableResult
    static func ensureCurrent(
        for task: CareTask,
        at date: Date = .now,
        in context: ModelContext
    ) throws -> CareOpportunity? {
        guard let plant = task.plant else {
            throw CareOpportunityLifecycleError.taskHasNoPlant
        }
        guard plant.archivedAt == nil else {
            throw CareOpportunityLifecycleError.archivedPlant
        }
        guard task.isEnabled else {
            try cancelOpen(for: task.id, at: date, in: context)
            return nil
        }

        let records = try opportunities(for: task.id, in: context)
        try validate(records)
        let matching = records.filter {
            $0.statusRaw == CareOpportunityStatus.open.rawValue &&
            $0.effectiveDueAt == task.dueDate
        }
        guard matching.count <= 1 else {
            throw CareOpportunityLifecycleError.duplicateCurrentOpportunity
        }
        if let existing = matching.first {
            guard existing.plantID == plant.id else {
                throw CareOpportunityLifecycleError.invalidLifecycleState
            }
            return existing
        }

        let opportunity = CareOpportunity(
            taskID: task.id,
            plantID: plant.id,
            scheduledDueAt: task.dueDate,
            effectiveDueAt: task.dueDate,
            createdAt: date,
            updatedAt: date
        )
        context.insert(opportunity)
        return opportunity
    }

    /// Applies task editor semantics. A due-date change cancels only the
    /// superseded current opportunity; disablement cancels every open outcome.
    static func applyScheduleChange(
        to task: CareTask,
        previousDueDate: Date,
        at date: Date,
        in context: ModelContext
    ) throws {
        guard let plant = task.plant else {
            throw CareOpportunityLifecycleError.taskHasNoPlant
        }
        guard plant.archivedAt == nil else {
            throw CareOpportunityLifecycleError.archivedPlant
        }

        if !task.isEnabled {
            try cancelOpen(for: task.id, at: date, in: context)
            return
        }

        if task.dueDate != previousDueDate {
            try cancelOpen(for: task.id, scheduledDueAt: previousDueDate, at: date, in: context)
        }
        _ = try ensureCurrent(for: task, at: date, in: context)
    }

    /// Resumes a Quiet Period occurrence without replacing its stable identity.
    /// The original scheduled instant remains immutable; only the effective
    /// eligibility boundary moves to the resumed task due date.
    static func resumeAfterQuietPeriod(
        for task: CareTask,
        previousDueDate: Date,
        at date: Date,
        in context: ModelContext
    ) throws {
        guard let plant = task.plant else {
            throw CareOpportunityLifecycleError.taskHasNoPlant
        }
        guard plant.archivedAt == nil else {
            throw CareOpportunityLifecycleError.archivedPlant
        }
        guard task.isEnabled else {
            try cancelOpen(for: task.id, at: date, in: context)
            return
        }

        let records = try opportunities(for: task.id, in: context)
        try validate(records)
        let matching = records.filter {
            $0.statusRaw == CareOpportunityStatus.open.rawValue &&
            $0.scheduledDueAt == previousDueDate
        }
        guard matching.count <= 1 else {
            throw CareOpportunityLifecycleError.duplicateCurrentOpportunity
        }
        if let existing = matching.first {
            guard existing.plantID == plant.id else {
                throw CareOpportunityLifecycleError.invalidLifecycleState
            }
            existing.effectiveDueAt = task.dueDate
            existing.updatedAt = date
            return
        }

        context.insert(CareOpportunity(
            taskID: task.id,
            plantID: plant.id,
            scheduledDueAt: previousDueDate,
            effectiveDueAt: task.dueDate,
            createdAt: date,
            updatedAt: date
        ))
    }

    static func cancelOpen(
        for taskID: UUID,
        effectiveDueAt: Date? = nil,
        at date: Date = .now,
        in context: ModelContext
    ) throws {
        let records = try opportunities(for: taskID, in: context)
        try validate(records)
        for record in records where
            record.statusRaw == CareOpportunityStatus.open.rawValue &&
            (scheduledDueAt == nil || record.scheduledDueAt == scheduledDueAt) {
            record.statusRaw = CareOpportunityStatus.cancelled.rawValue
            record.updatedAt = date
        }
    }

    static func complete(
        _ opportunity: CareOpportunity,
        with eventID: UUID,
        at date: Date
    ) throws {
        guard opportunity.statusRaw == CareOpportunityStatus.open.rawValue,
              opportunity.careEventID == nil else {
            throw CareOpportunityLifecycleError.opportunityAlreadyResolved
        }
        opportunity.statusRaw = CareOpportunityStatus.completed.rawValue
        opportunity.careEventID = eventID
        opportunity.updatedAt = date
    }

    /// Reopens the linked opportunity when its CareEvent is deleted. The task's
    /// current due date is intentionally not rewound.
    @discardableResult
    static func reopen(
        linkedTo eventID: UUID,
        at date: Date,
        in context: ModelContext
    ) throws -> CareOpportunity? {
        let records = try context.fetch(FetchDescriptor<CareOpportunity>()).filter {
            $0.careEventID == eventID
        }
        guard records.count <= 1 else {
            throw CareOpportunityLifecycleError.invalidLifecycleState
        }
        guard let opportunity = records.first else { return nil }
        guard opportunity.statusRaw == CareOpportunityStatus.completed.rawValue else {
            throw CareOpportunityLifecycleError.invalidLifecycleState
        }
        let taskID = opportunity.taskID
        let taskDescriptor = FetchDescriptor<CareTask>(
            predicate: #Predicate { $0.id == taskID }
        )
        let task = try context.fetch(taskDescriptor).first
        opportunity.statusRaw = task?.isEnabled == true
            ? CareOpportunityStatus.open.rawValue
            : CareOpportunityStatus.cancelled.rawValue
        opportunity.careEventID = nil
        opportunity.updatedAt = date
        return opportunity
    }

    static func snapshot(
        for taskIDs: Set<UUID>,
        in context: ModelContext
    ) throws -> CareOpportunityLifecycleSnapshot {
        let records = try context.fetch(FetchDescriptor<CareOpportunity>()).filter {
            taskIDs.contains($0.taskID)
        }
        return CareOpportunityLifecycleSnapshot(
            taskIDs: taskIDs,
            states: records.map {
                CareOpportunityLifecycleSnapshot.State(
                    record: $0,
                    statusRaw: $0.statusRaw,
                    careEventID: $0.careEventID,
                    effectiveDueAt: $0.effectiveDueAt,
                    updatedAt: $0.updatedAt
                )
            }
        )
    }

    static func restore(
        _ snapshot: CareOpportunityLifecycleSnapshot,
        in context: ModelContext
    ) {
        let originalIDs = Set(snapshot.states.map { $0.record.id })
        let current = (try? context.fetch(FetchDescriptor<CareOpportunity>())) ?? []
        for record in current where
            snapshot.taskIDs.contains(record.taskID) &&
            !originalIDs.contains(record.id) {
            context.delete(record)
        }
        for state in snapshot.states {
            state.record.statusRaw = state.statusRaw
            state.record.careEventID = state.careEventID
            state.record.effectiveDueAt = state.effectiveDueAt
            state.record.updatedAt = state.updatedAt
        }
    }

    /// Hard-deleting a plant removes its plant-owned opportunity ledger.
    static func deleteAll(
        for plantID: UUID,
        in context: ModelContext
    ) throws {
        let records = try context.fetch(FetchDescriptor<CareOpportunity>()).filter {
            $0.plantID == plantID
        }
        for record in records { context.delete(record) }
    }

    private static func opportunities(
        for taskID: UUID,
        in context: ModelContext
    ) throws -> [CareOpportunity] {
        let descriptor = FetchDescriptor<CareOpportunity>(
            predicate: #Predicate { $0.taskID == taskID }
        )
        return try context.fetch(descriptor)
    }

    private static func validate(_ records: [CareOpportunity]) throws {
        for record in records {
            guard let status = CareOpportunityStatus(rawValue: record.statusRaw) else {
                throw CareOpportunityLifecycleError.invalidLifecycleState
            }
            switch status {
            case .open, .cancelled:
                guard record.careEventID == nil else {
                    throw CareOpportunityLifecycleError.invalidLifecycleState
                }
            case .completed:
                guard record.careEventID != nil else {
                    throw CareOpportunityLifecycleError.invalidLifecycleState
                }
            }
        }
    }
}
