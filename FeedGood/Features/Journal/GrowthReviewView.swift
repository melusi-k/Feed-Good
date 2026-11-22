import SwiftUI
import SwiftData

/// A per-plant visual review of journal photos: pick two observations and see
/// them side by side, exactly as recorded. Photos never leave the device and no
/// measurement, health score or diagnosis is derived from them.
struct GrowthReviewView: View {
    let plant: Plant
    @Query private var journalEntries: [JournalEntry]
    @State private var selectedIDs: [UUID] = []
    @State private var adding = false

    private var photos: [JournalEntry] {
        GrowthReview.entries(plantID: plant.id, from: journalEntries)
    }

    private var comparison: (earlier: JournalEntry, later: JournalEntry)? {
        GrowthReview.comparison(selectedIDs.compactMap { id in photos.first(where: { $0.id == id }) })
    }

    var body: some View {
        List {
            Section {
                Text("Photos from \(plant.name)'s journal, newest first. Pick two to compare them side by side, exactly as recorded.")
                    .font(.callout).foregroundStyle(.secondary)
            }
            if photos.isEmpty {
                ContentUnavailableView("No photos yet", systemImage: "photo.on.rectangle", description: Text("Add a photo to a journal observation and \(plant.name)'s changes will gather here. One photo is a fine start."))
                    .accessibilityIdentifier("growthReview.empty")
                Button { adding = true } label: {
                    Label("Add observation", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .accessibilityIdentifier("growthReview.emptyAdd")
            } else {
                if photos.count == 1 {
                    Text("One photo so far. When a second observation has a photo, you can compare them side by side.")
                        .font(.callout).foregroundStyle(.secondary)
                        .accessibilityIdentifier("growthReview.onePhoto")
                } else {
                    Text("Select two photos to compare.")
                        .font(.caption).foregroundStyle(.secondary)
                }
                ForEach(photos) { entry in
                    photoRow(entry, selectable: photos.count > 1)
                }
                if photos.count > 1 {
                    NavigationLink {
                        GrowthComparisonView(plant: plant, selectedIDs: selectedIDs)
                    } label: {
                        Label("Compare selected", systemImage: "rectangle.split.2x1")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(comparison == nil)
                    .accessibilityIdentifier("growthReview.compare")
                }
            }
        }
        .feedGoodCollectionMotion(value: photos.map(\.id))
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Growth review")
        .toolbar { Button("Add observation", systemImage: "plus") { adding = true }.accessibilityIdentifier("growthReview.add") }
        .sheet(isPresented: $adding) { JournalEditor(plants: [plant]) }
    }

    private func photoRow(_ entry: JournalEntry, selectable: Bool) -> some View {
        let selected = selectedIDs.contains(entry.id)
        return Button {
            guard selectable else { return }
            toggle(entry)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                PlantPhotoView(photoData: entry.photoData)
                    .frame(width: 64, height: 64)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .accessibilityLabel("\(plant.name) photo, \(entry.date.formatted(date: .abbreviated, time: .omitted))")
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(FeedGoodTheme.soil)
                    if let milestone = entry.milestone {
                        Label(milestone.title, systemImage: "sparkle")
                            .font(.caption).foregroundStyle(FeedGoodTheme.leaf)
                    }
                    if !entry.note.isEmpty {
                        Text(entry.note)
                            .font(.caption).foregroundStyle(.secondary).lineLimit(2)
                    }
                }
                Spacer()
                if selectable {
                    Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(selected ? FeedGoodTheme.leaf : FeedGoodTheme.muted)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("growthReview.row.\(entry.id.uuidString)")
    }

    private func toggle(_ entry: JournalEntry) {
        if let index = selectedIDs.firstIndex(of: entry.id) {
            selectedIDs.remove(at: index)
        } else {
            selectedIDs.append(entry.id)
            if selectedIDs.count > 2 { selectedIDs.removeFirst() }
        }
    }
}
