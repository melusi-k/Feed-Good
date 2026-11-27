import Foundation

/// Local-day resolution of a garden-wide scheduled-care day.
///
/// Day states are explicit so presentation and tests never infer them from
/// run counts.
enum GardenCareStreakDayState: String, Equatable {
    /// At least one eligible opportunity has not resolved: it is still open
    /// inside its grace window, not due yet, or carries a future-dated
    /// completion. The day is neither counted nor declared failed yet.
    case pending
    /// Every eligible opportunity due that day completed on time.
    case qualified
    /// All eligible opportunities resolved and at least one completed late
    /// or was left open past its grace deadline.
    case failed
    /// No eligible opportunities are attributed to the day. Neutral days
    /// neither advance nor break a run; care is not expected every day.
    case neutral
}

/// One local calendar day with the eligible opportunities attributed to it.
struct GardenCareStreakDay: Equatable {
    /// Local midnight opening the half-open day interval
    /// `[dayStart, next local midnight)` in the injected calendar.
    let dayStart: Date
    let state: GardenCareStreakDayState
    /// Eligible source opportunities attributed to the day, oldest first.
    let opportunityIDs: [UUID]
    /// Of a pending day's unresolved opportunities: how many have not
    /// reached their effective due instant yet, so their 24-hour window
    /// has not started.
    let pendingNotYetDueCount: Int
    /// Of a pending day's unresolved opportunities: how many are due and
    /// inside their inclusive 24-hour window right now.
    let pendingInWindowCount: Int

    init(dayStart: Date, state: GardenCareStreakDayState, opportunityIDs: [UUID], pendingNotYetDueCount: Int = 0, pendingInWindowCount: Int = 0) {
        self.dayStart = dayStart
        self.state = state
        self.opportunityIDs = opportunityIDs
        self.pendingNotYetDueCount = pendingNotYetDueCount
        self.pendingInWindowCount = pendingInWindowCount
    }
}

/// Garden-wide descriptive run of qualifying scheduled-care days.
///
/// This is a distinct feature from per-task Plant Care Streaks
/// (`CareTaskStreaks`): it is calculated directly from eligible
/// CareOpportunity and linked CareEvent records across the garden and never
/// sums, averages or relabels per-task results.
struct GardenCareStreakSummary: Equatable {
    /// Consecutive qualifying local days ending at the latest resolved day.
    let currentRun: Int
    let longestRun: Int
    /// Local day start of the first day in the current run.
    let currentRunStart: Date?
    /// Local day bounds of the longest run.
    let longestRunStart: Date?
    let longestRunEnd: Date?
    /// Source opportunities forming the current run, oldest first.
    let currentRunOpportunityIDs: [UUID]
    /// Source opportunities forming the longest run, oldest first.
    let longestRunOpportunityIDs: [UUID]
    /// Local day of the first persisted eligible opportunity. Nil when the
    /// garden has none; nothing earlier is inferred or backfilled.
    let coverageStart: Date?
    /// The current candidate day, when it still waits on unresolved
    /// opportunities. Future days with only not-yet-due care are not
    /// surfaced here.
    let pendingDay: GardenCareStreakDay?
    /// Every attributed local day in chronological order, for traceability.
    let days: [GardenCareStreakDay]
}

/// Private, descriptive Garden Care Streak calculator.
///
/// Pure and deterministic over immutable value snapshots; SwiftData fetches
/// stay at the persistence boundary. Recomputed from source records on every
/// read: completion corrections, schedule edits, Quiet Period changes,
/// archive/restore and import all flow through the inputs, so nothing
/// derived is persisted and no history is backfilled.
///
/// Qualification rule: for a local calendar day to qualify, every eligible
/// scheduled-care opportunity whose authoritative `effectiveDueAt` falls
/// within that half-open local day must have an authoritative linked
/// CareEvent completed inside the shared inclusive 24-hour window
/// (`CareOpportunityEligibility`). Cancelled opportunities are excluded;
/// disabled tasks, active Quiet Periods and archived-open opportunities are
/// neutral under the owning lifecycle contract. A later completion never
/// repairs a failed day.
enum GardenCareStreaks {
    /// One eligible opportunity's contribution to its day.
    private enum Resolution: Equatable {
        /// Completed inside the shared inclusive 24-hour window.
        case onTime
        /// Completed after the window, or left open past its deadline.
        case late
        /// Still open inside its window, not due yet, or carrying a
        /// future-dated completion: the day cannot resolve yet.
        case unresolved
        /// Cancelled, Quiet-Period-paused or archived-open: no contribution.
        case excluded
    }

