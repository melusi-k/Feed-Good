import SwiftUI
import SwiftData

struct PlantStoryView: View {
    let plant: Plant
    @Query private var careEvents: [CareEvent]
    @Query private var journalEntries: [JournalEntry]
    @State private var adding = false
    @State private var editing: JournalEntry?

    private var items: [PlantStoryItem] {
        PlantStory.items(plantID: plant.id, careEvents: careEvents, journalEntries: journalEntries)
    }

    var body: some View {
        List {
            Section {
                if let archivedAt = plant.archivedAt {
                    Label("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted)) · Not in active care", systemImage: "archivebox")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("story.archivedStatus")
                }
                Text("Care you've recorded and moments you've noticed, newest first. These are your records, not a plant-health assessment.")
                    .font(.callout).foregroundStyle(.secondary)
                NavigationLink("Open plant journal") { JournalView(plant: plant) }
                    .accessibilityIdentifier("story.journal")
                NavigationLink("Open growth review") { GrowthReviewView(plant: plant) }
                    .accessibilityIdentifier("story.growth")
            }
            if items.isEmpty {
                ContentUnavailableView("A story waiting to grow", systemImage: "leaf", description: Text("Record care in this plant's routine, or add an observation, photo or milestone."))
                    .accessibilityIdentifier("story.empty")
            }
            ForEach(items) { item in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Label(kindLabel(item), systemImage: kindIcon(item))
                            .font(.headline).foregroundStyle(FeedGoodTheme.leaf)
                        Spacer()
                        Text(item.date.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    switch item {
                    case .care(let event):
                        Text(event.taskTitle).font(.subheadline.weight(.medium))
                        if !event.note.isEmpty { Text(event.note).fixedSize(horizontal: false, vertical: true) }
                        if plant.archivedAt == nil {
                            NavigationLink("Open care routine and history") { PlantCareView(plant: plant) }
                                .font(.callout)
                        }
                    case .journal(let entry):
                        if let photo = entry.photoData {
                            PlantPhotoView(photoData: photo).frame(height: 190).clipped().accessibilityLabel("Journal photo")
                        }
                        if !entry.note.isEmpty { Text(entry.note).fixedSize(horizontal: false, vertical: true) }
                        Button("Edit observation") { editing = entry }
                            .font(.callout).accessibilityIdentifier("story.edit.\(entry.id)")
                    }
                }
                .padding(.vertical, 6)
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier("story.row.\(item.id)")
            }
        }
        .feedGoodCollectionMotion(value: items.map(\.id))
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Plant story")
        .toolbar { Button("Add observation", systemImage: "plus") { adding = true }.accessibilityIdentifier("story.add") }
        .sheet(isPresented: $adding) { JournalEditor(plants: [plant]) }
        .sheet(item: $editing) { JournalEditor(plants: [plant], entry: $0) }
    }

    private func kindLabel(_ item: PlantStoryItem) -> String {
        switch item {
        case .care: return "Recorded care"
        case .journal(let entry): return entry.milestone?.title ?? "Journal observation"
        }
    }
    private func kindIcon(_ item: PlantStoryItem) -> String {
        switch item {
        case .care: return "drop"
        case .journal(let entry): return entry.milestone == nil ? "book.closed" : "sparkle"
        }
    }
}
