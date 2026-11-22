import SwiftUI
import SwiftData

/// The living record for one plant: photo, identity and notes, with routes
/// to edit the profile or delete the plant (always confirmed).
struct PlantDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    @State private var showingEditor = false
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                PlantPhotoView(photoData: plant.photoData)
                    .frame(maxWidth: .infinity)
                    .frame(height: 260)
                    .clipShape(RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius, style: .continuous))
                    .accessibilityIdentifier("plantDetail.photo")

                VStack(alignment: .leading, spacing: 6) {
                    Text(plant.name)
                        .font(.system(size: 28, weight: .semibold, design: .serif))
                        .foregroundStyle(FeedGoodTheme.soil)
                        .accessibilityIdentifier("plantDetail.name")
                    Text(plant.species.isEmpty ? "Species not added yet" : plant.species)
                        .font(.subheadline)
                        .foregroundStyle(plant.species.isEmpty ? FeedGoodTheme.muted.opacity(0.8) : FeedGoodTheme.muted)
                }

                NavigationLink { PlantCareView(plant: plant) } label: {
                    Label("Care routine and history", systemImage: "drop")
                }
                .accessibilityIdentifier("plantDetail.care")

                NavigationLink { JournalView(plant: plant) } label: {
                    Label("Plant journal", systemImage: "book.closed")
                }
                .accessibilityIdentifier("plantDetail.journal")

                notesCard

                Label("Added \(plant.createdAt.formatted(date: .abbreviated, time: .omitted))", systemImage: "calendar")
                    .font(.caption)
                    .foregroundStyle(FeedGoodTheme.muted)

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
            Text("This permanently deletes \(plant.name), its photo and its notes. Care history and journal entries belong to the plant and are removed with it. This can't be undone.")
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

    private func deletePlant() {
        modelContext.delete(plant)
        dismiss()
    }
}
