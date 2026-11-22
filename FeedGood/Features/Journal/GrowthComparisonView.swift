import SwiftUI
import SwiftData

/// A temporary side-by-side look at two journal photos from one plant. Nothing
/// is saved and nothing is inferred: dates and source observations stay visible
/// so any difference remains the user's to interpret.
struct GrowthComparisonView: View {
    let plant: Plant
    let selectedIDs: [UUID]
    @Query private var journalEntries: [JournalEntry]
    @State private var editing: JournalEntry?

    private var comparison: (earlier: JournalEntry, later: JournalEntry)? {
        let mine = journalEntries.filter { $0.plant?.id == plant.id && selectedIDs.contains($0.id) }
        return GrowthReview.comparison(mine)
    }

    var body: some View {
        ScrollView {
            if let comparison {
                VStack(alignment: .leading, spacing: 16) {
                    Text("\(plant.name), then and now")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(FeedGoodTheme.soil)
                    HStack(alignment: .top, spacing: 12) {
                        photoColumn(comparison.earlier, position: "Earlier")
                        photoColumn(comparison.later, position: "Later")
                    }
                    Text("Photos appear exactly as recorded, with their dates and sources. No measurement or health assessment is made from them.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(FeedGoodTheme.contentPadding)
            } else {
                ContentUnavailableView("A source observation was removed", systemImage: "photo.on.rectangle", description: Text("One of these photos or its journal entry is no longer there. Your other entries are untouched."))
                    .accessibilityIdentifier("growthCompare.missing")
            }
        }
        .background(FeedGoodTheme.background.ignoresSafeArea())
        .feedGoodHeader("Compare photos")
        .sheet(item: $editing) { JournalEditor(plants: [plant], entry: $0) }
    }

    private func photoColumn(_ entry: JournalEntry, position: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            if entry.photoData != nil {
                PlantPhotoView(photoData: entry.photoData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .accessibilityLabel("\(plant.name), \(position.lowercased()) photo, \(entry.date.formatted(date: .abbreviated, time: .omitted))")
            } else {
                Text("This observation no longer has a photo.")
                    .font(.caption).foregroundStyle(.secondary)
            }
            Text(position.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(FeedGoodTheme.muted)
            Text(entry.date.formatted(date: .abbreviated, time: .shortened))
                .font(.caption).foregroundStyle(.secondary)
            if let milestone = entry.milestone {
                Label(milestone.title, systemImage: "sparkle")
                    .font(.caption).foregroundStyle(FeedGoodTheme.leaf)
            }
            if !entry.note.isEmpty {
                Text(entry.note)
                    .font(.caption).foregroundStyle(.secondary).lineLimit(3)
            }
            Button("Open source observation") { editing = entry }
                .font(.callout)
                .accessibilityIdentifier("growthCompare.source.\(position.lowercased())")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("growthCompare.\(position.lowercased())")
    }
}
