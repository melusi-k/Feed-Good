import Foundation
import Testing
@testable import FeedGood

struct PlantScheduledCareAnalyticsTests {
    private let plantID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let otherPlantID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
    private let taskID = UUID(uuidString: "00000000-0000-0000-0000-000000000010")!

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(secondsFromGMT: 0)!
        value.firstWeekday = 2
        return value
    }

    private func opportunity(
        _ id: Int,
        taskID: UUID? = nil,
        plantID: UUID? = nil,
        due: Date,
        status: String = CareOpportunityStatus.open.rawValue,
        eventID: UUID? = nil
    ) -> ScheduledCareOpportunitySnapshot {
        ScheduledCareOpportunitySnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            taskID: taskID ?? self.taskID,
            plantID: plantID ?? self.plantID,
            effectiveDueAt: due,
            statusRaw: status,
            careEventID: eventID
        )
    }

    private func event(
        _ id: Int,
        taskID: UUID? = nil,
        plantID: UUID? = nil,
        completedAt: Date
    ) -> ScheduledCareEventSnapshot {
        ScheduledCareEventSnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            taskID: taskID ?? self.taskID,
            plantID: plantID ?? self.plantID,
            completedAt: completedAt
        )
    }

    @Test func separatesCompletedLateUnresolvedAndOverdueAndKeepsManualCareOutOfMetrics() throws {
        let due = date(1_800_000_000)
        let now = due.addingTimeInterval(2 * 86_400 + 0.001)
        let onTimeEventID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let lateEventID = UUID(uuidString: "00000000-0000-0000-0000-000000000102")!
        let opportunities = [
            opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: onTimeEventID),
            opportunity(2, due: due.addingTimeInterval(60), status: CareOpportunityStatus.completed.rawValue, eventID: lateEventID),
            opportunity(3, due: due.addingTimeInterval(86_400), status: CareOpportunityStatus.open.rawValue),
            opportunity(4, due: due.addingTimeInterval(2 * 86_400), status: CareOpportunityStatus.open.rawValue),
            opportunity(5, due: now.addingTimeInterval(86_400), status: CareOpportunityStatus.open.rawValue),
            opportunity(6, due: due, status: CareOpportunityStatus.cancelled.rawValue),
            opportunity(7, plantID: otherPlantID, due: due)
        ]
        let events = [
            ScheduledCareEventSnapshot(id: onTimeEventID, taskID: taskID, plantID: plantID, completedAt: due.addingTimeInterval(24 * 60 * 60)),
            ScheduledCareEventSnapshot(id: lateEventID, taskID: taskID, plantID: plantID, completedAt: due.addingTimeInterval(24 * 60 * 60 + 61)),
            event(103, completedAt: due.addingTimeInterval(300)) // Unlinked/manual care.
        ]
        let period = DateInterval(start: due, end: now.addingTimeInterval(86_400))

        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: period,
            now: now,
            calendar: calendar,
            opportunities: opportunities,
            events: events
        )

        #expect(summary.records.count == 4)
        #expect(summary.completedCount == 2)
        #expect(summary.completedOnTimeCount == 1)
        #expect(summary.completedLateCount == 1)
        #expect(summary.unresolvedCount == 1)
        #expect(summary.overdueCount == 1)
        #expect(summary.completionRate == (2.0 / 3.0))
        #expect(summary.records.allSatisfy { $0.taskID == taskID })
        #expect(summary.records.allSatisfy { $0.id != opportunities[4].id })
        #expect(summary.records.allSatisfy { $0.id != opportunities[5].id })
        #expect(summary.records.allSatisfy { $0.id != opportunities[6].id })
    }

    @Test func exactGraceDeadlineRemainsUnresolvedAndOneMillisecondLaterIsOverdue() throws {
        let due = date(1_800_000_000)
        let deadline = CareOpportunityEligibility.streakDeadline(for: due)
        let opportunities = [
            opportunity(1, due: due),
            opportunity(2, due: due.addingTimeInterval(1))
        ]
        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: due, end: due.addingTimeInterval(10)),
            now: deadline,
            calendar: calendar,
            opportunities: [opportunities[0]],
            events: []
        )
        #expect(summary.unresolvedCount == 1)
        #expect(summary.overdueCount == 0)

        let afterDeadline = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: due, end: due.addingTimeInterval(10)),
            now: deadline.addingTimeInterval(0.001),
            calendar: calendar,
            opportunities: [opportunities[0]],
            events: []
        )
        #expect(afterDeadline.unresolvedCount == 0)
        #expect(afterDeadline.overdueCount == 1)
        #expect(afterDeadline.completionRate == 0)
    }

    @Test func completedOutsideWindowIncludesBackdatedCorrectionWithoutCallingItOnTime() throws {
        let due = date(1_800_000_000)
        let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: due, end: due.addingTimeInterval(100)),
            now: due.addingTimeInterval(200),
            calendar: calendar,
            opportunities: [
                opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: eventID)
            ],
            events: [
                ScheduledCareEventSnapshot(id: eventID, taskID: taskID, plantID: plantID, completedAt: due.addingTimeInterval(-1))
            ]
        )
        #expect(summary.completedCount == 1)
        #expect(summary.completedOutsideWindowCount == 1)
        #expect(summary.completedOnTimeCount == 0)
        #expect(summary.completionRate == 1)
    }

    @Test func activeQuietPeriodMakesAllSelectedTaskOpportunitiesNeutralUntilResume() throws {
        let due = date(1_800_000_000)
        let quiet = ScheduledCareQuietPeriodSnapshot(
            taskID: taskID,
            plantID: plantID,
            startAt: due.addingTimeInterval(2 * 86_400)
        )
        let otherTaskID = UUID(uuidString: "00000000-0000-0000-0000-000000000020")!
        let opportunities = [
            opportunity(1, due: due), // Already past its grace deadline when the pause starts.
            opportunity(2, due: due.addingTimeInterval(2 * 86_400 + 1_500)),
            opportunity(3, taskID: otherTaskID, due: due.addingTimeInterval(2 * 86_400 + 1_500))
        ]
        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: due, end: due.addingTimeInterval(10 * 86_400)),
            now: due.addingTimeInterval(3 * 86_400),
            calendar: calendar,
            opportunities: opportunities,
            events: [],
            quietPeriods: [quiet]
        )
        #expect(summary.records.map(\.id) == [opportunities[2].id])
    }

    @Test func halfOpenPeriodIncludesStartAndExcludesEndWithStableOrdering() throws {
        let start = date(1_800_000_000)
        let end = start.addingTimeInterval(10)
        let laterID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!
        let earlierID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        let opportunities = [
            ScheduledCareOpportunitySnapshot(id: laterID, taskID: taskID, plantID: plantID, effectiveDueAt: start, statusRaw: "open", careEventID: nil),
            ScheduledCareOpportunitySnapshot(id: earlierID, taskID: taskID, plantID: plantID, effectiveDueAt: start, statusRaw: "open", careEventID: nil),
            opportunity(3, due: end)
        ]
        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: start, end: end),
            now: end,
            calendar: calendar,
            opportunities: opportunities,
            events: []
        )
        #expect(summary.records.map(\.id) == [earlierID, laterID])
    }

    @Test func invalidCompletionOwnershipFailsClosed() throws {
        let due = date(1_800_000_000)
        let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let badEvent = ScheduledCareEventSnapshot(
            id: eventID,
            taskID: taskID,
            plantID: otherPlantID,
            completedAt: due
        )
        let expectedID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        do {
            _ = try PlantScheduledCareAnalyticsSummary.calculate(
                plantID: plantID,
                period: DateInterval(start: due, end: due.addingTimeInterval(100)),
                now: due.addingTimeInterval(100),
                calendar: calendar,
                opportunities: [
                    opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: eventID)
                ],
                events: [badEvent]
            )
            Issue.record("Expected invalid completion ownership to fail closed.")
        } catch let error as ScheduledCareAnalyticsError {
            #expect(error == .invalidCompletionLink(expectedID))
        }
    }

    @Test func archivedPlantRetainsCompletedHistoryButExcludesOpenOutcomes() throws {
        let due = date(1_800_000_000)
        let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: due, end: due.addingTimeInterval(100)),
            now: due.addingTimeInterval(3 * 86_400),
            calendar: calendar,
            opportunities: [
                opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: eventID),
                opportunity(2, due: due.addingTimeInterval(1))
            ],
            events: [
                ScheduledCareEventSnapshot(id: eventID, taskID: taskID, plantID: plantID, completedAt: due)
            ],
            isArchived: true
        )
        #expect(summary.completedCount == 1)
        #expect(summary.records.count == 1)
        #expect(summary.records.first?.id == UUID(uuidString: "00000000-0000-0000-0000-000000000001")!)
        #expect(summary.unresolvedCount == 0)
        #expect(summary.overdueCount == 0)
    }

    @Test func futureDatedLinkedCompletionStaysOutOfCountsUntilItsCompletionInstant() throws {
        let due = date(1_800_000_000)
        let eventID = UUID(uuidString: "00000000-0000-0000-0000-000000000101")!
        let completionInstant = due.addingTimeInterval(3_600)
        let opportunities = [
            opportunity(1, due: due, status: CareOpportunityStatus.completed.rawValue, eventID: eventID)
        ]
        let events = [
            ScheduledCareEventSnapshot(id: eventID, taskID: taskID, plantID: plantID, completedAt: completionInstant)
        ]
        let period = DateInterval(start: due, end: due.addingTimeInterval(2 * 86_400))

        // Immediately before the recorded completion instant the correction
        // is neutral: no completed count, no numerator, no rate.
        let before = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: period,
            now: completionInstant.addingTimeInterval(-0.001),
            calendar: calendar,
            opportunities: opportunities,
            events: events
        )
        #expect(before.records.isEmpty)
        #expect(before.completedCount == 0)
        #expect(before.completionRate == nil)

        // At the exact completion instant it enters the completed outcomes.
        let atInstant = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: period,
            now: completionInstant,
            calendar: calendar,
            opportunities: opportunities,
            events: events
        )
        #expect(atInstant.records.count == 1)
        #expect(atInstant.completedCount == 1)
        #expect(atInstant.completedOnTimeCount == 1)
        #expect(atInstant.completionRate == 1)
    }

    @Test func singleLocalDaysSpanningDSTTransitionsAre23And25Hours() throws {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.firstWeekday = 2
        localCalendar.timeZone = TimeZone(identifier: "America/New_York")!

        // Spring-forward day: 23 elapsed hours, still one local calendar day.
        let springDay = try #require(localCalendar.dateInterval(
            of: .day,
            for: ISO8601DateFormatter().date(from: "2026-03-08T16:00:00Z")!
        ))
        #expect(springDay.duration == 23 * 3_600)
        #expect(localCalendar.dateComponents([.day], from: springDay.start, to: springDay.end).day == 1)
        #expect(localCalendar.component(.hour, from: springDay.start) == 0)
        #expect(localCalendar.component(.hour, from: springDay.end) == 0)

        // Fall-back day: 25 elapsed hours, still one local calendar day.
        let fallDay = try #require(localCalendar.dateInterval(
            of: .day,
            for: ISO8601DateFormatter().date(from: "2026-11-01T16:00:00Z")!
        ))
        #expect(fallDay.duration == 25 * 3_600)
        #expect(localCalendar.dateComponents([.day], from: fallDay.start, to: fallDay.end).day == 1)
        #expect(localCalendar.component(.hour, from: fallDay.start) == 0)
        #expect(localCalendar.component(.hour, from: fallDay.end) == 0)
    }

    @Test func zeroResolvedDenominatorDoesNotProduceCompletionRate() throws {
        let due = date(1_800_000_000)
        let summary = try PlantScheduledCareAnalyticsSummary.calculate(
            plantID: plantID,
            period: DateInterval(start: due, end: due.addingTimeInterval(10)),
            now: due.addingTimeInterval(10),
            calendar: calendar,
            opportunities: [opportunity(1, due: due)],
            events: []
        )
        #expect(summary.unresolvedCount == 1)
        #expect(summary.completionRate == nil)
    }

    @Test func selectedRangesUseCalendarDaysAndTwelveCalendarMonths() throws {
        let now = ISO8601DateFormatter().date(from: "2026-11-25T16:00:00Z")!
        let thirty = try #require(ScheduledCareAnalyticsRange.last30Days.period(now: now, calendar: calendar))
        let ninety = try #require(ScheduledCareAnalyticsRange.last90Days.period(now: now, calendar: calendar))
        let twelveMonths = try #require(ScheduledCareAnalyticsRange.last12Months.period(now: now, calendar: calendar))

        #expect(calendar.dateComponents([.day], from: thirty.start, to: thirty.end).day == 30)
        #expect(calendar.dateComponents([.day], from: ninety.start, to: ninety.end).day == 90)
        #expect(calendar.date(byAdding: .month, value: 12, to: twelveMonths.start) == calendar.startOfDay(for: now))
        #expect(calendar.component(.month, from: twelveMonths.start) == 11)
        #expect(calendar.component(.day, from: twelveMonths.start) == 25)
    }

    @Test func recentThirtyDaysUsesInjectedLocalCalendarBoundaries() throws {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.firstWeekday = 2
        localCalendar.timeZone = TimeZone(identifier: "America/New_York")!
        let now = ISO8601DateFormatter().date(from: "2026-03-15T16:00:00Z")!
        let period = try #require(
            PlantScheduledCareAnalyticsSummary.recent30Days(now: now, calendar: localCalendar)
        )
        #expect(localCalendar.component(.hour, from: period.start) == 0)
        #expect(localCalendar.component(.hour, from: period.end) == 0)
        #expect(localCalendar.dateComponents([.day], from: period.start, to: period.end).day == 30)
        #expect(localCalendar.timeZone.identifier == "America/New_York")
    }

    @Test func localCalendarPeriodsRespectSpringForwardAndFallBackDuration() throws {
        var localCalendar = Calendar(identifier: .gregorian)
        localCalendar.firstWeekday = 2
        localCalendar.timeZone = TimeZone(identifier: "America/New_York")!

        // Thirty local calendar days spanning spring-forward contain one
        // fewer elapsed hour than thirty fixed 24-hour periods.
        let springNow = ISO8601DateFormatter().date(from: "2026-03-15T16:00:00Z")!
        let spring = try #require(
            PlantScheduledCareAnalyticsSummary.recent30Days(now: springNow, calendar: localCalendar)
        )
        #expect(localCalendar.dateComponents([.day], from: spring.start, to: spring.end).day == 30)
        #expect(spring.end.timeIntervalSince(spring.start) == (30 * 86_400) - 3_600)
        #expect(localCalendar.component(.hour, from: spring.start) == 0)
        #expect(localCalendar.component(.hour, from: spring.end) == 0)

        // Thirty local calendar days spanning fall-back contain one
        // additional elapsed hour; the period remains thirty calendar days.
        let fallNow = ISO8601DateFormatter().date(from: "2026-11-02T17:00:00Z")!
        let fall = try #require(
            PlantScheduledCareAnalyticsSummary.recent30Days(now: fallNow, calendar: localCalendar)
        )
        #expect(localCalendar.dateComponents([.day], from: fall.start, to: fall.end).day == 30)
        #expect(fall.end.timeIntervalSince(fall.start) == (30 * 86_400) + 3_600)
        #expect(localCalendar.component(.hour, from: fall.start) == 0)
        #expect(localCalendar.component(.hour, from: fall.end) == 0)
    }

}
