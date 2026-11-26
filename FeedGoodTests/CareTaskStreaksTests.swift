import Foundation
import Testing
@testable import FeedGood

struct CareTaskStreaksTests {
    private let plantID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let taskID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!
    private let otherTaskID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private func opportunity(
        _ id: Int,
        taskID: UUID? = nil,
        due: Date,
        status: String = CareOpportunityStatus.open.rawValue,
        eventID: UUID? = nil
    ) -> ScheduledCareOpportunitySnapshot {
        ScheduledCareOpportunitySnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            taskID: taskID ?? self.taskID,
            plantID: plantID,
            effectiveDueAt: due,
            statusRaw: status,
            careEventID: eventID
        )
    }

    private func event(
        _ id: Int,
        taskID: UUID? = nil,
        completedAt: Date
    ) -> ScheduledCareEventSnapshot {
        ScheduledCareEventSnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            taskID: taskID ?? self.taskID,
            plantID: plantID,
            completedAt: completedAt
        )
    }

    private func completedPair(
        _ id: Int,
        due: TimeInterval,
        completedAt: TimeInterval
    ) -> (ScheduledCareOpportunitySnapshot, ScheduledCareEventSnapshot) {
        let eventID = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!
        return (
            opportunity(id, due: date(due), status: CareOpportunityStatus.completed.rawValue, eventID: eventID),
            event(id, completedAt: date(completedAt))
        )
    }

    private let day: TimeInterval = 86_400

    @Test func consecutiveOnTimeCompletionsBuildCurrentAndLongest() throws {
        let first = completedPair(1, due: 0, completedAt: 3600)
        let second = completedPair(2, due: 7 * day, completedAt: 7 * day + day)
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(8 * day),
            opportunities: [second.0, first.0],
            events: [first.1, second.1]
        )
        #expect(summary.currentStreak == 2)
        #expect(summary.longestStreak == 2)
        #expect(summary.currentRunOpportunityIDs == [first.0.id, second.0.id])
        #expect(summary.currentRunStart == date(0))
    }

    @Test func overdueAfterWindowBreaksCurrentStreakButKeepsLongest() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let second = completedPair(2, due: 7 * day, completedAt: 7 * day)
        let missed = opportunity(3, due: date(14 * day))
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(15 * day + 1),
            opportunities: [first.0, second.0, missed],
            events: [first.1, second.1]
        )
        #expect(summary.currentStreak == 0)
        #expect(summary.longestStreak == 2)
        #expect(summary.longestRunOpportunityIDs == [first.0.id, second.0.id])
        #expect(summary.longestRunStart == date(0))
        #expect(summary.longestRunEnd == date(7 * day))
    }

    @Test func lateCompletionDoesNotAdvanceOrRestoreStreak() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let late = completedPair(2, due: 7 * day, completedAt: 8 * day + 3600)
        let later = completedPair(3, due: 14 * day, completedAt: 14 * day)
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(15 * day),
            opportunities: [first.0, late.0, later.0],
            events: [first.1, late.1, later.1]
        )
        // The late completion ends the first run; the streak restarts from
        // the next on-time completion rather than being restored.
        #expect(summary.currentStreak == 1)
        #expect(summary.longestStreak == 1)
        #expect(summary.currentRunOpportunityIDs == [later.0.id])
    }

    @Test func unresolvedWithinWindowIsPendingAndDoesNotBreak() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let pending = opportunity(2, due: date(7 * day))
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(7 * day + 3600),
            opportunities: [first.0, pending],
            events: [first.1]
        )
        #expect(summary.currentStreak == 1)
        #expect(summary.longestStreak == 1)
    }

    @Test func cancelledOpportunityIsNeutral() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let cancelled = opportunity(2, due: date(7 * day), status: CareOpportunityStatus.cancelled.rawValue)
        let third = completedPair(3, due: 14 * day, completedAt: 14 * day)
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(15 * day),
            opportunities: [first.0, cancelled, third.0],
            events: [first.1, third.1]
        )
        #expect(summary.currentStreak == 2)
        #expect(summary.longestStreak == 2)
    }

    @Test func completionBeforeDueWindowDoesNotCount() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        // Recorded before the opportunity was due: completed care, but never
        // an on-time completion of that opportunity.
        let early = completedPair(2, due: 7 * day, completedAt: 6 * day)
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(15 * day),
            opportunities: [first.0, early.0],
            events: [first.1, early.1]
        )
        #expect(summary.currentStreak == 0)
        #expect(summary.longestStreak == 1)
    }

    @Test func opportunitiesFromOtherTasksNeverMerge() throws {
        let own = completedPair(1, due: 0, completedAt: 100)
        let foreign = completedPair(2, due: day, completedAt: day)
        let foreignOpportunity = ScheduledCareOpportunitySnapshot(
            id: foreign.0.id,
            taskID: otherTaskID,
            plantID: plantID,
            effectiveDueAt: foreign.0.effectiveDueAt,
            statusRaw: foreign.0.statusRaw,
            careEventID: foreign.0.careEventID
        )
        let foreignEvent = ScheduledCareEventSnapshot(
            id: foreign.1.id,
            taskID: otherTaskID,
            plantID: plantID,
            completedAt: foreign.1.completedAt
        )
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(2 * day),
            opportunities: [own.0, foreignOpportunity],
            events: [own.1, foreignEvent]
        )
        #expect(summary.currentStreak == 1)
        #expect(summary.currentRunOpportunityIDs == [own.0.id])
    }

    @Test func archivedTaskRetainsHistoryAndTreatsOpenOutcomesAsNeutral() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let openWhileArchived = opportunity(2, due: date(7 * day))
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(30 * day),
            opportunities: [first.0, openWhileArchived],
            events: [first.1],
            isArchived: true
        )
        #expect(summary.currentStreak == 1)
        #expect(summary.longestStreak == 1)
    }

    @Test func exactDeadlineCountsAndOneMillisecondLaterBreaks() throws {
        let onDeadline = completedPair(1, due: 0, completedAt: day)
        let atDeadline = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(2 * day),
            opportunities: [onDeadline.0],
            events: [onDeadline.1]
        )
        #expect(atDeadline.currentStreak == 1)

        let pastDeadline = completedPair(2, due: 0, completedAt: day + 0.001)
        let afterDeadline = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(2 * day),
            opportunities: [pastDeadline.0],
            events: [pastDeadline.1]
        )
        #expect(afterDeadline.currentStreak == 0)
    }

    @Test func completionWindowSpansDaylightSavingTransitionUnchanged() throws {
        // The 24-hour window is anchored to instants, not wall-clock days:
        // across the America/New_York spring-forward (a 23-hour local day)
        // the deadline is still exactly 86,400 seconds after the due instant.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let due = calendar.date(from: DateComponents(
            year: 2026, month: 3, day: 8, hour: 1, minute: 30
        ))!
        let onTime = completedPair(
            1,
            due: due.timeIntervalSince1970,
            completedAt: due.addingTimeInterval(86_400).timeIntervalSince1970
        )
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: due.addingTimeInterval(3 * 86_400),
            opportunities: [onTime.0],
            events: [onTime.1]
        )
        #expect(summary.currentStreak == 1)

        let missed = completedPair(
            2,
            due: due.timeIntervalSince1970,
            completedAt: due.addingTimeInterval(86_400 + 0.001).timeIntervalSince1970
        )
        let broken = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: due.addingTimeInterval(3 * 86_400),
            opportunities: [missed.0],
            events: [missed.1]
        )
        #expect(broken.currentStreak == 0)
    }

    @Test func activeQuietPeriodKeepsPastDeadlineOpportunityNeutral() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let paused = opportunity(2, due: date(7 * day))
        let quiet = ScheduledCareQuietPeriodSnapshot(
            taskID: taskID,
            plantID: plantID,
            startAt: date(6 * day)
        )
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(30 * day),
            opportunities: [first.0, paused],
            events: [first.1],
            quietPeriods: [quiet]
        )
        #expect(summary.currentStreak == 1)

        // Once the period ends, neutrality ends with it.
        let resumed = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(30 * day),
            opportunities: [first.0, paused],
            events: [first.1]
        )
        #expect(resumed.currentStreak == 0)
    }

    @Test func quietPeriodOnAnotherTaskDoesNotNeutralize() throws {
        let first = completedPair(1, due: 0, completedAt: 100)
        let missed = opportunity(2, due: date(7 * day))
        let foreignQuiet = ScheduledCareQuietPeriodSnapshot(
            taskID: otherTaskID,
            plantID: plantID,
            startAt: date(6 * day)
        )
        let summary = try CareTaskStreaks.calculate(
            taskID: taskID,
            now: date(30 * day),
            opportunities: [first.0, missed],
            events: [first.1],
            quietPeriods: [foreignQuiet]
        )
        #expect(summary.currentStreak == 0)
        #expect(summary.longestStreak == 1)
    }

    @Test func duplicateOpportunityFailsClosed() throws {
        let pair = completedPair(1, due: 0, completedAt: 100)
        #expect(throws: ScheduledCareAnalyticsError.self) {
            try CareTaskStreaks.calculate(
                taskID: taskID,
                now: date(2 * day),
                opportunities: [pair.0, pair.0],
                events: [pair.1]
            )
        }
    }

    @Test func mismatchedCompletionLinkFailsClosed() throws {
        let pair = completedPair(1, due: 0, completedAt: 100)
        let wrongTaskEvent = ScheduledCareEventSnapshot(
            id: pair.1.id,
            taskID: otherTaskID,
            plantID: plantID,
            completedAt: pair.1.completedAt
        )
        #expect(throws: ScheduledCareAnalyticsError.self) {
            try CareTaskStreaks.calculate(
                taskID: taskID,
                now: date(2 * day),
                opportunities: [pair.0],
                events: [wrongTaskEvent]
            )
        }
    }

    @Test func taskWithoutHistoryHasNoStreak() throws {
        let foreign = completedPair(1, due: 0, completedAt: 100)
        let summary = try CareTaskStreaks.calculate(
            taskID: otherTaskID,
            now: date(2 * day),
            opportunities: [foreign.0],
            events: [foreign.1]
        )
        #expect(summary.currentStreak == 0)
        #expect(summary.longestStreak == 0)
        #expect(summary.currentRunOpportunityIDs.isEmpty)
        #expect(summary.currentRunStart == nil)
    }
}
