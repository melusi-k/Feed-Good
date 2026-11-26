import Foundation

/// Deterministic instants at which displayed scheduled-care outcomes can
/// change while source records stay static. Drives `TimelineView(.explicit)`
/// so the screen re-evaluates exactly on a transition instead of polling.
enum ScheduledCareRefreshSchedule {
    /// The future transition instants, sorted ascending, for the given
    /// snapshots:
    /// - an open opportunity's due instant, when it becomes displayable;
    /// - an open opportunity's inclusive 24-hour grace deadline, after which
    ///   it flips from due to overdue;
    /// - a linked completion's recorded instant while that completion is
    ///   still future-dated, when it enters the completed outcomes.
    static func transitions(
        after now: Date,
        opportunities: [ScheduledCareOpportunitySnapshot],
        events: [ScheduledCareEventSnapshot]
    ) -> [Date] {
        var eventByID: [UUID: ScheduledCareEventSnapshot] = [:]
        for event in events {
            eventByID[event.id] = event
        }

        var dates = Set<Date>()
        for opportunity in opportunities {
            switch opportunity.statusRaw {
            case CareOpportunityStatus.open.rawValue:
                if opportunity.effectiveDueAt > now {
                    // A not-yet-due opportunity appears once its due instant
                    // arrives.
                    dates.insert(opportunity.effectiveDueAt)
                }
                let deadline = CareOpportunityEligibility.streakDeadline(
                    for: opportunity.effectiveDueAt
                )
                if deadline > now {
                    // The window stays open through the exact deadline and
                    // the outcome flips to overdue immediately after.
                    dates.insert(deadline)
                }
            case CareOpportunityStatus.completed.rawValue:
                guard let eventID = opportunity.careEventID,
                      let event = eventByID[eventID],
                      event.completedAt > now else {
                    continue
                }
                // A future-dated linked completion enters the completed
                // outcomes at its recorded completion instant.
                dates.insert(event.completedAt)
            default:
                continue
            }
        }
        return dates.sorted()
    }
}
