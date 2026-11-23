import Foundation

/// One real moment from the user's week. Always backed by an existing
/// CareEvent or JournalEntry; nothing here is invented.
struct GardenReflectionMoment: Equatable, Identifiable {
    enum Kind: String, Equatable {
        case milestone
        case journal
        case care

        /// Milestones first, then plain journal notes, then care records.
        var rank: Int {
            switch self {
            case .milestone: return 0
            case .journal: return 1
            case .care: return 2
            }
        }
    }

    let id: String
    let kind: Kind
    let plantID: UUID
    let plantName: String
    let date: Date
    let title: String
    let hasPhoto: Bool
}

/// A derived look-back over the user's local civil-calendar week. Rebuilt from
/// current records on every render, so edits and deletions are respected.
struct WeeklyGardenReflection: Equatable {
    let weekStart: Date
    let weekEnd: Date
    let careCount: Int
    let journalCount: Int
    let plantNames: [String]
    let moments: [GardenReflectionMoment]
    let prompt: String

    var isEmpty: Bool { careCount == 0 && journalCount == 0 }
}

enum GardenReflectionBuilder {
    /// Gentle, optional observation prompts. No streaks, scores or pressure.
    static let prompts: [String] = [
        "Notice one small change on a plant this week.",
        "Look at the newest leaf you can find. What is it telling you?",
        "Touch the soil of one plant before deciding anything today.",
        "Find the plant you have not looked at closely in a while."
    ]

    /// The user's local civil-calendar week containing `date`. Calendar-driven,
    /// so locale first-weekday, time zone and DST are respected.
    static func weekInterval(for date: Date, calendar: Calendar) -> DateInterval {
        if let interval = calendar.dateInterval(of: .weekOfYear, for: date) {
            return interval
        }
        let start = calendar.startOfDay(for: date)
        return DateInterval(start: start, end: start)
    }

    /// Deterministic per week: the same week always offers the same prompt.
    static func prompt(forWeekStarting weekStart: Date, calendar: Calendar) -> String {
        let week = calendar.component(.weekOfYear, from: weekStart)
        return prompts[abs(week) % prompts.count]
    }

    /// Builds the reflection for the week containing `date`.
    ///
    /// Counts include every in-week CareEvent and JournalEntry. Moments and
    /// plant names only use records whose plant still exists, because each
    /// moment must navigate to a real plant.
    static func reflection(
        for date: Date,
        calendar: Calendar = .current,
        careEvents: [CareEvent],
        journalEntries: [JournalEntry]
    ) -> WeeklyGardenReflection {
        let week = weekInterval(for: date, calendar: calendar)
        // Half-open membership [start, end): DateInterval.contains is
        // inclusive of the end on some runtimes, which would count the first
        // instant of next week in this one.
        let weekCare = careEvents.filter { $0.completedAt >= week.start && $0.completedAt < week.end }
        let weekJournal = journalEntries.filter { $0.date >= week.start && $0.date < week.end }

        var names = Set<String>()
        var candidates: [GardenReflectionMoment] = []

        for event in weekCare {
            guard let plant = event.plant else { continue }
            names.insert(plant.name)
            candidates.append(GardenReflectionMoment(
                id: "care.\(event.id.uuidString)",
                kind: .care,
                plantID: plant.id,
                plantName: plant.name,
                date: event.completedAt,
                title: "\(event.taskTitle) recorded for \(plant.name)",
                hasPhoto: false
            ))
        }

        for entry in weekJournal {
            guard let plant = entry.plant else { continue }
            names.insert(plant.name)
            if let milestone = entry.milestone {
                candidates.append(GardenReflectionMoment(
                    id: "journal.\(entry.id.uuidString)",
                    kind: .milestone,
                    plantID: plant.id,
                    plantName: plant.name,
                    date: entry.date,
                    title: "\(milestone.title) on \(plant.name)",
                    hasPhoto: entry.photoData != nil
                ))
            } else {
                candidates.append(GardenReflectionMoment(
                    id: "journal.\(entry.id.uuidString)",
                    kind: .journal,
                    plantID: plant.id,
                    plantName: plant.name,
                    date: entry.date,
                    title: "A note on \(plant.name)",
                    hasPhoto: entry.photoData != nil
                ))
            }
        }

        let ranked = candidates.sorted { lhs, rhs in
            if lhs.kind != rhs.kind { return lhs.kind.rank < rhs.kind.rank }
            if lhs.hasPhoto != rhs.hasPhoto { return lhs.hasPhoto && !rhs.hasPhoto }
            if lhs.date != rhs.date { return lhs.date > rhs.date }
            return lhs.id < rhs.id
        }

        return WeeklyGardenReflection(
            weekStart: week.start,
            weekEnd: week.end,
            careCount: weekCare.count,
            journalCount: weekJournal.count,
            plantNames: names.sorted(),
            moments: Array(ranked.prefix(3)),
            prompt: prompt(forWeekStarting: week.start, calendar: calendar)
        )
    }
}

/// Remembers a dismissed week so the reflection card does not repeatedly
/// interrupt. Presentation state only: not garden history, excluded from any
/// archive, and reversible within the same week.
struct GardenReflectionDismissal {
    static let key = "feedGood.reflection.dismissedWeekStart"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isDismissed(weekStart: Date) -> Bool {
        defaults.string(forKey: Self.key) == Self.stamp(weekStart)
    }

    func dismiss(weekStart: Date) {
        defaults.set(Self.stamp(weekStart), forKey: Self.key)
    }

    /// Reverses a dismissal; the card returns for the current week.
    func reopen() {
        defaults.removeObject(forKey: Self.key)
    }

    private static func stamp(_ date: Date) -> String {
        "\(Int(date.timeIntervalSince1970))"
    }
}
