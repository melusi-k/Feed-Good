import SwiftUI

/// An optional prompt card (PRD-019). It never blocks anything, keeps no score,
/// and answering starts an ordinary user-authored journal entry.
struct PlantJournalPromptCard: View {
    let plant: Plant
    var store = PlantJournalPromptStore()
    @State private var answering = false
    /// Bumped after any interaction so the card recomputes (and usually disappears).
    @State private var refresh = 0

    private var prompt: PlantJournalPrompt? {
        _ = refresh
        return PlantJournalPrompts.prompt(for: plant.id, on: .now, calendar: .current, state: store)
    }

    var body: some View {
        if let prompt {
            VStack(alignment: .leading, spacing: 10) {
                Label("A quiet prompt", systemImage: "text.quote")
                    .font(.subheadline.weight(.medium)).foregroundStyle(FeedGoodTheme.leaf)
                Text(prompt.text).fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("journalPrompt.text")
                Text("An optional idea, never a task.").font(.caption).foregroundStyle(.secondary)
                HStack {
                    Button("Answer in journal") {
                        store.recordInteraction(plantID: plant.id, day: PlantJournalPrompts.dayIndex(on: .now, calendar: .current))
                        answering = true
                    }.accessibilityIdentifier("journalPrompt.answer")
                    Spacer()
                    Menu {
                        Button("Skip for today") {
                            store.recordInteraction(plantID: plant.id, day: PlantJournalPrompts.dayIndex(on: .now, calendar: .current))
                            refresh += 1
                        }.accessibilityIdentifier("journalPrompt.skip")
                        Button("Show less often") {
                            store.dismiss(promptID: prompt.id, on: .now, calendar: .current)
                            store.recordInteraction(plantID: plant.id, day: PlantJournalPrompts.dayIndex(on: .now, calendar: .current))
                            refresh += 1
                        }.accessibilityIdentifier("journalPrompt.dismiss")
                    } label: { Text("Not now") }
                    .accessibilityIdentifier("journalPrompt.notNow")
                }.buttonStyle(FeedGoodPressStyle())
            }
            .padding(.vertical, 6)
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("journalPrompt.card")
            .sheet(isPresented: $answering) { JournalEditor(plants: [plant]) }
        }
    }
}
