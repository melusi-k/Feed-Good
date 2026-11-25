import Foundation

/// Immutable source snapshots keep the calculator independent of SwiftData.
struct ScheduledCareOpportunitySnapshot: Equatable {
    let id: UUID
    let taskID: UUID
    let plantID: UUID
    let effectiveDueAt: Date
    let statusRaw: String
    let careEventID: UUID?

    @MainActor
    init(opportunity: CareOpportunity) {
        id = opportunity.id
        taskID = opportunity.taskID
        plantID = opportunity.plantID
        effectiveDueAt = opportunity.effectiveDueAt
        statusRaw = opportunity.statusRaw
        careEventID = opportunity.careEventID
    }
}

struct ScheduledCareEventSnapshot: Equatable {
    let id: UUID
    let taskID: UUID
    let plantID: UUID?
    let completedAt: Date

    @MainActor
    init(event: CareEvent) {
        id = event.id
        taskID = event.taskID
        plantID = event.plant?.id
        completedAt = event.completedAt
    }
}

/// Only active quiet-period memberships pause an opportunity. Historical
/// ended periods are represented by the opportunity's updated effective due.
struct ScheduledCareQuietPeriodSnapshot: Equatable {
    let taskID: UUID
    let plantID: UUID
    let startAt: Date

    @MainActor
    init?(membership: QuietPeriodTaskSnapshot) {
        guard membership.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue,
              let period = membership.quietPeriod,
              period.statusRaw == QuietPeriodStatus.active.rawValue,
              let plantID = period.plant?.id else {
            return nil
        }
        taskID = membership.taskID
        self.plantID = plantID
        startAt = period.activatedAt ?? period.startAt
    }

    /// The persisted active status is authoritative until lifecycle catch-up ends it.
    func isActive(at now: Date) -> Bool {
        now >= startAt
    }
}

enum ScheduledCareAnalyticsError: Error, Equatable {
    case invalidPeriod
    case duplicateOpportunity(UUID)
    case duplicateCareEvent(UUID)
    case invalidOpportunityStatus(UUID)
    case invalidCompletionLink(UUID)
}

enum ScheduledCareAnalyticsRange: String, CaseIterable, Identifiable {
    case last30Days
    case last90Days
    case last12Months

    var id: String { rawValue }
    var title: String {
        switch self {
        case .last30Days: "30 days"
        case .last90Days: "90 days"
        case .last12Months: "12 months"
        }
    }

    func period(now: Date, calendar: Calendar) -> DateInterval? {
        guard let today = calendar.dateInterval(of: .day, for: now) else {
            return nil
        }
        let start: Date?
        switch self {
        case .last30Days:
            start = calendar.date(byAdding: .day, value: -29, to: today.start)
        case .last90Days:
            start = calendar.date(byAdding: .day, value: -89, to: today.start)
        case .last12Months:
            start = calendar.date(byAdding: .month, value: -11, to: today.start)
        }
        guard let start else { return nil }
        return DateInterval(start: start, end: today.end)
    }
}

enum ScheduledCareOutcome: Equatable {
    case completedOnTime
    case completedLate
    case completedOutsideWindow
    case unresolved
    case overdue

    var isCompleted: Bool {
        switch self {
        case .completedOnTime, .completedLate, .completedOutsideWindow: return true
        case .unresolved, .overdue: return false
        }
    }
}

struct ScheduledCareAnalyticsRecord: Identifiable, Equatable {
    let id: UUID
    let taskID: UUID
    let effectiveDueAt: Date
    let careEventID: UUID?
    let completedAt: Date?
    let outcome: ScheduledCareOutcome
}

struct PlantScheduledCareAnalyticsSummary: Equatable {
    let plantID: UUID
    let period: DateInterval
    let timeZoneIdentifier: String
    let records: [ScheduledCareAnalyticsRecord]

    var completedCount: Int {
        records.filter { $0.outcome.isCompleted }.count
    }

    var completedOnTimeCount: Int {
        records.filter { $0.outcome == .completedOnTime }.count
    }

    var completedLateCount: Int {
        records.filter { $0.outcome == .completedLate }.count
    }

    var completedOutsideWindowCount: Int {
        records.filter { $0.outcome == .completedOutsideWindow }.count
    }

    var unresolvedCount: Int {
        records.filter { $0.outcome == .unresolved }.count
    }

    var overdueCount: Int {
        records.filter { $0.outcome == .overdue }.count
    }

