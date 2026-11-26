import Foundation
import Testing
@testable import FeedGood

struct ScheduledCareRefreshScheduleTests {
    private let plantID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private func opportunity(
        _ id: Int,
        due: Date,
        status: String = CareOpportunityStatus.open.rawValue,
        eventID: UUID? = nil
    ) -> ScheduledCareOpportunitySnapshot {
        ScheduledCareOpportunitySnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            taskID: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            plantID: plantID,
            effectiveDueAt: due,
            statusRaw: status,
            careEventID: eventID
        )
    }

    @Test func includesDueInstantAndGraceDeadlineForOpenOpportunities() {
        let now = date(1_800_000_000)
        let futureDue = now.addingTimeInterval(3_600)
        let alreadyDue = now.addingTimeInterval(-3_600)
        let transitions = ScheduledCareRefreshSchedule.transitions(
            after: now,
            opportunities: [
                opportunity(1, due: futureDue),
                opportunity(2, due: alreadyDue)
            ],
            events: []
        )
        // Grace deadlines tick one second past the inclusive boundary: the
        // window is still open at the exact deadline and flips right after.
        #expect(transitions == [
            futureDue,
            CareOpportunityEligibility.streakDeadline(for: alreadyDue).addingTimeInterval(1),
            CareOpportunityEligibility.streakDeadline(for: futureDue).addingTimeInterval(1)
        ])
    }

    @Test func omitsExpiredDeadlinesAndCancelledOpportunities() {
        let now = date(1_800_000_000)
        let longPastDue = now.addingTimeInterval(-3 * 86_400)
        let transitions = ScheduledCareRefreshSchedule.transitions(
            after: now,
            opportunities: [
                opportunity(1, due: longPastDue),
                opportunity(2, due: now.addingTimeInterval(3_600), status: CareOpportunityStatus.cancelled.rawValue)
            ],
            events: []
        )
        #expect(transitions.isEmpty)
    }

    @Test func includesFutureDatedCompletionInstantUntilItArrives() {
        let now = date(1_800_000_000)
        let due = now.addingTimeInterval(-3_600)
        let futureCompletion = now.addingTimeInterval(1_200)
        let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let event = ScheduledCareEventSnapshot(
            id: eventID,
            taskID: UUID(uuidString: "00000000-0000-0000-0000-000000000010")!,
            plantID: plantID,
            completedAt: futureCompletion
        )
        let before = ScheduledCareRefreshSchedule.transitions(
            after: now,
            opportunities: [
                opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: eventID)
            ],
            events: [event]
        )
        #expect(before == [futureCompletion])

        let atInstant = ScheduledCareRefreshSchedule.transitions(
            after: futureCompletion,
            opportunities: [
                opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: eventID)
            ],
            events: [event]
        )
        #expect(atInstant.isEmpty)
    }
}
