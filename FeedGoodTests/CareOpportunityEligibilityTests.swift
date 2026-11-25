import Foundation
import Testing
@testable import FeedGood

struct CareOpportunityEligibilityTests {
    @Test func streakGraceWindowIncludesDueInstantAndExactTwentyFourHourDeadline() {
        let due = Date(timeIntervalSince1970: 1_800_000_000)
        let deadline = due.addingTimeInterval(24 * 60 * 60)

        #expect(CareOpportunityEligibility.qualifiesForStreak(
            completedAt: due,
            effectiveDueAt: due
        ))
        #expect(CareOpportunityEligibility.qualifiesForStreak(
            completedAt: deadline,
            effectiveDueAt: due
        ))
        #expect(!CareOpportunityEligibility.qualifiesForStreak(
            completedAt: deadline.addingTimeInterval(0.001),
            effectiveDueAt: due
        ))
        #expect(!CareOpportunityEligibility.qualifiesForStreak(
            completedAt: due.addingTimeInterval(-0.001),
            effectiveDueAt: due
        ))
        #expect(CareOpportunityEligibility.streakDeadline(for: due) == deadline)
        #expect(!CareOpportunityEligibility.gracePeriodHasExpired(now: deadline, effectiveDueAt: due))
        #expect(CareOpportunityEligibility.gracePeriodHasExpired(now: deadline.addingTimeInterval(0.001), effectiveDueAt: due))
    }
}
