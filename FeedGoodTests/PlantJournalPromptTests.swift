import Foundation
import Testing
@testable import FeedGood

struct PlantJournalPromptTests {
    private let plant = UUID()
    private let otherPlant = UUID()
    private var calendar: Calendar { Calendar(identifier: .gregorian) }

    private func date(_ stamp: String) -> Date {
        let formatter = ISO8601DateFormatter()
        return formatter.date(from: stamp)!
    }

    private func store(_ suite: String = "test.prompts.\(UUID().uuidString)") -> (PlantJournalPromptStore, String) {
        (PlantJournalPromptStore(defaults: UserDefaults(suiteName: suite)!), suite)
    }

    @Test func bundledContentHasUniqueStableIDsAndProvenance() {
        let ids = PlantJournalPrompts.prompts.map(\.id)
        #expect(Set(ids).count == ids.count)
        #expect(ids.count >= 8)
        #expect(ids.allSatisfy { $0.hasPrefix("prompt.") })
        #expect(PlantJournalPrompts.prompts.allSatisfy {
            !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            !$0.sourceTitle.isEmpty && !$0.reviewedOn.isEmpty && !$0.reviewedBy.isEmpty
        })
        #expect(PlantJournalPrompts.contentVersion == 1)
        // No obligation language: prompts never mention streaks, scores or tasks.
        #expect(PlantJournalPrompts.prompts.allSatisfy {
            !$0.text.lowercased().contains("streak") && !$0.text.lowercased().contains("score") && !$0.text.lowercased().contains("task")
        })
    }

    @Test func selectionIsDeterministicForTheSameInputs() {
        let (state, suite) = store(); defer { UserDefaults().removePersistentDomain(forName: suite) }
        let day = date("2026-11-23T09:00:00+02:00")
        let first = PlantJournalPrompts.prompt(for: plant, on: day, calendar: calendar, state: state)
        let second = PlantJournalPrompts.prompt(for: plant, on: day, calendar: calendar, state: state)
        #expect(first != nil)
        #expect(first == second)
        // A different plant on the same day gets its own deterministic pick.
        let other = PlantJournalPrompts.prompt(for: otherPlant, on: day, calendar: calendar, state: state)
        #expect(other != nil)
        #expect(PlantJournalPrompts.prompt(for: otherPlant, on: day, calendar: calendar, state: state) == other)
    }

    @Test func skipOrAnswerHidesTheCardOnlyForThatPlantThatDay() {
        let (state, suite) = store(); defer { UserDefaults().removePersistentDomain(forName: suite) }
        let day = date("2026-11-23T09:00:00+02:00")
        let nextDay = date("2026-11-24T09:00:00+02:00")
        let dayIndex = PlantJournalPrompts.dayIndex(on: day, calendar: calendar)
        state.recordInteraction(plantID: plant, day: dayIndex)
        #expect(PlantJournalPrompts.prompt(for: plant, on: day, calendar: calendar, state: state) == nil)
        // The same interaction hides nothing for another plant, or for this plant tomorrow.
        #expect(PlantJournalPrompts.prompt(for: otherPlant, on: day, calendar: calendar, state: state) != nil)
        #expect(PlantJournalPrompts.prompt(for: plant, on: nextDay, calendar: calendar, state: state) != nil)
    }

    @Test func dismissedPromptStaysOutForFourteenCivilDaysThenReturns() {
        let (state, suite) = store(); defer { UserDefaults().removePersistentDomain(forName: suite) }
        let day = date("2026-11-23T09:00:00+02:00")
        let prompt = PlantJournalPrompts.prompts[0]
        state.dismiss(promptID: prompt.id, on: day, calendar: calendar)
        let inside = date("2026-12-06T09:00:00+02:00") // 13 days later
        #expect(state.isEligible(promptID: prompt.id, on: inside, calendar: calendar) == false)
        let boundary = date("2026-12-07T09:00:00+02:00") // exactly 14 civil days later
        #expect(state.isEligible(promptID: prompt.id, on: boundary, calendar: calendar))
        // Other prompts were never affected.
        #expect(state.isEligible(promptID: PlantJournalPrompts.prompts[1].id, on: inside, calendar: calendar))
        // Reopening reverses the dismissal immediately.
        state.dismiss(promptID: prompt.id, on: day, calendar: calendar)
        state.reopen(promptID: prompt.id)
        #expect(state.isEligible(promptID: prompt.id, on: inside, calendar: calendar))
    }

    @Test func dismissedPromptsAreExcludedFromSelectionUntilCooldownEnds() {
        let (state, suite) = store(); defer { UserDefaults().removePersistentDomain(forName: suite) }
        let day = date("2026-11-23T09:00:00+02:00")
        // Dismiss every prompt: selection returns nil (the quiet state), not a resurfaced prompt.
        for prompt in PlantJournalPrompts.prompts {
            state.dismiss(promptID: prompt.id, on: day, calendar: calendar)
        }
        #expect(PlantJournalPrompts.prompt(for: plant, on: day, calendar: calendar, state: state) == nil)
        // After the cooldown the same deterministic selection returns.
        let after = date("2026-12-08T09:00:00+02:00")
        #expect(PlantJournalPrompts.prompt(for: plant, on: after, calendar: calendar, state: state) != nil)
    }

    @Test func dayIndexUsesCivilGregorianDaysAcrossDSTBoundaries() {
        var zone = Calendar(identifier: .gregorian)
        zone.timeZone = TimeZone(identifier: "Africa/Johannesburg")!
        #expect(PlantJournalPrompts.dayIndex(on: date("2026-11-23T00:30:00+02:00"), calendar: zone) ==
                PlantJournalPrompts.dayIndex(on: date("2026-11-23T23:30:00+02:00"), calendar: zone))
        #expect(PlantJournalPrompts.dayIndex(on: date("2026-11-24T00:30:00+02:00"), calendar: zone) ==
                PlantJournalPrompts.dayIndex(on: date("2026-11-23T23:30:00+02:00"), calendar: zone) + 1)
    }
}