    static func calculate(
        now: Date,
        calendar: Calendar,
        opportunities: [ScheduledCareOpportunitySnapshot],
        events: [ScheduledCareEventSnapshot],
        quietPeriods: [ScheduledCareQuietPeriodSnapshot] = [],
        archivedPlantIDs: Set<UUID> = []
    ) throws -> GardenCareStreakSummary {
        var eventByID: [UUID: ScheduledCareEventSnapshot] = [:]
        for event in events {
            guard eventByID[event.id] == nil else {
                throw ScheduledCareAnalyticsError.duplicateCareEvent(event.id)
            }
            eventByID[event.id] = event
        }

        // Attribute each opportunity to exactly one local day: the half-open
        // interval [local midnight, next local midnight) in the injected
        // calendar. Calendar owns 23/24/25-hour DST days and time-zone
        // changes; the calculator never derives boundaries from elapsed
        // seconds.
        var dayBuckets: [Date: [ScheduledCareOpportunitySnapshot]] = [:]
        var seenOpportunityIDs = Set<UUID>()
        for opportunity in opportunities {
            guard seenOpportunityIDs.insert(opportunity.id).inserted else {
                throw ScheduledCareAnalyticsError.duplicateOpportunity(opportunity.id)
            }
            // Cancelled opportunities are excluded from eligibility entirely.
            guard opportunity.statusRaw != CareOpportunityStatus.cancelled.rawValue else {
                continue
            }
            guard let dayStart = calendar.dateInterval(of: .day, for: opportunity.effectiveDueAt)?.start else {
                throw ScheduledCareAnalyticsError.invalidPeriod
            }
            dayBuckets[dayStart, default: []].append(opportunity)
        }

        var days: [GardenCareStreakDay] = []
        days.reserveCapacity(dayBuckets.count)

        for dayStart in dayBuckets.keys.sorted() {
            let bucket = dayBuckets[dayStart]!.sorted {
                ($0.effectiveDueAt, $0.id.uuidString) < ($1.effectiveDueAt, $1.id.uuidString)
            }
            var eligibleIDs: [UUID] = []
            var hasUnresolved = false
            var hasFailure = false
            var notYetDue = 0
            var inWindow = 0
            for opportunity in bucket {
                switch try resolution(
                    of: opportunity,
                    now: now,
                    eventByID: eventByID,
                    quietPeriods: quietPeriods,
                    archivedPlantIDs: archivedPlantIDs
                ) {
                case .excluded:
                    continue
                case .onTime:
                    eligibleIDs.append(opportunity.id)
                case .late:
                    eligibleIDs.append(opportunity.id)
                    hasFailure = true
                case .unresolved:
                    eligibleIDs.append(opportunity.id)
                    hasUnresolved = true
                    if opportunity.effectiveDueAt > now {
                        notYetDue += 1
                    } else {
                        inWindow += 1
                    }
                }
            }
            let state: GardenCareStreakDayState
            if eligibleIDs.isEmpty {
                state = .neutral
            } else if hasUnresolved {
                // Pending dominates: the day stays provisional until every
                // eligible opportunity has resolved or its individual grace
                // deadline has expired. No premature success or failure.
                state = .pending
            } else if hasFailure {
                state = .failed
            } else {
                state = .qualified
            }
            days.append(GardenCareStreakDay(dayStart: dayStart, state: state, opportunityIDs: eligibleIDs, pendingNotYetDueCount: notYetDue, pendingInWindowCount: inWindow))
        }

        // Runs: qualifying days advance, failed days interrupt, neutral
        // no-opportunity days are skipped. Pending days never join a run:
        // they reset the accumulator so a later qualifying day cannot
        // bridge a day whose outcome is still unresolved. The reported
        // current run still ends at the latest resolved day.
        var currentRun: [GardenCareStreakDay] = []
        var longestRun: [GardenCareStreakDay] = []
        var lastResolvedRun: [GardenCareStreakDay] = []
        for day in days {
            switch day.state {
            case .qualified:
                currentRun.append(day)
                lastResolvedRun = currentRun
                if currentRun.count > longestRun.count {
                    longestRun = currentRun
                }
            case .failed:
                currentRun = []
                lastResolvedRun = []
            case .neutral:
                continue
            case .pending:
                currentRun = []
            }
        }

        return GardenCareStreakSummary(
            currentRun: lastResolvedRun.count,
            longestRun: longestRun.count,
            currentRunStart: lastResolvedRun.first?.dayStart,
            longestRunStart: longestRun.first?.dayStart,
            longestRunEnd: longestRun.last?.dayStart,
            currentRunOpportunityIDs: lastResolvedRun.flatMap(\.opportunityIDs),
            longestRunOpportunityIDs: longestRun.flatMap(\.opportunityIDs),
            // Coverage begins on the first day with at least one eligible
            // opportunity; days whose records are all excluded (archived
            // plants, active Quiet Periods) do not open coverage, and a
            // garden with only excluded records keeps the empty state.
            coverageStart: days.first(where: { !$0.opportunityIDs.isEmpty })?.dayStart,
            pendingDay: days.first(where: { $0.state == .pending && $0.dayStart <= now }),
            days: days
        )
    }

