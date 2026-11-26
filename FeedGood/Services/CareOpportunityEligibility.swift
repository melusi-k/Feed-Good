import Foundation

/// Shared scheduled-care completion policy used by analytics and streaks.
/// Early/manual care is not an on-time completion of a future opportunity.
enum CareOpportunityEligibility {
    static let streakGracePeriod: TimeInterval = 24 * 60 * 60

    static func qualifiesForStreak(
        completedAt: Date,
        effectiveDueAt: Date
    ) -> Bool {
        completedAt >= effectiveDueAt &&
        completedAt <= effectiveDueAt.addingTimeInterval(streakGracePeriod)
    }

    static func streakDeadline(for effectiveDueAt: Date) -> Date {
        effectiveDueAt.addingTimeInterval(streakGracePeriod)
    }

    /// The grace period remains open through the exact deadline instant.
    static func gracePeriodHasExpired(now: Date, effectiveDueAt: Date) -> Bool {
        now > streakDeadline(for: effectiveDueAt)
    }
}
