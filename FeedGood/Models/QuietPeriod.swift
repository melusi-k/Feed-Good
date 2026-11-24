import Foundation
import SwiftData

/// A user-authored pause window for one plant. Scheduling and lifecycle
/// transitions are implemented in the Quiet Period domain layer.
@Model
final class QuietPeriod {
    var id: UUID = UUID()
    var createdAt: Date = Date.now
    /// Absolute instant selected for immediate or scheduled activation.
    var startAt: Date = Date.now
    /// Nil means explicitly open-ended.
    var endAt: Date?
    var statusRaw: String = "scheduled"
    var reason: String?
    var activatedAt: Date?
    var endedAt: Date?
    var plant: Plant?
    @Relationship(deleteRule: .cascade, inverse: \QuietPeriodTaskSnapshot.quietPeriod)
    var taskSnapshots: [QuietPeriodTaskSnapshot]? = []

    init(
        id: UUID = UUID(),
        createdAt: Date = .now,
        startAt: Date = .now,
        endAt: Date? = nil,
        statusRaw: String = "scheduled",
        reason: String? = nil,
        activatedAt: Date? = nil,
        endedAt: Date? = nil,
        plant: Plant
    ) {
        self.id = id
        self.createdAt = createdAt
        self.startAt = startAt
        self.endAt = endAt
        self.statusRaw = statusRaw
        self.reason = reason
        self.activatedAt = activatedAt
        self.endedAt = endedAt
        self.plant = plant
    }
}

/// Captures membership and frozen scheduling state without a CareTask
/// relationship. Deleting a task therefore cannot erase this audit record.
@Model
final class QuietPeriodTaskSnapshot {
    var id: UUID = UUID()
    var taskID: UUID = UUID()
    var taskTitleSnapshot: String = ""
    var membershipStatusRaw: String = "active"
    /// Signed calendar-day offset captured at activation.
    var remainingCalendarDays: Int?
    /// Original local due-time components used when reconstructing on resume.
    var originalDueHour: Int?
    var originalDueMinute: Int?
    var originalDueSecond: Int?
    /// Updated by completion/interval edits while the period is active.
    var frozenIntervalDays: Int?
    /// Exact-instant override from an explicit Next care edit.
    var nextCareOverrideAt: Date?
    var capturedAt: Date = Date.now
    var updatedAt: Date = Date.now
    var quietPeriod: QuietPeriod?

    init(
        id: UUID = UUID(),
        taskID: UUID,
        taskTitleSnapshot: String,
        membershipStatusRaw: String = "active",
        remainingCalendarDays: Int? = nil,
        originalDueHour: Int? = nil,
        originalDueMinute: Int? = nil,
        originalDueSecond: Int? = nil,
        frozenIntervalDays: Int? = nil,
        nextCareOverrideAt: Date? = nil,
        capturedAt: Date = .now,
        updatedAt: Date = .now,
        quietPeriod: QuietPeriod
    ) {
        self.id = id
        self.taskID = taskID
        self.taskTitleSnapshot = taskTitleSnapshot
        self.membershipStatusRaw = membershipStatusRaw
        self.remainingCalendarDays = remainingCalendarDays
        self.originalDueHour = originalDueHour
        self.originalDueMinute = originalDueMinute
        self.originalDueSecond = originalDueSecond
        self.frozenIntervalDays = frozenIntervalDays
        self.nextCareOverrideAt = nextCareOverrideAt
        self.capturedAt = capturedAt
        self.updatedAt = updatedAt
        self.quietPeriod = quietPeriod
    }
}
