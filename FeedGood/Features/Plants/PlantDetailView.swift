import SwiftUI
import SwiftData

/// The living record for one plant: photo, identity, growing context and notes.
struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false
    @State private var showingArchiveConfirmation = false
    @State private var showingRestoreConfirmation = false
    @State private var actionError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PlantPhotoView(photoData: plant.photoData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius, style: .continuous))
                    .accessibilityIdentifier("plantDetail.photo")

                if let archivedAt = plant.archivedAt {
                    Label("Archived \(archivedAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "archivebox")
                        .font(.callout.weight(.medium))
                        .foregroundStyle(FeedGoodTheme.muted)
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .accessibilityIdentifier("plantDetail.archivedStatus")
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(FeedGoodTheme.soil)
                        .accessibilityIdentifier("plantDetail.name")
                    Text(plant.species.isEmpty ? "Species not added yet" : plant.species)
                        .font(.subheadline)
                        .foregroundStyle(plant.species.isEmpty ? FeedGoodTheme.muted.opacity(0.8) : FeedGoodTheme.muted)
                }

                if plant.growingEnvironment != .unspecified || plant.lightCondition != .unspecified {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("GROWING CONTEXT")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(FeedGoodTheme.muted)
                        if plant.growingEnvironment != .unspecified {
                            Label(plant.growingEnvironment.title, systemImage: "house")
                        }
                        if plant.lightCondition != .unspecified {
                            Label(plant.lightCondition.title, systemImage: "sun.max")
                        }
                        Text("Based on your observations.")
                            .font(.caption)
                            .foregroundStyle(FeedGoodTheme.muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(17)
                    .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .accessibilityIdentifier("plantDetail.growingContext")
                }

                NavigationLink {
                    PlantScheduledCareAnalyticsView(plant: plant)
                } label: {
                    Label("Scheduled care", systemImage: "chart.bar")
                }
                .accessibilityIdentifier("plantDetail.scheduledCareAnalytics")

                NavigationLink {
                    PlantInsightsView(plant: plant)
                } label: {
                    Label("Plant insights", systemImage: "leaf")
                }
                .accessibilityIdentifier("plantDetail.insights")

                if plant.archivedAt == nil {
                    NavigationLink { CareRoutineReviewView(plant: plant) } label: {
                        Label("Review care routine", systemImage: "calendar.badge.clock")
                    }
                    .accessibilityIdentifier("plantDetail.routineReview")

                    NavigationLink { PlantCareView(plant: plant) } label: {
                        Label("Care routine and history", systemImage: "drop")
                    }
                    .accessibilityIdentifier("plantDetail.care")

                    NavigationLink { QuietPeriodView(plant: plant) } label: {
                        Label(
                            (plant.quietPeriods ?? []).contains {
                                $0.statusRaw == QuietPeriodStatus.active.rawValue ||
                                $0.statusRaw == QuietPeriodStatus.scheduled.rawValue
                            } ? "Manage Quiet Period" : "Quiet Period",
                            systemImage: "pause.circle"
                        )
                    }
                    .accessibilityIdentifier("plantDetail.quietPeriod")
                }

                NavigationLink { JournalView(plant: plant) } label: {
                    Label(plant.archivedAt == nil ? "Plant journal" : "Plant journal and story", systemImage: "book.closed")
                }
                .accessibilityIdentifier("plantDetail.journal")

                NavigationLink { GrowthReviewView(plant: plant) } label: {
                    Label("Growth review", systemImage: "photo.on.rectangle.angled")
                }
                .accessibilityIdentifier("plantDetail.growth")

                notesCard

                Label("Added \(plant.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(FeedGoodTheme.muted)

                if plant.archivedAt == nil {
                    Button {
                        showingArchiveConfirmation = true
                    } label: {
                        Label("Archive plant", systemImage: "archivebox")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FeedGoodPressStyle(surface: .bordered))
                    .accessibilityIdentifier("plantDetail.archive")
                } else {
                    Button {
                        showingRestoreConfirmation = true
                    } label: {
                        Label("Restore plant", systemImage: "arrow.uturn.backward")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(FeedGoodPressStyle(surface: .prominent))
                    .tint(FeedGoodTheme.leaf)
                    .accessibilityIdentifier("plantDetail.restore")
                }

                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Label("Delete plant", systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(FeedGoodPressStyle(surface: .bordered))
                .accessibilityIdentifier("plantDetail.delete")
            }
            .padding(FeedGoodTheme.contentPadding)
        }
        .background(FeedGoodTheme.background.ignoresSafeArea())
        .feedGoodHeader(plant.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
                    .accessibilityIdentifier("plantDetail.edit")
            }
        }
        .sheet(isPresented: $showingEditor) {
            EditPlantView(plant: plant)
        }
        .alert("Delete \(plant.name)?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) { deletePlant() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This permanently deletes \(plant.name), its photo and its notes. Care history, journal entries and plant check-ins belong to the plant and are removed with it. This can't be undone.")
        }
        .alert("Plant not updated", isPresented: Binding(get: { actionError != nil }, set: { if !$0 { actionError = nil } })) {
            Button("OK") { actionError = nil }
        } message: {
            Text(actionError ?? "")
        }
        .confirmationDialog("Archive \(plant.name)?", isPresented: $showingArchiveConfirmation, titleVisibility: .visible) {
            Button("Archive plant", role: .destructive) { archivePlant() }
                .accessibilityIdentifier("plantDetail.archive.confirm")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes the plant from your active collection and care reminders. Its story, photos and care history stay safe. You can restore it at any time.")
        }
        .confirmationDialog("Restore \(plant.name)?", isPresented: $showingRestoreConfirmation, titleVisibility: .visible) {
            Button("Restore plant") { restorePlant() }
                .accessibilityIdentifier("plantDetail.restore.confirm")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This returns the same plant and its existing records to your active collection. Eligible future reminders will be restored if notifications are allowed.")
        }
    }

    private var notesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES")
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(FeedGoodTheme.muted)
            if plant.notes.isEmpty {
                Text("No notes yet. Edit this plant to remember what makes it happy.")
                    .font(.system(size: 14))
                    .foregroundStyle(FeedGoodTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text(plant.notes)
                    .font(.system(size: 14))
                    .lineSpacing(3)
                    .foregroundStyle(FeedGoodTheme.soil)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(17)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .accessibilityIdentifier("plantDetail.notes")
    }

    private func archivePlant() {
        do {
            try PlantArchive.archive(plant, in: modelContext)
        } catch {
            actionError = "Couldn't archive \(plant.name). Nothing was changed. Try again."
        }
    }

    private func restorePlant() {
        do {
            try PlantArchive.restore(plant, in: modelContext)
        } catch {
            actionError = "Couldn't restore \(plant.name). It remains archived. Try again."
        }
    }

    private func deletePlant() {
        do {
            try CareOpportunityLifecycle.deleteAll(for: plant.id, in: modelContext)
            try PlantCheckInStore.deleteAll(for: plant.id, in: modelContext)
            modelContext.delete(plant)
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            actionError = "Couldn't delete \(plant.name). Nothing was removed. Try again."
        }
    }
}
