import SwiftUI
import SwiftData
import PhotosUI

/// Edits an existing plant's profile through a draft, so cancelling never
/// touches the stored record. Photos are picked with the system picker,
/// resized by PlantPhotoService and stored on-device only.
struct EditPlantView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let plant: Plant

    @State private var draft: PlantProfileDraft
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoError = false
    @State private var errorMessage: String?
    @State private var assignedTagIDs: Set<UUID>
    @State private var pendingTagNames: [String] = []
    @State private var newTagName = ""
    @Query(sort: \PlantTag.name) private var allTags: [PlantTag]

    init(plant: Plant) {
        self.plant = plant
        _draft = State(initialValue: PlantProfileDraft(plant: plant))
        _photoData = State(initialValue: plant.photoData)
        _assignedTagIDs = State(initialValue: Set((plant.tags ?? []).map(\.id)))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 16) {
                        PlantPhotoView(photoData: photoData)
                            .frame(width: 84, height: 84)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                            .accessibilityIdentifier("editPlant.photoPreview")
                        VStack(alignment: .leading, spacing: 8) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                Text(photoData == nil ? "Add photo" : "Replace photo")
                            }
                            .accessibilityIdentifier("editPlant.photoPicker")
                            if photoData != nil {
                                Button("Remove photo", role: .destructive) {
                                    photoData = nil
                                    selectedPhotoItem = nil
                                }
                                .accessibilityIdentifier("editPlant.removePhoto")
                            }
                        }
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Photo")
                } footer: {
                    Text("Photos are chosen with the system picker, resized and stored on this device only. No photo library permission is needed and nothing is uploaded.")
                }

                Section("Plant details") {
                    TextField("Plant name", text: $draft.name)
                        .accessibilityIdentifier("editPlant.name")
                    TextField("Species or variety (optional)", text: $draft.species)
                        .accessibilityIdentifier("editPlant.species")
                    TextField("Notes (optional)", text: $draft.notes, axis: .vertical)
                        .lineLimit(3...6)
                        .accessibilityIdentifier("editPlant.notes")
                }

                Section {
                    Picker("Where does it grow?", selection: $draft.growingEnvironment) {
                        ForEach(GrowingEnvironment.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .accessibilityIdentifier("editPlant.growingEnvironment")

                    Picker("Observed light", selection: $draft.lightCondition) {
                        ForEach(LightCondition.allCases) { option in
                            Text(option.title).tag(option)
                        }
                    }
                    .accessibilityIdentifier("editPlant.lightCondition")
                } header: {
                    Text("Growing context (optional)")
                } footer: {
                    Text("This helps us tailor plant care guidance to your plant’s growing conditions. These are your observations, not measurements. You can leave them unset or change them later. We do not need your location.")
                }
                Section {
                    ForEach(allTags) { tag in
                        Button {
                            if assignedTagIDs.contains(tag.id) { assignedTagIDs.remove(tag.id) } else { assignedTagIDs.insert(tag.id) }
                        } label: {
                            HStack {
                                Text(tag.name).foregroundStyle(.primary)
                                Spacer()
                                if assignedTagIDs.contains(tag.id) { Image(systemName: "checkmark").foregroundStyle(FeedGoodTheme.leaf) }
                            }
                        }
                        .accessibilityIdentifier("editPlant.tag.\(tag.name)")
                    }
                    ForEach(pendingTagNames, id: \.self) { name in
                        HStack {
                            Text(name)
                            Spacer()
                            Button("Remove", role: .destructive) { pendingTagNames.removeAll { $0 == name } }
                                .accessibilityIdentifier("editPlant.pendingTagRemove.\(name)")
                        }
                    }
                    HStack {
                        TextField("New tag", text: $newTagName)
                            .accessibilityIdentifier("editPlant.newTag")
                        Button("Add") {
                            let trimmed = PlantTagStore.trimmed(newTagName)
                            let key = PlantTagStore.normalized(newTagName)
                            if key.isEmpty == false,
                               allTags.contains(where: { $0.normalizedName == key }) == false,
                               pendingTagNames.contains(where: { PlantTagStore.normalized($0) == key }) == false {
                                pendingTagNames.append(trimmed)
                            }
                            newTagName = ""
                        }
                        .disabled(PlantTagStore.normalized(newTagName).isEmpty)
                        .accessibilityIdentifier("editPlant.addTag")
                    }
                } header: {
                    Text("Tags (optional)")
                } footer: {
                    Text("Tags are your own labels for finding plants, kept on this device. They are never tasks, folders or health categories.")
                }
                if let errorMessage {
                    Text(errorMessage)
                        .foregroundStyle(.red)
                        .accessibilityIdentifier("editPlant.error")
                }
            }
            .feedGoodHeader("Edit plant")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!draft.isValid)
                        .accessibilityIdentifier("editPlant.save")
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                guard let newItem else { return }
                Task { await importPhoto(from: newItem) }
            }
            .alert("That photo couldn't be used", isPresented: $showingPhotoError) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Try a different photo. Your current photo is unchanged.")
            }
        }
    }

    private func importPhoto(from item: PhotosPickerItem) async {
        do {
            guard let raw = try await item.loadTransferable(type: Data.self) else {
                showingPhotoError = true
                return
            }
            photoData = try PlantPhotoService.prepareForStorage(raw)
        } catch {
            showingPhotoError = true
        }
    }

    private func save() {
        draft.applying(to: plant)
        plant.photoData = photoData
        do {
            var assigned = allTags.filter { assignedTagIDs.contains($0.id) }
            for name in pendingTagNames {
                if let tag = try PlantTagStore.tag(named: name, context: modelContext),
                   assigned.contains(where: { $0.id == tag.id }) == false {
                    assigned.append(tag)
                }
            }
            plant.tags = assigned
            try modelContext.save()
            dismiss()
        } catch {
            modelContext.rollback()
            errorMessage = "Couldn't save these changes. The stored plant is unchanged. Try again."
        }
    }
}
