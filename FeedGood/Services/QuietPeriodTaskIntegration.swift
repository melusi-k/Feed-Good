import Foundation
import SwiftData

/// Applies the Quiet Period overlay to task mutations without changing the
/// user's independent CareTask.isEnabled preference.
@MainActor
enum QuietPeriodTaskIntegration {
    static func activeSnapshot(for taskID: UUID, in context: ModelContext) throws -> QuietPeriodTaskSnapshot? {
        let descriptor = FetchDescriptor<QuietPeriodTaskSnapshot>(
            predicate: #Predicate { $0.taskID == taskID && $0.membershipStatusRaw == "active" }
        )
        return try context.fetch(descriptor).first {
            $0.quietPeriod?.statusRaw == QuietPeriodStatus.active.rawValue
        }
    }

    static func applyCompletion(
        to task: CareTask,
        at date: Date,
        in context: ModelContext
    ) throws -> Bool {
        guard let snapshot = try activeSnapshot(for: task.id, in: context) else { return false }
        snapshot.frozenIntervalDays = max(1, task.intervalDays)
        snapshot.nextCareOverrideAt = nil
        snapshot.updatedAt = date
        return true
    }

    static func applyEditorChanges(
        to task: CareTask,
        previousIntervalDays: Int,
        previousDueDate: Date,
        previousEnabled: Bool,
        at date: Date,
        in context: ModelContext
    ) throws {
        guard let snapshot = try activeSnapshot(for: task.id, in: context) else { return }
        if task.intervalDays != previousIntervalDays {
            snapshot.frozenIntervalDays = max(1, task.intervalDays)
            snapshot.nextCareOverrideAt = nil
        }
        if task.dueDate != previousDueDate {
            snapshot.nextCareOverrideAt = task.dueDate
        }
        if previousEnabled && !task.isEnabled {
            snapshot.membershipStatusRaw = QuietPeriodMembershipStatus.disabled.rawValue
        }
        // Re-enabling does not restore active membership during this period.
        snapshot.updatedAt = date
    }

    static func markDeleted(
        taskID: UUID,
        at date: Date,
        in context: ModelContext
    ) throws {
        guard let snapshot = try activeSnapshot(for: taskID, in: context) else { return }
        snapshot.membershipStatusRaw = QuietPeriodMembershipStatus.removed.rawValue
        snapshot.updatedAt = date
        guard let period = snapshot.quietPeriod else { return }
        let descriptor = FetchDescriptor<QuietPeriodTaskSnapshot>(
            predicate: #Predicate { $0.quietPeriod?.id == period.id && $0.membershipStatusRaw == "active" }
        )
        let remaining = try context.fetch(descriptor)
        if remaining.isEmpty {
            period.statusRaw = QuietPeriodStatus.ended.rawValue
            period.endedAt = date
        }
    }

    static func reconcileEmptyPeriod(
        for snapshot: QuietPeriodTaskSnapshot,
        at date: Date,
        in context: ModelContext
    ) throws {
        guard let period = snapshot.quietPeriod else { return }
        let periodID = period.id
        let descriptor = FetchDescriptor<QuietPeriodTaskSnapshot>(
            predicate: #Predicate { $0.quietPeriod?.id == periodID && $0.membershipStatusRaw == "active" }
        )
        if try context.fetch(descriptor).isEmpty {
            period.statusRaw = QuietPeriodStatus.ended.rawValue
            period.endedAt = date
        }
    }
}
