import Foundation
import Testing
@testable import FeedGood

struct DailyMomentsTests {
    private func calendar(_ zone: String, identifier: Calendar.Identifier = .gregorian) -> Calendar {
        var calendar = Calendar(identifier: identifier)
        calendar.timeZone = TimeZone(identifier: zone)!
        return calendar
    }

    private func date(_ iso: String) -> Date {
        ISO8601DateFormatter().date(from: iso)!
    }

    @Test func sameLocalDayHasSameContent() {
        let calendar = calendar("Africa/Johannesburg")
        let morning = date("2026-11-21T00:01:00+02:00")
        let evening = date("2026-11-21T23:59:00+02:00")
        #expect(DailyMoments.reflection(for: morning, calendar: calendar) == DailyMoments.reflection(for: evening, calendar: calendar))
        #expect(DailyMoments.tip(for: morning, calendar: calendar) == DailyMoments.tip(for: evening, calendar: calendar))
    }

    @Test func sevenUniqueDaysThenRepeatForBothLibraries() {
        let calendar = calendar("Africa/Johannesburg")
        let start = date("2026-12-29T12:00:00+02:00")
        let days = (0...7).map { calendar.date(byAdding: .day, value: $0, to: start)! }
        let reflections = days.map { DailyMoments.reflection(for: $0, calendar: calendar).id }
        let tips = days.map { DailyMoments.tip(for: $0, calendar: calendar).id }
        #expect(Set(reflections.prefix(7)).count == 7)
        #expect(Set(tips.prefix(7)).count == 7)
        #expect(reflections.first == reflections.last)
        #expect(tips.first == tips.last)
    }

    @Test func midnightLeapDayAndYearRolloverAdvanceExactlyOneItem() throws {
        let calendar = calendar("UTC")
        for pair in [
            ("2028-02-28T23:59:59Z", "2028-02-29T00:00:00Z"),
            ("2028-02-29T23:59:59Z", "2028-03-01T00:00:00Z"),
            ("2026-12-31T23:59:59Z", "2027-01-01T00:00:00Z")
        ] {
            let before = DailyMoments.tip(for: date(pair.0), calendar: calendar)
            let after = DailyMoments.tip(for: date(pair.1), calendar: calendar)
            let index = try #require(DailyMoments.tips.firstIndex(of: before))
            #expect(after == DailyMoments.tips[(index + 1) % 7])
        }
    }

    @Test func dstUsesCivilDaysAndNotElapsedHours() throws {
        let calendar = calendar("America/New_York")
        for start in ["2026-03-07T12:00:00-05:00", "2026-10-31T12:00:00-04:00"] {
            let dates = (0..<4).map { calendar.date(byAdding: .day, value: $0, to: date(start))! }
            let values = dates.map { DailyMoments.tip(for: $0, calendar: calendar) }
            for index in 1..<values.count {
                let previous = try #require(DailyMoments.tips.firstIndex(of: values[index - 1]))
                #expect(values[index] == DailyMoments.tips[(previous + 1) % 7])
            }
        }
    }

    @Test func timezoneIsLocalAndCalendarIdentifierDoesNotChangeSelection() {
        let instant = date("2026-11-21T00:30:00Z")
        let johannesburg = calendar("Africa/Johannesburg")
        let losAngeles = calendar("America/Los_Angeles")
        #expect(DailyMoments.tip(for: instant, calendar: johannesburg) != DailyMoments.tip(for: instant, calendar: losAngeles))
        #expect(DailyMoments.tip(for: instant, calendar: johannesburg) == DailyMoments.tip(for: instant, calendar: calendar("Africa/Johannesburg", identifier: .buddhist)))
        // The selector is total for dates outside the current content window.
        _ = DailyMoments.tip(for: date("1990-01-01T12:00:00Z"), calendar: johannesburg)
    }

    @Test func metadataIsCompleteAndKindsAreSeparated() {
        let all = DailyMoments.reflections + DailyMoments.tips
        #expect(Set(all.map(\.id)).count == 14)
        for moment in all {
            #expect(moment.text.isEmpty == false)
            #expect(moment.sourceTitle.isEmpty == false)
            #expect(moment.sourceSection.isEmpty == false)
            #expect(moment.reviewedOn.isEmpty == false)
            #expect(moment.reviewedBy.isEmpty == false)
        }
        #expect(DailyMoments.reflections.allSatisfy { $0.kind == .reflection && $0.review == .editorialChecked && $0.sourceURL == nil })
        #expect(DailyMoments.tips.allSatisfy { $0.kind == .careTip && $0.review == .sourceChecked && $0.sourceURL?.scheme == "https" })
    }

    @Test func emptyUnreviewedAndWrongKindLibrariesUseBundledFallback() {
        let now = date("2026-11-21T12:00:00Z")
        let calendar = calendar("UTC")
        let unchecked = DailyMoment(id: "unchecked", kind: .careTip, text: "Not approved for display", sourceTitle: "Test", sourceURL: nil, sourceSection: "Test", review: .needsReview, reviewedOn: "", reviewedBy: "")
        for library in [[], [unchecked], DailyMoments.reflections] {
            #expect(DailyMoments.select(from: library, kind: .careTip, for: now, calendar: calendar) == DailyMoments.tips[0])
        }
        #expect(DailyMoments.select(from: [], kind: .reflection, for: now, calendar: calendar) == DailyMoments.reflections[0])
    }
}
