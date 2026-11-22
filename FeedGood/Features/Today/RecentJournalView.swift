import SwiftUI
import SwiftData

struct RecentJournalView: View {
    @Query private var entries: [JournalEntry]
    @Binding var selectedTab: AppTab
    private var recent: [JournalEntry] { RecentJournal.entries(from: entries) }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            if recent.isEmpty {
                Button { selectedTab = .journal } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "book.closed").font(.title2)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("A little something to remember").font(.subheadline.weight(.semibold))
                            Text("What have you noticed in your garden lately?").font(.caption)
                        }
                        .multilineTextAlignment(.leading)
                        Spacer(minLength: 0)
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(FeedGoodPressStyle())
                .accessibilityIdentifier("today.journal.empty")
            } else {
                HStack {
                    Text("Recent journal moments").font(.system(size: 21, weight: .semibold, design: .serif))
                    Spacer()
                    Button("See all") { selectedTab = .journal }.font(.caption)
                        .accessibilityIdentifier("today.journal.all")
                }
                ForEach(recent) { entry in
                    if let plant = entry.plant {
                        NavigationLink { JournalView(plant: plant) } label: {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .firstTextBaseline) {
                                    Text(plant.name).font(.subheadline.weight(.semibold))
                                    Spacer()
                                    Text(entry.date.formatted(date: .abbreviated, time: .omitted)).font(.caption).foregroundStyle(FeedGoodTheme.muted)
                                }
                                if let milestone = entry.milestone {
                                    Label(milestone.title, systemImage: "sparkle").font(.caption.weight(.medium))
                                }
                                if !entry.note.isEmpty {
                                    Text(entry.note).font(.subheadline).lineLimit(3).multilineTextAlignment(.leading)
                                }
                                if let photo = entry.photoData {
                                    PlantPhotoView(photoData: photo).frame(height: 120).clipped().accessibilityLabel("Journal photo")
                                }
                                Label("Open plant journal", systemImage: "arrow.up.right").font(.caption)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 6)
                        }
                        .buttonStyle(FeedGoodPressStyle())
                        .accessibilityIdentifier("today.journal.entry.\(entry.id)")
                        if entry.id != recent.last?.id { Divider() }
                    }
                }
            }
        }
        .foregroundStyle(FeedGoodTheme.leaf)
        .padding(19)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
    }
}
