import Foundation
import SwiftData

/// Scoped SwiftData fetches for the scheduled-care analytics surface.
/// Keeps the read model off full-table materialisation: each consumer gets
/// only the records its calculation actually reads.
enum ScheduledCareAnalyticsFetch {
    /// Opportunities for the summary: the selected plant, from the selected
    /// period's start. Deliberately no upper bound: the exact half-open
    /// period filtering stays in the calculator, so a day rollover while the
    /// screen is open can never hide a newly due opportunity behind a stale
    /// fetch window.
    static func opportunitiesPredicate(plantID: UUID, periodStart: Date) -> Predicate<CareOpportunity> {
        #Predicate<CareOpportunity> {
            $0.plantID == plantID && $0.effectiveDueAt >= periodStart
        }
    }

    static func opportunities(plantID: UUID, periodStart: Date) -> FetchDescriptor<CareOpportunity> {
        FetchDescriptor(
            predicate: opportunitiesPredicate(plantID: plantID, periodStart: periodStart),
            sortBy: [SortDescriptor(\.effectiveDueAt)]
        )
    }

    /// Every opportunity for streak history: runs span any window, so the
    /// consistency read keeps the plant's full scheduled history.
    static func opportunityHistoryPredicate(plantID: UUID) -> Predicate<CareOpportunity> {
        #Predicate<CareOpportunity> { $0.plantID == plantID }
    }

    static func opportunityHistory(plantID: UUID) -> FetchDescriptor<CareOpportunity> {
        FetchDescriptor(
            predicate: opportunityHistoryPredicate(plantID: plantID),
            sortBy: [SortDescriptor(\.effectiveDueAt)]
        )
    }

    /// Events: linked completions can postdate their opportunity's period,
    /// and future-dated corrections must stay visible to the calculator
    /// until their recorded instant.
    static func eventsPredicate(plantID: UUID) -> Predicate<CareEvent> {
        #Predicate<CareEvent> { $0.plant?.id == plantID }
    }

    static func events(plantID: UUID) -> FetchDescriptor<CareEvent> {
        FetchDescriptor(
            predicate: eventsPredicate(plantID: plantID),
            sortBy: [SortDescriptor(\.completedAt)]
        )
    }

    /// Only active memberships can pause an opportunity; ended history never
    /// enters the read model.
    static func activeQuietMembershipsPredicate() -> Predicate<QuietPeriodTaskSnapshot> {
        let active = QuietPeriodMembershipStatus.active.rawValue
        return #Predicate<QuietPeriodTaskSnapshot> {
            $0.membershipStatusRaw == active
        }
    }

    static func activeQuietMemberships() -> FetchDescriptor<QuietPeriodTaskSnapshot> {
        FetchDescriptor(predicate: activeQuietMembershipsPredicate())
    }

    /// Care tasks for display titles; a deleted task's history keeps the
    /// existing "Removed care task" fallback.
    static func tasksPredicate(plantID: UUID) -> Predicate<CareTask> {
        #Predicate<CareTask> { $0.plant?.id == plantID }
    }

    static func tasks(plantID: UUID) -> FetchDescriptor<CareTask> {
        FetchDescriptor(predicate: tasksPredicate(plantID: plantID))
    }
}
