import Foundation
import Testing
@testable import FeedGood

struct GardenReflectionTests {
    // firstWeekday is set explicitly: Calendar.locale does not reliably move
    // the week start on every platform, and the civil-week definition is what
    // these tests pin down.
    private func calendar(_ zone: String, firstWeekday: Int = 2) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: zone)!
        calendar.firstWeekday = firstWeekday
        return calendar
    }

    private func date(_ iso: String) -> Date { ISO8601DateFormatter().date(from: iso)! }

    private func plant(_ name: String) -> Plant { Plant(name: name) }

    private func care(_ title: String, _ iso: String, plant: Plant?) -> CareEvent {
        CareEvent(id: UUID(), taskID: UUID(), taskTitle: title, completedAt: date(iso), note: "", plant: plant ?? self.plant("Placeholder"))
    }

    private func journal(_ iso: String, plant: Plant, milestone: JournalMilestone? = nil, photo: Bool = false) -> JournalEntry {
        JournalEntry(
            id: UUID(),
            date: date(iso),
            note: "note",
            photoData: photo ? Data([0x01]) : nil,
            milestoneRaw: milestone?.rawValue,
            plant: plant
        )
    }

    // MARK: Week boundaries

    @Test func weekBoundariesFollowTheLocalCivilCalendar() {
        // Monday-start (en_ZA) vs Sunday-start (en_US) calendars put the same
        // Sunday morning instant in different weeks.
        let sunday = date("2026-11-22T08:00:00+02:00") // a Sunday in Johannesburg
        let mondayCal = calendar("Africa/Johannesburg", firstWeekday: 2)
        let sundayCal = calendar("Africa/Johannesburg", firstWeekday: 1)
        let mondayStart = GardenReflectionBuilder.weekInterval(for: sunday, calendar: mondayCal)
        let sundayStart = GardenReflectionBuilder.weekInterval(for: sunday, calendar: sundayCal)
        #expect(mondayStart.start != sundayStart.start)
        // Monday-start: Sunday 22 Nov belongs to the week that started Monday 16 Nov.
        #expect(mondayStart.start == mondayCal.date(from: DateComponents(year: 2026, month: 11, day: 16)))
        // Sunday-start: Sunday 22 Nov starts a new week.
        #expect(sundayStart.start == sundayCal.date(from: DateComponents(year: 2026, month: 11, day: 22)))
    }

    @Test func eventsAtTheWeekEdgesLandInsideOrOutsideExactly() {
        let cal = calendar("Africa/Johannesburg")
        let fern = plant("Fern")
        // Johannesburg weeks start Monday 00:00 local. Week of Mon 16 - Sun 22 Nov 2026.
        let mondayStart = care("Water", "2026-11-16T00:00:00+02:00", plant: fern)
        let sundayEnd = care("Water", "2026-11-22T23:59:59+02:00", plant: fern)
        let nextMonday = care("Water", "2026-11-23T00:00:00+02:00", plant: fern)
        let reflection = GardenReflectionBuilder.reflection(
            for: date("2026-11-18T12:00:00+02:00"),
            calendar: cal,
            careEvents: [mondayStart, sundayEnd, nextMonday],
            journalEntries: []
        )
        #expect(reflection.careCount == 2)
        #expect(reflection.weekStart == cal.date(from: DateComponents(year: 2026, month: 11, day: 16)))
    }

    @Test func dstTransitionWeekKeepsLocalMidnightBoundaries() {
        // America/New_York falls back on 1 Nov 2026: the week containing it is
        // 169 hours long, and its bounds are still local midnights.
        let cal = calendar("America/New_York", firstWeekday: 1)
        let during = date("2026-11-01T05:30:00Z") // 01:30 EDT, happens twice that night
        let week = GardenReflectionBuilder.weekInterval(for: during, calendar: cal)
        #expect(week.end.timeIntervalSince(week.start) == 169 * 3600)
        #expect(cal.component(.hour, from: week.start) == 0)
        #expect(cal.component(.hour, from: week.end) == 0)
    }

    // MARK: Determinism

    @Test func sameInputsProduceTheSameReflection() {
        let cal = calendar("Africa/Johannesburg")
        let fern = plant("Fern")
        let events = [care("Water", "2026-11-18T08:00:00+02:00", plant: fern)]
        let entries = [journal("2026-11-19T08:00:00+02:00", plant: fern, milestone: .newLeaf, photo: true)]
        let now = date("2026-11-20T12:00:00+02:00")
        let first = GardenReflectionBuilder.reflection(for: now, calendar: cal, careEvents: events, journalEntries: entries)
        let second = GardenReflectionBuilder.reflection(for: now, calendar: cal, careEvents: events, journalEntries: entries)
        #expect(first == second)
        #expect(first.prompt == GardenReflectionBuilder.prompt(forWeekStarting: first.weekStart, calendar: cal))
    }

    // MARK: Source accuracy

    @Test func countsAndMomentsMapToRealRecordsOnly() {
        let cal = calendar("Africa/Johannesburg")
        let fern = plant("Fern")
        let aloe = plant("Aloe")
        let inWeekCare = [
            care("Water", "2026-11-17T08:00:00+02:00", plant: fern),
            care("Mist", "2026-11-18T08:00:00+02:00", plant: aloe)
        ]
        let outOfWeek = care("Water", "2026-11-10T08:00:00+02:00", plant: fern)
        let entries = [journal("2026-11-19T08:00:00+02:00", plant: fern, milestone: .flowering, photo: true)]
        let reflection = GardenReflectionBuilder.reflection(
            for: date("2026-11-20T12:00:00+02:00"),
            calendar: cal,
            careEvents: inWeekCare + [outOfWeek],
            journalEntries: entries
        )
        #expect(reflection.careCount == 2)
        #expect(reflection.journalCount == 1)
        #expect(reflection.plantNames == ["Aloe", "Fern"])
        // The milestone moment wins first place and names its real record.
        #expect(reflection.moments.first?.kind == .milestone)
        #expect(reflection.moments.first?.title == "Flowering on Fern")
        #expect(reflection.moments.first?.hasPhoto == true)
        #expect(reflection.moments.first?.plantID == fern.id)
        // Every moment id carries the UUID of an existing record.
        let recordIDs = Set(inWeekCare.map { "care.\($0.id.uuidString)" } + entries.map { "journal.\($0.id.uuidString)" })
        #expect(reflection.moments.allSatisfy { recordIDs.contains($0.id) })
    }

    @Test func rebuildAfterEditsAndDeletionsReflectsCurrentRecords() {
        let cal = calendar("Africa/Johannesburg")
        let fern = plant("Fern")
        let entry = journal("2026-11-19T08:00:00+02:00", plant: fern)
        let now = date("2026-11-20T12:00:00+02:00")
        let before = GardenReflectionBuilder.reflection(for: now, calendar: cal, careEvents: [], journalEntries: [entry])
        #expect(before.journalCount == 1)
        let after = GardenReflectionBuilder.reflection(for: now, calendar: cal, careEvents: [], journalEntries: [])
        #expect(after.journalCount == 0)
        #expect(after.moments.isEmpty)
        #expect(after.isEmpty)
    }

    // MARK: Empty and quiet states

    @Test func emptyWeekIsNeutralAndStillOffersAPrompt() {
        let reflection = GardenReflectionBuilder.reflection(
            for: date("2026-11-20T12:00:00+02:00"),
            calendar: calendar("Africa/Johannesburg"),
            careEvents: [],
            journalEntries: []
        )
        #expect(reflection.isEmpty)
        #expect(reflection.careCount == 0)
        #expect(reflection.journalCount == 0)
        #expect(reflection.moments.isEmpty)
        #expect(GardenReflectionBuilder.prompts.contains(reflection.prompt))
    }

    @Test func noPhotoWeekStillShowsTextMoments() {
        let cal = calendar("Africa/Johannesburg")
        let fern = plant("Fern")
        let reflection = GardenReflectionBuilder.reflection(
            for: date("2026-11-20T12:00:00+02:00"),
            calendar: cal,
            careEvents: [care("Water", "2026-11-18T08:00:00+02:00", plant: fern)],
            journalEntries: [journal("2026-11-19T08:00:00+02:00", plant: fern)]
        )
        #expect(reflection.moments.count == 2)
        #expect(reflection.moments.allSatisfy { !$0.hasPhoto })
    }

    @Test func recordsWhosePlantIsGoneStayOutOfMomentsAndNames() {
        let cal = calendar("Africa/Johannesburg")
        let orphan = care("Water", "2026-11-18T08:00:00+02:00", plant: nil)
        orphan.plant = nil
        let reflection = GardenReflectionBuilder.reflection(
            for: date("2026-11-20T12:00:00+02:00"),
            calendar: cal,
            careEvents: [orphan],
            journalEntries: []
        )
        // The event exists, so it counts; it cannot navigate, so it is no moment.
        #expect(reflection.careCount == 1)
        #expect(reflection.moments.isEmpty)
        #expect(reflection.plantNames.isEmpty)
    }

    // MARK: Moment selection

    @Test func momentsRankMilestoneThenJournalThenCareNewestFirstCappedAtThree() {
        let cal = calendar("Africa/Johannesburg")
        let fern = plant("Fern")
        let events = [
            care("Water", "2026-11-17T08:00:00+02:00", plant: fern),
            care("Mist", "2026-11-18T08:00:00+02:00", plant: fern)
        ]
        let entries = [
            journal("2026-11-16T08:00:00+02:00", plant: fern),
            journal("2026-11-19T08:00:00+02:00", plant: fern, milestone: .newLeaf)
        ]
        let reflection = GardenReflectionBuilder.reflection(
            for: date("2026-11-20T12:00:00+02:00"),
            calendar: cal,
            careEvents: events,
            journalEntries: entries
        )
        #expect(reflection.moments.map(\.kind) == [.milestone, .journal, .care])
        #expect(reflection.moments.count == 3)
        // Within one kind, a photo beats no photo; otherwise newest first.
        let a = journal("2026-11-17T08:00:00+02:00", plant: fern, photo: true)
        let b = journal("2026-11-18T08:00:00+02:00", plant: fern)
        let ranked = GardenReflectionBuilder.reflection(
            for: date("2026-11-20T12:00:00+02:00"),
            calendar: cal,
            careEvents: [],
            journalEntries: [b, a]
        )
        #expect(ranked.moments.first?.hasPhoto == true)
    }

    // MARK: Dismissal

    @Test func dismissalIsScopedToOneWeekAndReversible() {
        let suite = "test.reflection.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let dismissal = GardenReflectionDismissal(defaults: defaults)
        let thisWeek = date("2026-11-16T00:00:00+02:00")
        let nextWeek = date("2026-11-23T00:00:00+02:00")
        #expect(dismissal.isDismissed(weekStart: thisWeek) == false)
        dismissal.dismiss(weekStart: thisWeek)
        #expect(dismissal.isDismissed(weekStart: thisWeek))
        #expect(dismissal.isDismissed(weekStart: nextWeek) == false)
        dismissal.reopen()
        #expect(dismissal.isDismissed(weekStart: thisWeek) == false)
    }
}
