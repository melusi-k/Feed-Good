import Foundation
import SwiftData

/// A durable identity for one scheduled care opportunity.
///
/// CareTask remains the recurring routine and CareEvent remains the recorded
/// action. This record only connects one schedule instance to its eventual
/// outcome; it is not a second task or event history.
@Model
final class ScheduledCareOpportunity {
    var id: UUID = UUID()
    var taskID: UUID
    var plantID: UUID
    /// Original due instant captured when this opportunity was created.
    /// Treat as immutable after insertion.
    var scheduledDueAt: Date
    /// Current eligibility boundary. Quiet Period resume may adjust this
    /// under the PRD-020 calendar contract without changing opportunity ID.
    var effectiveDueAt: Date
    var statusRaw: String = "open"
    /// Set only when this opportunity is completed by its accepted CareEvent.
    var careEventID: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        taskID: UUID,
        plantID: UUID,
        scheduledDueAt: Date,
        effectiveDueAt: Date? = nil,
        statusRaw: String = "open",
        careEventID: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.taskID = taskID
        self.plantID = plantID
        self.scheduledDueAt = scheduledDueAt
        self.effectiveDueAt = effectiveDueAt ?? scheduledDueAt
        self.statusRaw = statusRaw
        self.careEventID = careEventID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
