import SwiftUI
import SwiftData

struct PlantStoryView: View {
    let plant: Plant
    @Query private var careEvents: [CareEvent]
    @Query private var journalEntries: [JournalEntry]
    @Query private var quietPeriodSnapshots: [QuietPeriodTaskSnapshot]
    @State private var adding = false
    @State private var editing: JournalEntry?

    private var items: [PlantStoryItem] {
        PlantStory.items(
            plantID: plant.id,
            careEvents: careEvents,
            journalEntries: journalEntries,
            quietPeriodSnapshots: quietPeriodSnapshots
        )
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
            Section { PlantJournalPromptCard(plant: plant) }
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
                    case .quietPeriod(let snapshot):
                        Text(snapshot.taskTitleSnapshot).font(.subheadline.weight(.medium))
                        Text(quietPeriodDescription(snapshot))
                            .font(.callout).foregroundStyle(.secondary)
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
        // A plant change is labelled explicitly so it reads as a record of what the
        // person changed, never as care completed or a plant-health assessment.
        case .journal(let entry):
            if let change = entry.changeKind { return "Plant change: \(change.title)" }
            return entry.milestone?.title ?? "Journal observation"
        case .quietPeriod(let snapshot):
            switch snapshot.membershipStatusRaw {
            case QuietPeriodMembershipStatus.removed.rawValue: return "Quiet Period · removed task"
            case QuietPeriodMembershipStatus.disabled.rawValue: return "Quiet Period · disabled task"
            default:
                switch snapshot.quietPeriod?.statusRaw ?? QuietPeriodStatus.ended.rawValue {
                case QuietPeriodStatus.scheduled.rawValue: return "Quiet Period · scheduled task"
                case QuietPeriodStatus.active.rawValue: return "Quiet Period · paused task"
                case QuietPeriodStatus.cancelled.rawValue: return "Quiet Period · cancelled"
                default: return "Quiet Period · ended"
                }
            }
        }
    }

    private func kindIcon(_ item: PlantStoryItem) -> String {
        switch item {
        case .care: return "drop"
        case .journal(let entry):
            if entry.changeKind != nil { return "arrow.triangle.2.circlepath" }
            return entry.milestone == nil ? "book.closed" : "sparkle"
        case .quietPeriod: return "pause.circle"
        }
    }

    private func quietPeriodDescription(_ snapshot: QuietPeriodTaskSnapshot) -> String {
        switch snapshot.membershipStatusRaw {
        case QuietPeriodMembershipStatus.removed.rawValue: return "This task was removed from the care routine. Its Quiet Period history is retained."
        case QuietPeriodMembershipStatus.disabled.rawValue: return "This task was disabled and is no longer part of the Quiet Period."
        default: return "This task was included in a Quiet Period."
        }
    }
}
