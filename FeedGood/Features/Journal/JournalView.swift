import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers

struct JournalView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @Query(sort: \Plant.name) private var plants: [Plant]
    var plant: Plant? = nil
    @State private var adding = false
    @State private var editing: JournalEntry?
    @State private var deleting: JournalEntry?
    @State private var errorMessage: String?
    @State private var exporting = false
    @State private var importing = false
    @State private var archive: JournalArchiveDocument?
    @State private var statusMessage: String?

    private var visibleEntries: [JournalEntry] { entries.filter { plant == nil || $0.plant?.id == plant?.id } }

    var body: some View {
        List {
            if plants.isEmpty {
                ContentUnavailableView("Your garden story starts here", systemImage: "book.closed", description: Text("Add a plant in My Plants, then keep its notes and photos here."))
            } else if visibleEntries.isEmpty {
                ContentUnavailableView("Remember a little moment", systemImage: "leaf", description: Text("Add a dated note or photo. Small changes count."))
            }
            ForEach(visibleEntries) { entry in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(entry.plant?.name ?? "Plant unavailable").font(.headline)
                        Spacer()
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    }
                    if let photo = entry.photoData {
                        PlantPhotoView(photoData: photo).frame(maxWidth: .infinity).frame(height: 190).clipped().accessibilityLabel("Journal photo")
                    }
                    if !entry.note.isEmpty { Text(entry.note).fixedSize(horizontal: false, vertical: true) }
                    HStack {
                        Button("Edit") { editing = entry }.accessibilityIdentifier("journal.edit.\(entry.id)")
                        Spacer()
                        Button("Delete", role: .destructive) { deleting = entry }.accessibilityIdentifier("journal.delete.\(entry.id)")
                    }.buttonStyle(.borderless)
                }.padding(.vertical, 6)
            }
            if let statusMessage { Text(statusMessage).font(.callout).accessibilityIdentifier("journal.status") }
            if plant == nil {
                Section("Local journal archive") {
                    Text("Export includes all journal notes/photos and plant identity, not care records, profile photos or settings. Save outside the app before deletion. Archives contain private text and photos.").font(.caption).foregroundStyle(.secondary)
                    Button("Export journal") { export() }.accessibilityIdentifier("journal.export")
                    Button("Recover journal") { importing = true }.accessibilityIdentifier("journal.recover")
                    Text("Recovery adds missing entries, recreates missing plants and skips identical entries. Existing details are never overwritten. Conflicting IDs reject the import. Recovering an old archive can restore deleted entries.").font(.caption).foregroundStyle(.secondary)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .navigationTitle(plant == nil ? "Journal" : "Plant journal")
        .toolbar { Button("Add entry", systemImage: "plus") { adding = true }.disabled(plants.isEmpty).accessibilityIdentifier("journal.add") }
        .sheet(isPresented: $adding) { JournalEditor(plants: plant.map { [$0] } ?? plants) }
        .sheet(item: $editing) { JournalEditor(plants: plants, entry: $0) }
        .confirmationDialog("Delete this journal entry and its photo? This can't be undone. Exported archives are unchanged.", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible) {
            Button("Delete entry", role: .destructive) {
                guard let entry = deleting else { return }
                do { try JournalStore.delete(entry, context: context); deleting = nil }
                catch { deleting = nil; errorMessage = "Couldn't delete this entry. It has been kept. Try again." }
            }
        }
        .alert("Journal", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: { Text(errorMessage ?? "") }
        .fileExporter(isPresented: $exporting, document: archive, contentType: .json, defaultFilename: "FeedGood-Journal") { result in
            switch result {
            case .success: statusMessage = "Journal exported. Keep the archive somewhere safe outside the app."
            case .failure(let error): errorMessage = "Export failed: \(error.localizedDescription)"
            }
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                let url = try result.get()
                let access = url.startAccessingSecurityScopedResource()
                defer { if access { url.stopAccessingSecurityScopedResource() } }
                let size = try url.resourceValues(forKeys: [.fileSizeKey]).fileSize ?? 0
                guard size <= JournalArchive.maxBytes else { throw JournalArchiveError.tooLarge }
                let count = try JournalArchive.recover(Data(contentsOf: url), context: context)
                statusMessage = "Recovered \(count) entries. Existing entries were kept. Review your journal and save a fresh export."
            } catch { errorMessage = "Recovery failed: \(error.localizedDescription)" }
        }
    }

    private func export() {
        do { archive = JournalArchiveDocument(data: try JournalArchive.export(plants: plants, entries: entries)); exporting = true }
        catch { errorMessage = "Export failed: \(error.localizedDescription)" }
    }
}

struct JournalEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let plants: [Plant]
    var entry: JournalEntry?
    @State private var selectedPlant: UUID?
    @State private var draft = JournalDraft()
    @State private var photoItem: PhotosPickerItem?
    @State private var importingPhoto = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                if entry == nil {
                    Picker("Plant", selection: $selectedPlant) {
                        ForEach(plants) { Text($0.name).tag(Optional($0.id)) }
                    }.accessibilityIdentifier("journal.plant")
                } else { Text(entry?.plant?.name ?? "Plant unavailable") }
                DatePicker("Date", selection: $draft.date)
                TextField("What did you notice?", text: $draft.note, axis: .vertical).lineLimit(3...10).accessibilityIdentifier("journal.note")
                Section {
                    if let photo = draft.photoData { PlantPhotoView(photoData: photo).frame(height: 180).clipped() }
                    PhotosPicker(selection: $photoItem, matching: .images) { Text(draft.photoData == nil ? "Add photo" : "Replace photo") }
                        .disabled(importingPhoto).accessibilityIdentifier("journal.photo")
                    if draft.photoData != nil { Button("Remove photo", role: .destructive) { draft.photoData = nil; photoItem = nil } }
                    if importingPhoto { ProgressView("Preparing photo") }
                } footer: { Text("System photo picker, no library permission needed. Photos are resized and stored locally. Export an archive to keep a recovery copy outside the app.") }
                if let errorMessage { Text(errorMessage).foregroundStyle(.red).accessibilityIdentifier("journal.error") }
            }
            .navigationTitle(entry == nil ? "New journal entry" : "Edit journal entry")
            .interactiveDismissDisabled(importingPhoto)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(importingPhoto) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!draft.isValid || selectedPlant == nil || importingPhoto).accessibilityIdentifier("journal.save")
                }
            }
            .onAppear {
                selectedPlant = entry?.plant?.id ?? plants.first?.id
                if let entry { draft = JournalDraft(date: entry.date, note: entry.note, photoData: entry.photoData) }
            }
            .onChange(of: photoItem) { _, item in
                guard let item else { return }
                importingPhoto = true
                Task { @MainActor in
                    defer { importingPhoto = false }
                    do {
                        guard let data = try await item.loadTransferable(type: Data.self) else { throw PlantPhotoError.unreadableImage }
                        draft.photoData = try PlantPhotoService.prepareForStorage(data)
                    } catch { errorMessage = "Couldn't use that photo. Your previous photo is kept. Try another." }
                }
            }
        }
    }

    private func save() {
        guard let plant = plants.first(where: { $0.id == selectedPlant }) else { errorMessage = "Choose a plant before saving."; return }
        do { try JournalStore.save(draft, plant: plant, entry: entry, context: context); dismiss() }
        catch { errorMessage = "Couldn't save this entry. Your draft is kept here. Try again." }
    }
}
