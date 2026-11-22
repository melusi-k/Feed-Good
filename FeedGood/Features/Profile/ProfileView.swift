import SwiftUI
import SwiftData

/// Shared by all tab roots. Personal identity, streaks and account dates are not
/// invented: this first profile reads only the garden records already on device.
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Plant.createdAt) private var plants: [Plant]
    @Query private var careEvents: [CareEvent]
    @Query private var journalEntries: [JournalEntry]
    @ScaledMetric(relativeTo: .largeTitle) private var portraitSize = 84
    let openSettings: () -> Void

    private var summary: GardenProfileSummary {
        GardenProfileSummary(plants: plants, careEvents: careEvents, journalEntries: journalEntries)
    }

    private var version: String {
        let info = Bundle.main.infoDictionary ?? [:]
        let version = info["CFBundleShortVersionString"] as? String ?? "Unknown"
        let build = info["CFBundleVersion"] as? String ?? "Unknown"
        return "Version \(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: portraitSize, weight: .regular))
                            .foregroundStyle(FeedGoodTheme.leaf)
                            .accessibilityHidden(true)
                        Text("Your garden")
                            .font(.largeTitle.bold())
                            .fontDesign(.serif)
                            .accessibilityAddTraits(.isHeader)
                        Text("Your plants and the care you give them.")
                            .font(.subheadline)
                            .foregroundStyle(FeedGoodTheme.muted)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)

                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 12)], spacing: 12) {
                        stat(summary.plantCount, title: "Plants", id: "plants")
                        stat(summary.careEventCount, title: "Care records", id: "care")
                        stat(summary.journalEntryCount, title: "Journal entries", id: "journal")
                    }

                    VStack(alignment: .leading, spacing: 14) {
                        Text("ABOUT YOUR GARDEN")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(FeedGoodTheme.muted)
                            .accessibilityAddTraits(.isHeader)
                        VStack(alignment: .leading, spacing: 16) {
                            NavigationLink {
                                growingContext
                            } label: {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Growing context").font(.headline)
                                        Text("Notes from your plant profiles")
                                            .font(.subheadline)
                                            .foregroundStyle(FeedGoodTheme.muted)
                                    }
                                    Spacer(minLength: 8)
                                    Image(systemName: "chevron.right").accessibilityHidden(true)
                                }
                            }
                            .accessibilityIdentifier("profile.context")
                            Divider()
                            Button(action: openSettings) {
                                HStack {
                                    Label("App settings", systemImage: "slider.horizontal.3")
                                    Spacer(minLength: 8)
                                    Image(systemName: "arrow.up.forward").accessibilityHidden(true)
                                }
                                .font(.headline)
                            }
                            .accessibilityIdentifier("profile.settings")
                            Text("Appearance and journal archive tools stay in Settings. Care reminders are managed in each plant's care routine.")
                                .font(.footnote)
                                .foregroundStyle(FeedGoodTheme.muted)
                        }
                        .padding(20)
                        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
                    }

                    VStack(spacing: 6) {
                        Text("Feed Good").font(.headline)
                        Text(version).font(.caption)
                        Text("Profile uses your existing garden records. It doesn't create an account.")
                            .font(.footnote)
                            .multilineTextAlignment(.center)
                    }
                    .foregroundStyle(FeedGoodTheme.muted)
                    .frame(maxWidth: .infinity)
                }
                .padding(FeedGoodTheme.contentPadding)
            }
            .background(FeedGoodTheme.background)
            .feedGoodHeader("Profile")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("profile.done")
                }
            }
        }
        .tint(FeedGoodTheme.leaf)
        .presentationDragIndicator(.visible)
    }

    private func stat(_ value: Int, title: String, id: String) -> some View {
        VStack(spacing: 4) {
            Text(value, format: .number)
                .font(.title.bold())
                .fontDesign(.serif)
                .foregroundStyle(FeedGoodTheme.leaf)
            Text(title)
                .font(.caption)
                .foregroundStyle(FeedGoodTheme.muted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 76)
        .padding(8)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(value) \(title)")
        .accessibilityIdentifier("profile.stats.\(id)")
    }

    private var growingContext: some View {
        Group {
            if plants.isEmpty {
                ContentUnavailableView("No plants yet", systemImage: "leaf", description: Text("Add a plant in My Plants to start saving its growing context."))
            } else {
                List(plants) { plant in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(plant.name).font(.headline)
                        if !plant.species.isEmpty { Text(plant.species).font(.subheadline) }
                        Text(plant.notes.isEmpty ? "No notes saved for this plant." : plant.notes)
                            .font(.body)
                            .foregroundStyle(FeedGoodTheme.muted)
                    }
                    .padding(.vertical, 6)
                }
                .scrollContentBackground(.hidden)
            }
        }
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Growing context")
    }
}
