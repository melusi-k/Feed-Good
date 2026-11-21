import SwiftUI
import SwiftData
import PhotosUI

/// Edits an existing plant's profile through a draft, so cancelling never
/// touches the stored record. Photos are picked with the system picker,
/// resized by PlantPhotoService and stored on-device only.
struct EditPlantView: View {
    @Environment(\.dismiss) private var dismiss

    let plant: Plant

    @State private var draft: PlantProfileDraft
    @State private var photoData: Data?
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showingPhotoError = false

    init(plant: Plant) {
        self.plant = plant
        _draft = State(initialValue: PlantProfileDraft(plant: plant))
        _photoData = State(initialValue: plant.photoData)
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
            }
            .navigationTitle("Edit plant")
            .navigationBarTitleDisplayMode(.inline)
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
        dismiss()
    }
}