    private static func resolution(
        of opportunity: ScheduledCareOpportunitySnapshot,
        now: Date,
        eventByID: [UUID: ScheduledCareEventSnapshot],
        quietPeriods: [ScheduledCareQuietPeriodSnapshot],
        archivedPlantIDs: Set<UUID>
    ) throws -> Resolution {
        switch opportunity.statusRaw {
        case CareOpportunityStatus.cancelled.rawValue:
            return .excluded
        case CareOpportunityStatus.completed.rawValue:
            guard let eventID = opportunity.careEventID,
                  let event = eventByID[eventID],
                  event.taskID == opportunity.taskID,
                  event.plantID == opportunity.plantID else {
                throw ScheduledCareAnalyticsError.invalidCompletionLink(opportunity.id)
            }
            // A future-dated completion has not happened yet: the day stays
            // unresolved until the recorded completion instant arrives.
            guard event.completedAt <= now else { return .unresolved }
            return CareOpportunityEligibility.qualifiesForStreak(
                completedAt: event.completedAt,
                effectiveDueAt: opportunity.effectiveDueAt
            ) ? .onTime : .late
        case CareOpportunityStatus.open.rawValue:
            if archivedPlantIDs.contains(opportunity.plantID) {
                // Open outcomes are neutral while the plant is archived;
                // completed history stays attributed to its due day.
                return .excluded
            }
            if quietPeriods.contains(where: {
                $0.taskID == opportunity.taskID && $0.isActive(at: now)
            }) {
                // An active Quiet Period pauses the task: open opportunities
                // stay neutral until resume.
                return .excluded
            }
            // Left open past the shared inclusive deadline: the day fails
            // once resolved, and later completion cannot repair it.
            return CareOpportunityEligibility.gracePeriodHasExpired(
                now: now,
                effectiveDueAt: opportunity.effectiveDueAt
            ) ? .late : .unresolved
        default:
            throw ScheduledCareAnalyticsError.invalidOpportunityStatus(opportunity.id)
        }
    }
}
