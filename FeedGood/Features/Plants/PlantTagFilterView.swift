import SwiftUI
import SwiftData

/// Optional tag filter chips (#75). OR semantics: selecting chips shows plants
/// carrying ANY selected tag; "Clear" returns to the unfiltered collection.
struct PlantTagFilterView: View {
    let tags: [PlantTag]
    @Binding var selectedTagIDs: Set<UUID>

    var body: some View {
        if tags.isEmpty == false {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(tags.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }) { tag in
                        Button {
                            if selectedTagIDs.contains(tag.id) { selectedTagIDs.remove(tag.id) } else { selectedTagIDs.insert(tag.id) }
                        } label: {
                            Text(tag.name)
                                .font(.callout)
                                .padding(.horizontal, 12).padding(.vertical, 6)
                                .background(selectedTagIDs.contains(tag.id) ? FeedGoodTheme.leaf.opacity(0.25) : FeedGoodTheme.background)
                                .clipShape(Capsule())
                                .overlay(Capsule().stroke(FeedGoodTheme.leaf, lineWidth: 1))
                        }
                        .accessibilityIdentifier("plants.tagFilter.\(tag.name)")
                    }
                    if selectedTagIDs.isEmpty == false {
                        Button("Clear") { selectedTagIDs.removeAll() }
                            .font(.callout)
                            .accessibilityIdentifier("plants.tagFilter.clear")
                    }
                    NavigationLink("Manage tags") { ManageTagsView() }
                        .font(.callout)
                        .accessibilityIdentifier("plants.tagFilter.manage")
                }
                .padding(.horizontal).padding(.vertical, 6)
            }
            .accessibilityElement(children: .contain)
            .accessibilityIdentifier("plants.tagFilter")
        }
    }
}

/// Rename or delete tags (#75). Deleting a tag never deletes a plant or a record.
struct ManageTagsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \PlantTag.name) private var tags: [PlantTag]
    @State private var renaming: PlantTag?
    @State private var renameText = ""
    @State private var deleting: PlantTag?
    @State private var errorMessage: String?

    var body: some View {
        List {
            if tags.isEmpty {
                ContentUnavailableView("No tags yet", systemImage: "tag", description: Text("Add tags from a plant's Edit screen. They stay on this device."))
            }
            ForEach(tags) { tag in
                HStack {
                    VStack(alignment: .leading) {
                        Text(tag.name)
                        Text("\((tag.plants ?? []).count) plant\((tag.plants ?? []).count == 1 ? "" : "s")")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button("Rename") { renaming = tag; renameText = tag.name }
                        .accessibilityIdentifier("tags.rename.\(tag.name)")
                    Button("Delete", role: .destructive) { deleting = tag }
                        .accessibilityIdentifier("tags.delete.\(tag.name)")
                }
            }
        }
        .feedGoodHeader("Manage tags")
        .alert("Rename tag", isPresented: Binding(get: { renaming != nil }, set: { if !$0 { renaming = nil } })) {
            TextField("Tag name", text: $renameText).accessibilityIdentifier("tags.renameField")
            Button("Save") {
                guard let tag = renaming else { return }
                do { try PlantTagStore.rename(tag, to: renameText, context: context); renaming = nil }
                catch { renaming = nil; errorMessage = "Couldn't rename this tag. Try again." }
            }.accessibilityIdentifier("tags.renameSave")
            Button("Cancel", role: .cancel) { renaming = nil }
        } message: {
            Text("If another tag already has this name, the two merge.")
        }
        .confirmationDialog("Delete this tag? Plants and their records are kept.", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete tag", role: .destructive) {
                guard let tag = deleting else { return }
                do { try PlantTagStore.delete(tag, context: context); deleting = nil }
                catch { deleting = nil; errorMessage = "Couldn't delete this tag. It has been kept. Try again." }
            }
        }
        .alert("Tags", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
    }
}
