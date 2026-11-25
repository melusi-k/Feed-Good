import Foundation
import SwiftData

enum CareOpportunityStatus: String, CaseIterable {
    case open
    case completed
    case cancelled
}

/// A persisted identity for one scheduled instance of a CareTask.
///
/// CareTask remains the reusable routine and current schedule pointer.
/// CareEvent remains the recorded-care history. This ledger connects the two
/// without making task deletion erase historical scheduled outcomes.
@Model
final class CareOpportunity {
    var id: UUID = UUID()
    var taskID: UUID
    var plantID: UUID
    var scheduledDueAt: Date
    var statusRaw: String = "open"
    var careEventID: UUID?
    var createdAt: Date
    var updatedAt: Date

    var status: CareOpportunityStatus? {
        CareOpportunityStatus(rawValue: statusRaw)
    }

    init(
        id: UUID = UUID(),
        taskID: UUID,
        plantID: UUID,
        scheduledDueAt: Date,
        status: CareOpportunityStatus = .open,
        careEventID: UUID? = nil,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.taskID = taskID
        self.plantID = plantID
        self.scheduledDueAt = scheduledDueAt
        self.statusRaw = status.rawValue
        self.careEventID = careEventID
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
