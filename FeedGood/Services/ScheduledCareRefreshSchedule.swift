import Foundation

/// Deterministic instants at which displayed scheduled-care outcomes can
/// change while source records stay static. Drives `TimelineView(.explicit)`
/// so the screen re-evaluates exactly on a transition instead of polling.
enum ScheduledCareRefreshSchedule {
    /// The future transition instants, sorted ascending, for the given
    /// snapshots:
    /// - an open opportunity's due instant, when it becomes displayable;
    /// - one second past an open opportunity's inclusive 24-hour grace
    ///   deadline, when it flips from due to overdue;
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
                    // The window is inclusive through the exact deadline, so
                    // the outcome flips one second after it. Tick then rather
                    // than at the deadline itself, or an idle screen would
                    // keep showing due with no later transition scheduled.
                    dates.insert(deadline.addingTimeInterval(1))
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