    /// A late linked completion is still completed care. The separate late
    /// count makes timing transparent without changing the scheduled outcome.
    var completionRate: Double? {
        let denominator = completedCount + overdueCount
        guard denominator > 0 else { return nil }
        return Double(completedCount) / Double(denominator)
    }

    /// Includes today and the preceding local calendar days.
    static func period(days: Int, now: Date, calendar: Calendar) -> DateInterval? {
        guard days > 0,
              let today = calendar.dateInterval(of: .day, for: now),
              let start = calendar.date(byAdding: .day, value: -(days - 1), to: today.start) else {
            return nil
        }
        return DateInterval(start: start, end: today.end)
    }

    static func recent30Days(now: Date, calendar: Calendar) -> DateInterval? {
        period(days: 30, now: now, calendar: calendar)
    }

    /// Calculates scheduled outcomes only. Unlinked/manual CareEvents are
    /// deliberately ignored and cannot enter the scheduled denominator.
    static func calculate(
        plantID: UUID,
        period: DateInterval,
        now: Date,
        calendar: Calendar,
        opportunities: [ScheduledCareOpportunitySnapshot],
        events: [ScheduledCareEventSnapshot],
        quietPeriods: [ScheduledCareQuietPeriodSnapshot] = []
    ) throws -> PlantScheduledCareAnalyticsSummary {
        var eventByID: [UUID: ScheduledCareEventSnapshot] = [:]
        for event in events {
            guard eventByID[event.id] == nil else {
                throw ScheduledCareAnalyticsError.duplicateCareEvent(event.id)
            }
            eventByID[event.id] = event
        }

        var seenOpportunityIDs = Set<UUID>()
        var records: [ScheduledCareAnalyticsRecord] = []

        for opportunity in opportunities {
            guard seenOpportunityIDs.insert(opportunity.id).inserted else {
                throw ScheduledCareAnalyticsError.duplicateOpportunity(opportunity.id)
            }
            guard opportunity.plantID == plantID,
                  opportunity.effectiveDueAt >= period.start,
                  opportunity.effectiveDueAt < period.end else {
                continue
            }

            switch opportunity.statusRaw {
            case CareOpportunityStatus.cancelled.rawValue:
                continue
            case CareOpportunityStatus.completed.rawValue:
                guard let eventID = opportunity.careEventID,
                      let event = eventByID[eventID],
                      event.taskID == opportunity.taskID,
                      event.plantID == opportunity.plantID else {
                    throw ScheduledCareAnalyticsError.invalidCompletionLink(opportunity.id)
                }
                let deadline = CareOpportunityEligibility.streakDeadline(
                    for: opportunity.effectiveDueAt
                )
                let outcome: ScheduledCareOutcome
                if event.completedAt < opportunity.effectiveDueAt {
                    outcome = .completedOutsideWindow
                } else if event.completedAt <= deadline {
                    outcome = .completedOnTime
                } else {
                    outcome = .completedLate
                }
                records.append(ScheduledCareAnalyticsRecord(
                    id: opportunity.id,
                    taskID: opportunity.taskID,
                    effectiveDueAt: opportunity.effectiveDueAt,
                    careEventID: event.id,
                    completedAt: event.completedAt,
                    outcome: outcome
                ))
            case CareOpportunityStatus.open.rawValue:
                guard opportunity.effectiveDueAt <= now else { continue }
                let paused = quietPeriods.contains {
                    $0.taskID == opportunity.taskID &&
                    $0.plantID == opportunity.plantID &&
                    $0.isActive(at: now)
                }
                guard !paused else { continue }

                let outcome: ScheduledCareOutcome =
                    CareOpportunityEligibility.gracePeriodHasExpired(
                        now: now,
                        effectiveDueAt: opportunity.effectiveDueAt
                    ) ? .overdue : .unresolved
                records.append(ScheduledCareAnalyticsRecord(
                    id: opportunity.id,
                    taskID: opportunity.taskID,
                    effectiveDueAt: opportunity.effectiveDueAt,
                    careEventID: nil,
                    completedAt: nil,
                    outcome: outcome
                ))
            default:
                throw ScheduledCareAnalyticsError.invalidOpportunityStatus(opportunity.id)
            }
        }

        records.sort {
            if $0.effectiveDueAt != $1.effectiveDueAt {
                return $0.effectiveDueAt > $1.effectiveDueAt
            }
            return $0.id.uuidString < $1.id.uuidString
        }

        return PlantScheduledCareAnalyticsSummary(
            plantID: plantID,
            period: period,
            timeZoneIdentifier: calendar.timeZone.identifier,
            records: records
        )
    }
}
