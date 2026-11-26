import Foundation

/// Private per-task consistency history over scheduled-care source records.
///
/// A streak counts consecutive eligible opportunities completed within the
/// shared 24-hour completion window (`CareOpportunityEligibility`). Cancelled,
/// paused, not-yet-due and archived-open opportunities are neutral: they
/// neither advance nor break a streak. Late or date-corrected completions
/// remain completed care but do not count toward a streak. Streaks are scoped
/// to a single stable CareTask UUID and are recomputed from source records on
/// every read; nothing derived is persisted and no history is backfilled.
struct CareTaskStreakSummary: Equatable {
    let taskID: UUID
    let currentStreak: Int
    let longestStreak: Int
    /// Opportunities forming the current run, oldest first.
    let currentRunOpportunityIDs: [UUID]
    /// Opportunities forming the longest run, oldest first.
    let longestRunOpportunityIDs: [UUID]
    /// `effectiveDueAt` of the first opportunity in the current run.
    let currentRunStart: Date?
    /// `effectiveDueAt` bounds of the longest run.
    let longestRunStart: Date?
    let longestRunEnd: Date?
}

enum CareTaskStreaks {
    /// One eligible opportunity's effect on a run.
    private enum Disposition: Equatable {
        /// Completed within the shared completion window: advances the run.
        case onTime
        /// Late completion, date-corrected completion or definitively
        /// overdue: ends the current run.
        case interruption
        /// Cancelled, still inside its window, or open while archived:
        /// neither advances nor breaks the run.
        case neutral
    }

    static func calculate(
        taskID: UUID,
        now: Date,
        opportunities: [ScheduledCareOpportunitySnapshot],
        events: [ScheduledCareEventSnapshot],
        isArchived: Bool = false
    ) throws -> CareTaskStreakSummary {
        var eventByID: [UUID: ScheduledCareEventSnapshot] = [:]
        for event in events {
            guard eventByID[event.id] == nil else {
                throw ScheduledCareAnalyticsError.duplicateCareEvent(event.id)
            }
            eventByID[event.id] = event
        }

        let taskOpportunities = opportunities
            .filter { $0.taskID == taskID }
            .sorted {
                ($0.effectiveDueAt, $0.id.uuidString) < ($1.effectiveDueAt, $1.id.uuidString)
            }

        var seenOpportunityIDs = Set<UUID>()
        var currentRun: [ScheduledCareOpportunitySnapshot] = []
        var longestRun: [ScheduledCareOpportunitySnapshot] = []

        for opportunity in taskOpportunities {
            guard seenOpportunityIDs.insert(opportunity.id).inserted else {
                throw ScheduledCareAnalyticsError.duplicateOpportunity(opportunity.id)
            }

            switch try disposition(
                of: opportunity,
                now: now,
                eventByID: eventByID,
                isArchived: isArchived
            ) {
            case .onTime:
                currentRun.append(opportunity)
                if currentRun.count > longestRun.count {
                    longestRun = currentRun
                }
            case .interruption:
                currentRun = []
            case .neutral:
                continue
            }
        }

        return CareTaskStreakSummary(
            taskID: taskID,
            currentStreak: currentRun.count,
            longestStreak: longestRun.count,
            currentRunOpportunityIDs: currentRun.map(\.id),
            longestRunOpportunityIDs: longestRun.map(\.id),
            currentRunStart: currentRun.first?.effectiveDueAt,
            longestRunStart: longestRun.first?.effectiveDueAt,
            longestRunEnd: longestRun.last?.effectiveDueAt
        )
    }

    private static func disposition(
        of opportunity: ScheduledCareOpportunitySnapshot,
        now: Date,
        eventByID: [UUID: ScheduledCareEventSnapshot],
        isArchived: Bool
    ) throws -> Disposition {
        switch opportunity.statusRaw {
        case CareOpportunityStatus.cancelled.rawValue:
            return .neutral
        case CareOpportunityStatus.completed.rawValue:
            guard let eventID = opportunity.careEventID,
                  let event = eventByID[eventID],
                  event.taskID == opportunity.taskID,
                  event.plantID == opportunity.plantID else {
                throw ScheduledCareAnalyticsError.invalidCompletionLink(opportunity.id)
            }
            if CareOpportunityEligibility.qualifiesForStreak(
                completedAt: event.completedAt,
                effectiveDueAt: opportunity.effectiveDueAt
            ) {
                return .onTime
            }
            // Late or date-corrected care stays completed but never counts
            // toward a streak, and never retroactively restores one.
            return .interruption
        case CareOpportunityStatus.open.rawValue:
            if isArchived {
                // Open outcomes are neutral while the plant is archived;
                // completed history is retained and restoring recomputes.
                return .neutral
            }
            // An open opportunity breaks the current streak only once the
            // shared completion window has definitively expired.
            return CareOpportunityEligibility.gracePeriodHasExpired(
                now: now,
                effectiveDueAt: opportunity.effectiveDueAt
            ) ? .interruption : .neutral
        default:
            throw ScheduledCareAnalyticsError.invalidOpportunityStatus(opportunity.id)
        }
    }
}
