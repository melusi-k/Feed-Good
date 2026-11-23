import Foundation

/// An optional, bundled journal prompt (PRD-019). A prompt is never a task:
/// it carries no due date, streak, score or penalty, and skipping or dismissing
/// it changes nothing about the plant's care or journal.
struct PlantJournalPrompt: Identifiable, Equatable {
    let id: String
    let text: String
    let sourceTitle: String
    let review: DailyMoment.Review
    let reviewedOn: String
    let reviewedBy: String
}

/// Bundled, versioned prompt content with deterministic local selection.
/// No network, no account, no inspection of private journal text.
enum PlantJournalPrompts {
    static let contentVersion = 1

    static let prompts: [PlantJournalPrompt] = [
        make("new-growth", "Notice any new growth this week? Even a small leaf is worth a line."),
        make("light-today", "How is the light where this plant lives today? Brighter, dimmer or about the same?"),
        make("leaf-texture", "Touch a leaf gently. Does it feel firm, soft or different from last week?"),
        make("month-change", "What looks different about this plant compared to a month ago?"),
        make("better-spot", "Is there a spot in your home this plant might enjoy more?"),
        make("season-rhythm", "How does this plant's rhythm match the season outside?"),
        make("care-moment", "What did you do for this plant recently that you would do again?"),
        make("plant-story", "Does this plant have a story - where it came from, or how it joined your home?"),
        make("small-detail", "Pick one small detail: a stem, a vein, a new shoot. What do you notice?"),
        make("looking-forward", "What are you curious to see from this plant next?")
    ]

    private static func make(_ slug: String, _ text: String) -> PlantJournalPrompt {
        PlantJournalPrompt(id: "prompt.\(slug)", text: text,
                           sourceTitle: "Feed Good original prompt",
                           review: .editorialChecked, reviewedOn: "2026-11-23",
                           reviewedBy: "Assistant editorial check")
    }

    /// Deterministic prompt for a plant on a civil day, given the current prompt state.
    /// Returns nil when the plant already had a prompt interaction today or every
    /// prompt is inside its dismissal cooldown: the quiet state shows no card.
    static func prompt(for plantID: UUID, on date: Date, calendar: Calendar, state: PlantJournalPromptStore) -> PlantJournalPrompt? {
        guard !state.hasInteraction(plantID: plantID, day: dayIndex(on: date, calendar: calendar)) else { return nil }
        let eligible = prompts.filter { state.isEligible(promptID: $0.id, on: date, calendar: calendar) }
        guard !eligible.isEmpty else { return nil }
        // djb2 over a stable key: deterministic across launches, unlike Swift's seeded hash().
        let key = "\(plantID.uuidString)|\(dayIndex(on: date, calendar: calendar))"
        var hash: UInt64 = 5381
        for byte in key.utf8 { hash = (hash &* 33) &+ UInt64(byte) }
        return eligible[Int(hash % UInt64(eligible.count))]
    }

    /// Civil days since a fixed Gregorian anchor in the calendar's timezone,
    /// the same convention as DailyMoments: DST cannot skip or repeat a day.
    static func dayIndex(on date: Date, calendar: Calendar) -> Int {
        var civil = Calendar(identifier: .gregorian)
        civil.timeZone = calendar.timeZone
        let anchor = civil.date(from: DateComponents(year: 2000, month: 1, day: 1))!
        return civil.dateComponents([.day], from: anchor, to: civil.startOfDay(for: date)).day ?? 0
    }
}

/// Minimal local prompt state: dismissal dates per prompt ID and one interaction
/// day per plant. Presentation state only - never a duplicate answer store, never
/// journal content, excluded from archives.
struct PlantJournalPromptStore {
    /// A dismissed prompt is not resurfaced for 14 civil days, then becomes
    /// eligible again on its own. This is the documented cooldown and reset rule.
    static let cooldownDays = 14

    private static let dismissedKey = "feedGood.prompts.dismissed.v1"
    private static let interactionKey = "feedGood.prompts.interactions.v1"

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func isEligible(promptID: String, on date: Date, calendar: Calendar) -> Bool {
        guard let dismissedDay = dismissedDays()[promptID] else { return true }
        return dayDifference(from: dismissedDay, to: PlantJournalPrompts.dayIndex(on: date, calendar: calendar)) >= Self.cooldownDays
    }

    func hasInteraction(plantID: UUID, day: Int) -> Bool {
        interactions()[plantID.uuidString] == day
    }

    /// Skip or answer: no more prompt for this plant today. No penalty either way.
    func recordInteraction(plantID: UUID, day: Int) {
        var map = interactions()
        map[plantID.uuidString] = day
        defaults.set(map, forKey: Self.interactionKey)
    }

    /// "Show less often": this prompt id stays out of selection for the cooldown.
    func dismiss(promptID: String, on date: Date, calendar: Calendar) {
        var map = dismissedDays()
        map[promptID] = PlantJournalPrompts.dayIndex(on: date, calendar: calendar)
        defaults.set(map, forKey: Self.dismissedKey)
    }

    /// Reverses a dismissal; the prompt is eligible again immediately.
    func reopen(promptID: String) {
        var map = dismissedDays()
        map.removeValue(forKey: promptID)
        defaults.set(map, forKey: Self.dismissedKey)
    }

    private func dismissedDays() -> [String: Int] {
        defaults.dictionary(forKey: Self.dismissedKey) as? [String: Int] ?? [:]
    }

    private func interactions() -> [String: Int] {
        defaults.dictionary(forKey: Self.interactionKey) as? [String: Int] ?? [:]
    }

    private func dayDifference(from start: Int, to end: Int) -> Int { end - start }
}
