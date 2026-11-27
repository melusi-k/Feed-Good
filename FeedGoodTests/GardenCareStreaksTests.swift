import Foundation
import Testing
@testable import FeedGood

struct GardenCareStreaksTests {
    private let plantA = UUID(uuidString: "00000000-0000-0000-0000-0000000000A1")!
    private let plantB = UUID(uuidString: "00000000-0000-0000-0000-0000000000B1")!
    private let taskA = UUID(uuidString: "00000000-0000-0000-0000-0000000000A2")!
    private let taskB = UUID(uuidString: "00000000-0000-0000-0000-0000000000B2")!

    private var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        return calendar
    }

    private let baseDay = Date(timeIntervalSince1970: 1_768_780_800) // 2026-01-19 00:00:00 UTC
    private let day: TimeInterval = 86_400
    private let grace: TimeInterval = 86_400

    private func midday(_ dayOffset: Int) -> Date {
        baseDay.addingTimeInterval(TimeInterval(dayOffset) * day + 12 * 3_600)
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
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", id))!,
            taskID: taskID ?? taskA,
            plantID: plantID ?? plantA,
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
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", id))!,
            taskID: taskID ?? taskA,
            plantID: plantID ?? plantA,
            completedAt: completedAt
        )
    }

    private func completedPair(
        _ id: Int,
        taskID: UUID? = nil,
        plantID: UUID? = nil,
        due: Date,
        completedAt: Date
    ) -> (ScheduledCareOpportunitySnapshot, ScheduledCareEventSnapshot) {
        let eventID = UUID(uuidString: String(format: "00000000-0000-0000-0000-%012X", id))!
        return (
            opportunity(
                id,
                taskID: taskID,
                plantID: plantID,
                due: due,
                status: CareOpportunityStatus.completed.rawValue,
                eventID: eventID
            ),
            event(id, taskID: taskID, plantID: plantID, completedAt: completedAt)
        )
    }

    @Test func allOpportunitiesOnTimeQualifiesDayAcrossPlantsAndTasks() throws {
        // Garden-wide qualification: every eligible opportunity due on the
        // day, across plants and care types, must complete on time.
        let first = completedPair(1, taskID: taskA, plantID: plantA, due: midday(0), completedAt: midday(0).addingTimeInterval(3_600))
        let second = completedPair(2, taskID: taskB, plantID: plantB, due: midday(0).addingTimeInterval(-6 * 3_600), completedAt: midday(0).addingTimeInterval(-6 * 3_600))
        let third = completedPair(3, taskID: taskA, plantID: plantA, due: midday(1), completedAt: midday(1))
        let summary = try GardenCareStreaks.calculate(
            now: midday(2),
            calendar: utcCalendar,
            opportunities: [third.0, first.0, second.0],
            events: [first.1, second.1, third.1]
        )
        #expect(summary.currentRun == 2)
        #expect(summary.longestRun == 2)
        #expect(summary.days.map(\.state) == [.qualified, .qualified])
        #expect(summary.days.first?.opportunityIDs == [second.0.id, first.0.id])
        #expect(summary.currentRunOpportunityIDs == [second.0.id, first.0.id, third.0.id])
        #expect(summary.currentRunStart == summary.days.first?.dayStart)
    }

    @Test func oneLateOrMissingCompletionFailsTheWholeDay() throws {
        let onTime = completedPair(1, taskID: taskA, plantID: plantA, due: midday(0), completedAt: midday(0))
        let late = completedPair(2, taskID: taskB, plantID: plantB, due: midday(0), completedAt: midday(0).addingTimeInterval(grace + 60))
        let summary = try GardenCareStreaks.calculate(
            now: midday(3),
            calendar: utcCalendar,
            opportunities: [onTime.0, late.0],
            events: [onTime.1, late.1]
        )
        #expect(summary.days.map(\.state) == [.failed])
        #expect(summary.currentRun == 0)
        #expect(summary.longestRun == 0)
    }

    @Test func completionAtExactGraceDeadlineIsOnTimeAndOneSecondAfterIsLate() throws {
        let exact = completedPair(1, due: midday(0), completedAt: midday(0).addingTimeInterval(grace))
        let onTime = try GardenCareStreaks.calculate(
            now: midday(3),
            calendar: utcCalendar,
            opportunities: [exact.0],
            events: [exact.1]
        )
        #expect(onTime.days.map(\.state) == [.qualified])

        let justAfter = completedPair(2, due: midday(0), completedAt: midday(0).addingTimeInterval(grace + 1))
        let late = try GardenCareStreaks.calculate(
            now: midday(3),
            calendar: utcCalendar,
            opportunities: [justAfter.0],
            events: [justAfter.1]
        )
        #expect(late.days.map(\.state) == [.failed])
    }

    @Test func openOpportunityInsideGraceKeepsDayPendingWithoutCounting() throws {
        let first = completedPair(1, due: midday(0), completedAt: midday(0))
        let waiting = opportunity(2, due: midday(1))
        // Now: midday of day 1 plus one hour; day 1's opportunity is open
        // and well inside its grace window.
        let summary = try GardenCareStreaks.calculate(
            now: midday(1).addingTimeInterval(3_600),
            calendar: utcCalendar,
            opportunities: [first.0, waiting],
            events: [first.1]
        )
        #expect(summary.days.map(\.state) == [.qualified, .pending])
        // The pending day is neither counted nor declared failed: the
        // current run still ends at the latest resolved qualifying day.
        #expect(summary.currentRun == 1)
        #expect(summary.pendingDay?.dayStart == summary.days.last?.dayStart)
        #expect(summary.pendingDay?.opportunityIDs == [waiting.id])
        #expect(summary.pendingDay?.pendingInWindowCount == 1)
        #expect(summary.pendingDay?.pendingNotYetDueCount == 0)
    }

    @Test func pendingDayDoesNotBridgeQualifyingRunsAcrossIt() throws {
        // A qualified day, then a day still waiting on its outcome, then
        // another qualified day: the run must not span the unresolved day.
        let first = completedPair(1, due: midday(0), completedAt: midday(0))
        // Due at 20:00 on day 1: still inside its window at midday day 2.
        let waiting = opportunity(2, due: midday(1).addingTimeInterval(8 * 3_600))
        let third = completedPair(3, due: midday(2), completedAt: midday(2))
        let summary = try GardenCareStreaks.calculate(
            now: midday(2).addingTimeInterval(3_600),
            calendar: utcCalendar,
            opportunities: [first.0, waiting, third.0],
            events: [first.1, third.1]
        )
        #expect(summary.days.map(\.state) == [.qualified, .pending, .qualified])
        // Pending is provisional, not neutral: day 2 starts a fresh run.
        #expect(summary.currentRun == 1)
        #expect(summary.longestRun == 1)
        #expect(summary.currentRunStart == summary.days.last?.dayStart)
    }

    @Test func notYetDueOpportunityKeepsItsDayFromResolvingEarly() throws {
        // Care due tonight must not let the day read as qualified at noon,
        // and must not fail it either.
        let tonight = opportunity(1, due: baseDay.addingTimeInterval(20 * 3_600))
        let summary = try GardenCareStreaks.calculate(
            now: baseDay.addingTimeInterval(9 * 3_600),
            calendar: utcCalendar,
            opportunities: [tonight],
            events: []
        )
        #expect(summary.days.map(\.state) == [.pending])
        #expect(summary.currentRun == 0)
        #expect(summary.pendingDay != nil)
        // Not-yet-due care is not inside its 24-hour window yet.
        #expect(summary.pendingDay?.pendingNotYetDueCount == 1)
        #expect(summary.pendingDay?.pendingInWindowCount == 0)
    }

    @Test func openOpportunityPastDeadlineFailsDayAndLaterCompletionCannotRepair() throws {
        let missed = opportunity(1, due: midday(0))
        let overdue = try GardenCareStreaks.calculate(
            now: midday(0).addingTimeInterval(grace + 60),
            calendar: utcCalendar,
            opportunities: [missed],
            events: []
        )
        #expect(overdue.days.map(\.state) == [.failed])
        #expect(overdue.currentRun == 0)

        // A completion recorded after the deadline leaves the day failed.
        let repaired = completedPair(2, due: midday(0), completedAt: midday(0).addingTimeInterval(grace + 120))
        let stillFailed = try GardenCareStreaks.calculate(
            now: midday(2),
            calendar: utcCalendar,
            opportunities: [repaired.0],
            events: [repaired.1]
        )
        #expect(stillFailed.days.map(\.state) == [.failed])
        #expect(stillFailed.currentRun == 0)
    }

    @Test func failedDayInterruptsRunAndLongestRunIsKept() throws {
        let first = completedPair(1, due: midday(0), completedAt: midday(0))
        let second = completedPair(2, due: midday(1), completedAt: midday(1))
        let missed = opportunity(3, due: midday(2))
        let third = completedPair(4, due: midday(3), completedAt: midday(3))
        let summary = try GardenCareStreaks.calculate(
            now: midday(4),
            calendar: utcCalendar,
            opportunities: [first.0, second.0, missed, third.0],
            events: [first.1, second.1, third.1]
        )
        #expect(summary.days.map(\.state) == [.qualified, .qualified, .failed, .qualified])
        #expect(summary.currentRun == 1)
        #expect(summary.longestRun == 2)
        #expect(summary.longestRunOpportunityIDs == [first.0.id, second.0.id])
        #expect(summary.longestRunStart == summary.days.first?.dayStart)
        #expect(summary.longestRunEnd == summary.days.dropFirst().first?.dayStart)
    }

    @Test func noOpportunityDaysAreNeutralAndSkippedWithoutBreakingARun() throws {
        // Qualifying days on day 0 and day 3: the empty days between them
        // neither advance nor break the run.
        let first = completedPair(1, due: midday(0), completedAt: midday(0))
        let second = completedPair(2, due: midday(3), completedAt: midday(3))
        let summary = try GardenCareStreaks.calculate(
            now: midday(4),
            calendar: utcCalendar,
            opportunities: [first.0, second.0],
            events: [first.1, second.1]
        )
        #expect(summary.days.count == 2)
        #expect(summary.currentRun == 2)
        #expect(summary.longestRun == 2)
    }

    @Test func cancelledOpportunitiesAreExcludedFromEligibility() throws {
        let first = completedPair(1, due: midday(0), completedAt: midday(0))
        let cancelled = opportunity(2, due: midday(1), status: CareOpportunityStatus.cancelled.rawValue)
        let second = completedPair(3, due: midday(2), completedAt: midday(2))
        let summary = try GardenCareStreaks.calculate(
            now: midday(4),
            calendar: utcCalendar,
            opportunities: [first.0, cancelled, second.0],
            events: [first.1, second.1]
        )
        // The cancelled-only day is not attributed at all.
        #expect(summary.days.count == 2)
        #expect(summary.currentRun == 2)
    }

    @Test func activeQuietPeriodKeepsOpenOpportunityNeutralUntilResume() throws {
        let first = completedPair(1, due: midday(0), completedAt: midday(0))
        let paused = opportunity(2, due: midday(1))
        let quiet = ScheduledCareQuietPeriodSnapshot(
            taskID: taskA,
            plantID: plantA,
            startAt: midday(0)
        )
        let summary = try GardenCareStreaks.calculate(
            now: midday(4),
            calendar: utcCalendar,
            opportunities: [first.0, paused],
            events: [first.1],
            quietPeriods: [quiet]
        )
        #expect(summary.days.map(\.state) == [.qualified, .neutral])
        #expect(summary.currentRun == 1)

        // Once the period is no longer active, the same records recompute:
        // the opportunity left open past its deadline now fails its day.
        let ended = ScheduledCareQuietPeriodSnapshot(
            taskID: taskA,
            plantID: plantA,
            startAt: midday(5)
        )
        let resumed = try GardenCareStreaks.calculate(
            now: midday(4),
            calendar: utcCalendar,
            opportunities: [first.0, paused],
            events: [first.1],
            quietPeriods: [ended]
        )
        #expect(resumed.days.map(\.state) == [.qualified, .failed])
        #expect(resumed.currentRun == 0)
    }

    @Test func archivedPlantOpenOpportunityIsNeutralButCompletedHistoryCounts() throws {
        // Day 0: completed on time before archive; remains attributed.
        let completed = completedPair(1, plantID: plantA, due: midday(0), completedAt: midday(0))
        // Day 1: the archived plant's open opportunity is neutral and must
        // not fail the day; the active plant's on-time care still qualifies it.
        let archivedOpen = opportunity(2, plantID: plantA, due: midday(1))
        let active = completedPair(3, taskID: taskB, plantID: plantB, due: midday(1), completedAt: midday(1))
        let summary = try GardenCareStreaks.calculate(
            now: midday(4),
            calendar: utcCalendar,
            opportunities: [completed.0, archivedOpen, active.0],
            events: [completed.1, active.1],
            archivedPlantIDs: [plantA]
        )
        #expect(summary.days.map(\.state) == [.qualified, .qualified])
        #expect(summary.currentRun == 2)
        #expect(summary.days.last?.opportunityIDs == [active.0.id])
    }

    @Test func futureDatedCompletionKeepsDayPendingUntilItsInstant() throws {
        let future = completedPair(1, due: midday(0), completedAt: midday(1))
        let pending = try GardenCareStreaks.calculate(
            now: midday(0).addingTimeInterval(3_600),
            calendar: utcCalendar,
            opportunities: [future.0],
            events: [future.1]
        )
        #expect(pending.days.map(\.state) == [.pending])

        // Once the recorded instant arrives the day resolves: the completion
        // is within the shared window, so the day qualifies.
        let resolved = try GardenCareStreaks.calculate(
            now: midday(2),
            calendar: utcCalendar,
            opportunities: [future.0],
            events: [future.1]
        )
        #expect(resolved.days.map(\.state) == [.qualified])
    }

    @Test func completionCorrectionAndDeletionRecomputeTheAffectedDay() throws {
        let late = completedPair(1, due: midday(0), completedAt: midday(0).addingTimeInterval(grace + 60))
        let failed = try GardenCareStreaks.calculate(
            now: midday(2),
            calendar: utcCalendar,
            opportunities: [late.0],
            events: [late.1]
        )
        #expect(failed.days.map(\.state) == [.failed])

        // A corrected completion time recomputes the day deterministically.
        let corrected = completedPair(2, due: midday(0), completedAt: midday(0).addingTimeInterval(3_600))
        let qualified = try GardenCareStreaks.calculate(
            now: midday(2),
            calendar: utcCalendar,
            opportunities: [corrected.0],
            events: [corrected.1]
        )
        #expect(qualified.days.map(\.state) == [.qualified])
        #expect(qualified.currentRun == 1)

        // Deleting the completion returns the opportunity to open; past its
        // deadline the day fails, with no history rewritten.
        let deleted = try GardenCareStreaks.calculate(
            now: midday(2),
            calendar: utcCalendar,
            opportunities: [opportunity(3, due: midday(0))],
            events: []
        )
        #expect(deleted.days.map(\.state) == [.failed])
    }

    @Test func coverageStartsAtFirstPersistedOpportunityAndNothingIsBackfilled() throws {
        let first = completedPair(1, due: midday(7), completedAt: midday(7))
        let summary = try GardenCareStreaks.calculate(
            now: midday(9),
            calendar: utcCalendar,
            opportunities: [first.0],
            events: [first.1]
        )
        // Days before the first persisted opportunity do not exist and are
        // never inferred.
        #expect(summary.coverageStart == summary.days.first?.dayStart)
        #expect(summary.days.count == 1)
        let empty = try GardenCareStreaks.calculate(
            now: midday(9),
            calendar: utcCalendar,
            opportunities: [],
            events: []
        )
        #expect(empty.coverageStart == nil)
        #expect(empty.currentRun == 0)
        #expect(empty.days.isEmpty)
    }

    @Test func coverageStartsAtFirstEligibleDayAndSkipsFullyExcludedDays() throws {
        // Day 0 holds only an archived plant's open opportunity: neutral,
        // and it must not open coverage.
        let archived = opportunity(1, plantID: plantA, due: midday(0))
        let eligible = completedPair(2, taskID: taskB, plantID: plantB, due: midday(1), completedAt: midday(1))
        let summary = try GardenCareStreaks.calculate(
            now: midday(3),
            calendar: utcCalendar,
            opportunities: [archived, eligible.0],
            events: [eligible.1],
            archivedPlantIDs: [plantA]
        )
        #expect(summary.days.map(\.state) == [.neutral, .qualified])
        #expect(summary.coverageStart == summary.days.last?.dayStart)

        // With only excluded records, coverage stays nil and the Profile
        // keeps its empty state instead of a misleading start date.
        let excludedOnly = try GardenCareStreaks.calculate(
            now: midday(3),
            calendar: utcCalendar,
            opportunities: [archived],
            events: [],
            archivedPlantIDs: [plantA]
        )
        #expect(excludedOnly.coverageStart == nil)
        #expect(excludedOnly.days.map(\.state) == [.neutral])
        #expect(excludedOnly.currentRun == 0)
    }

    @Test func halfOpenBoundariesAttributeEachOpportunityToExactlyOneDay() throws {
        let calendar = utcCalendar
        // One second before local midnight belongs to the previous day;
        // local midnight opens the next day.
        let beforeMidnight = completedPair(1, due: baseDay.addingTimeInterval(-1), completedAt: baseDay.addingTimeInterval(-1))
        let atMidnight = completedPair(2, due: baseDay, completedAt: baseDay)
        let summary = try GardenCareStreaks.calculate(
            now: midday(1),
            calendar: calendar,
            opportunities: [beforeMidnight.0, atMidnight.0],
            events: [beforeMidnight.1, atMidnight.1]
        )
        #expect(summary.days.count == 2)
        #expect(summary.days.first?.dayStart == baseDay.addingTimeInterval(-day))
        #expect(summary.days.last?.dayStart == baseDay)
        #expect(summary.days.first?.opportunityIDs == [beforeMidnight.0.id])
        #expect(summary.days.last?.opportunityIDs == [atMidnight.0.id])
    }

    @Test func daylightSavingShortAndLongDaysAreLocalCalendarDays() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!

        // 2026-03-08 is the 23-hour spring-forward day in New York.
        let shortDay = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8))!
        // Sub-second tolerance: DateInterval duration is Double arithmetic and
        // can drift below printed precision across the transition instant.
        #expect(abs((calendar.dateInterval(of: .day, for: shortDay)?.duration ?? 0) - 23 * 3_600) < 0.5)
        let earlySameDay = completedPair(1, due: calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 30))!, completedAt: calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 45))!)
        let lateSameDay = completedPair(2, due: calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 22, minute: 30))!, completedAt: calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 22, minute: 45))!)
        let before = completedPair(3, due: calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 23, minute: 30))!, completedAt: calendar.date(from: DateComponents(year: 2026, month: 3, day: 7, hour: 23, minute: 45))!)
        let summary = try GardenCareStreaks.calculate(
            now: calendar.date(from: DateComponents(year: 2026, month: 3, day: 12))!,
            calendar: calendar,
            opportunities: [earlySameDay.0, lateSameDay.0, before.0],
            events: [earlySameDay.1, lateSameDay.1, before.1]
        )
        // Both 01:30 and 22:30 on the short day attribute to that one local
        // day; 23:30 the night before stays on the 7th.
        #expect(summary.days.count == 2)
        #expect(summary.days.last?.opportunityIDs == [earlySameDay.0.id, lateSameDay.0.id])
        #expect(summary.currentRun == 2)

        // The grace window is anchored to instants, not wall-clock days:
        // exactly 86,400 seconds after a due instant on the 23-hour day is
        // still on time even though the local clock shows a different hour.
        let dueOnShortDay = calendar.date(from: DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 30))!
        let acrossTransition = completedPair(
            4,
            due: dueOnShortDay,
            completedAt: dueOnShortDay.addingTimeInterval(86_400)
        )
        let windowed = try GardenCareStreaks.calculate(
            now: dueOnShortDay.addingTimeInterval(3 * 86_400),
            calendar: calendar,
            opportunities: [acrossTransition.0],
            events: [acrossTransition.1]
        )
        #expect(windowed.days.map(\.state) == [.qualified])

        // 2026-11-01 is the 25-hour fall-back day.
        let longDay = calendar.date(from: DateComponents(year: 2026, month: 11, day: 1))!
        #expect(abs((calendar.dateInterval(of: .day, for: longDay)?.duration ?? 0) - 25 * 3_600) < 0.5)
        let onLongDay = completedPair(5, due: calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 3, minute: 30))!, completedAt: calendar.date(from: DateComponents(year: 2026, month: 11, day: 1, hour: 4, minute: 30))!)
        let longSummary = try GardenCareStreaks.calculate(
            now: calendar.date(from: DateComponents(year: 2026, month: 11, day: 4))!,
            calendar: calendar,
            opportunities: [onLongDay.0],
            events: [onLongDay.1]
        )
        #expect(longSummary.days.count == 1)
        #expect(longSummary.days.map(\.state) == [.qualified])
    }

    @Test func timeZoneChangeReattributesTheSameInstants() throws {
        // One instant, two local days: 2026-03-09T02:30Z is Monday the 9th
        // in UTC but still Sunday the 8th in New York.
        let instant = Date(timeIntervalSince1970: 1_773_023_400) // 2026-03-09 02:30 UTC
        let pair = completedPair(1, due: instant, completedAt: instant)
        let utcSummary = try GardenCareStreaks.calculate(
            now: instant.addingTimeInterval(day),
            calendar: utcCalendar,
            opportunities: [pair.0],
            events: [pair.1]
        )
        var nyCalendar = Calendar(identifier: .gregorian)
        nyCalendar.timeZone = TimeZone(identifier: "America/New_York")!
        let nySummary = try GardenCareStreaks.calculate(
            now: instant.addingTimeInterval(day),
            calendar: nyCalendar,
            opportunities: [pair.0],
            events: [pair.1]
        )
        #expect(utcSummary.days.first?.dayStart != nySummary.days.first?.dayStart)
        #expect(utcSummary.days.first?.state == .qualified)
        #expect(nySummary.days.first?.state == .qualified)
    }

    @Test func invalidSourceRecordsThrowInsteadOfGuessing() throws {
        let id = UUID(uuidString: "00000000-0000-0000-0000-000000000099")!
        let event = self.event(1, completedAt: midday(0))
        #expect(throws: ScheduledCareAnalyticsError.self) {
            try GardenCareStreaks.calculate(now: midday(1), calendar: utcCalendar, opportunities: [], events: [event, event])
        }
        let duplicated = opportunity(2, due: midday(0))
        #expect(throws: ScheduledCareAnalyticsError.self) {
            try GardenCareStreaks.calculate(now: midday(1), calendar: utcCalendar, opportunities: [duplicated, duplicated], events: [])
        }
        let brokenLink = opportunity(3, due: midday(0), status: CareOpportunityStatus.completed.rawValue, eventID: id)
        #expect(throws: ScheduledCareAnalyticsError.self) {
            try GardenCareStreaks.calculate(now: midday(1), calendar: utcCalendar, opportunities: [brokenLink], events: [])
        }
        let unknownStatus = opportunity(4, due: midday(0), status: "mystery")
        #expect(throws: ScheduledCareAnalyticsError.self) {
            try GardenCareStreaks.calculate(now: midday(1), calendar: utcCalendar, opportunities: [unknownStatus], events: [])
        }
    }

    @Test func largeHistoryCalculatesDeterministically() throws {
        // Two years of daily opportunities across two plants (730 days,
        // 1,460 records): full-history coverage with no truncation, sampling
        // or derived cache.
        let dayCount = 730
        var opportunities: [ScheduledCareOpportunitySnapshot] = []
        var events: [ScheduledCareEventSnapshot] = []
        opportunities.reserveCapacity(dayCount * 2)
        events.reserveCapacity(dayCount * 2)
        for offset in 0..<dayCount {
            let a = completedPair(10_000 + offset, taskID: taskA, plantID: plantA, due: midday(offset), completedAt: midday(offset))
            let b = completedPair(20_000 + offset, taskID: taskB, plantID: plantB, due: midday(offset).addingTimeInterval(-3_600), completedAt: midday(offset).addingTimeInterval(-3_600))
            opportunities.append(contentsOf: [a.0, b.0])
            events.append(contentsOf: [a.1, b.1])
        }
        let summary = try GardenCareStreaks.calculate(
            now: midday(dayCount + 1),
            calendar: utcCalendar,
            opportunities: opportunities,
            events: events
        )
        #expect(summary.days.count == dayCount)
        #expect(summary.days.allSatisfy { $0.state == .qualified })
        #expect(summary.currentRun == dayCount)
        #expect(summary.longestRun == dayCount)
        #expect(summary.currentRunOpportunityIDs.count == dayCount * 2)
        #expect(summary.coverageStart == summary.days.first?.dayStart)
        let lastDay = try #require(summary.days.last)
        #expect(lastDay.opportunityIDs.count == 2)
    }
}
