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

    private var visibleEntries: [JournalEntry] { entries.filter { plant == nil || $0.plant?.id == plant?.id } }

    var body: some View {
        List {
            if let plant {
                NavigationLink { PlantStoryView(plant: plant) } label: {
                    Label("Plant story: care and journal", systemImage: "clock.arrow.circlepath")
                }.accessibilityIdentifier("journal.story")
                PlantJournalPromptCard(plant: plant)
            }
            if plants.isEmpty {
                ContentUnavailableView("Your garden story starts here", systemImage: "book.closed", description: Text("Add a plant in My Plants, then keep its notes and photos here."))
            } else if visibleEntries.isEmpty {
                ContentUnavailableView("Remember a little moment", systemImage: "leaf", description: Text("Add a dated note, photo or milestone. Small changes count."))
            }
            ForEach(visibleEntries) { entry in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text(entry.plant?.name ?? "Plant unavailable").font(.headline)
                        Spacer()
                        Text(entry.date.formatted(date: .abbreviated, time: .shortened)).font(.caption).foregroundStyle(.secondary)
                    }
                    if let milestone = entry.milestone { Label(milestone.title, systemImage: "sparkle").font(.subheadline).foregroundStyle(FeedGoodTheme.leaf).accessibilityIdentifier("journal.milestoneLabel") }
                    if let change = entry.changeKind { Label("Plant change: \(change.title)", systemImage: "arrow.triangle.2.circlepath").font(.subheadline).foregroundStyle(FeedGoodTheme.leaf).accessibilityIdentifier("journal.changeLabel") }
                    if let photo = entry.photoData {
                        PlantPhotoView(photoData: photo).frame(maxWidth: .infinity).frame(height: 190).clipped().accessibilityLabel("Journal photo")
                    }
                    if !entry.note.isEmpty { Text(entry.note).fixedSize(horizontal: false, vertical: true) }
                    HStack {
                        Button("Edit") { editing = entry }.accessibilityIdentifier("journal.edit.\(entry.id)")
                        Spacer()
                        Button("Delete", role: .destructive) { deleting = entry }.accessibilityIdentifier("journal.delete.\(entry.id)")
                    }.buttonStyle(FeedGoodPressStyle())
                }.padding(.vertical, 6)
            }

        }
        .feedGoodCollectionMotion(value: visibleEntries.map(\.id))
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader(plant == nil ? "Journal" : "Plant journal", tab: plant == nil ? .journal : nil)
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
    }
}

struct JournalEditor: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let plants: [Plant]
    var entry: JournalEntry?
    @State private var selectedPlant: UUID?
    @State private var draft = JournalDraft()
    @State private var entryType: EntryType = .observation

    /// One record is one kind: a plain observation, a milestone or a plant change (PRD-018).
    enum EntryType: String, CaseIterable, Identifiable {
        case observation, milestone, change
        var id: String { rawValue }
        var title: String {
            switch self {
            case .observation: return "Observation"
            case .milestone: return "Milestone"
            case .change: return "Plant change"
            }
        }
    }
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
                Picker("Entry type", selection: $entryType) {
                    ForEach(EntryType.allCases) { Text($0.title).tag($0) }
                }.accessibilityIdentifier("journal.entryType")
                if entryType == .milestone {
                    Picker("Milestone", selection: $draft.milestone) {
                        Text("No milestone").tag(JournalMilestone?.none)
                        ForEach(JournalMilestone.allCases) { Text($0.title).tag(Optional($0)) }
                    }.accessibilityIdentifier("journal.milestone")
                }
                if entryType == .change {
                    Picker("Change", selection: $draft.changeKind) {
                        ForEach(PlantChangeKind.allCases) { Text($0.title).tag(Optional($0)) }
                    }.accessibilityIdentifier("journal.changeKind")
                    Text("A change you made, not something the plant did. It never changes care tasks or due dates.").font(.caption).foregroundStyle(.secondary)
                } else {
                    Text("Optional observation, not a plant-health assessment. Use a note for any other moment.").font(.caption).foregroundStyle(.secondary)
                }
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
            .feedGoodHeader(entry == nil ? "New journal entry" : "Edit journal entry")
            .interactiveDismissDisabled(importingPhoto)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(importingPhoto) }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.disabled(!draft.isValid || selectedPlant == nil || importingPhoto).accessibilityIdentifier("journal.save")
                }
            }
            .onAppear {
                selectedPlant = entry?.plant?.id ?? plants.first?.id
                if let entry {
                    draft = JournalDraft(date: entry.date, note: entry.note, photoData: entry.photoData, milestone: entry.milestone, changeKind: entry.changeKind)
                    entryType = entry.changeKind != nil ? .change : (entry.milestone != nil ? .milestone : .observation)
                }
            }
            .onChange(of: entryType) { _, type in
                if type == .change, draft.changeKind == nil { draft.changeKind = .movedLocation }
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
        // The type picker owns which structured kind applies; clear the other so one record stays one kind.
        var saving = draft
        switch entryType {
        case .observation: saving.milestone = nil; saving.changeKind = nil
        case .milestone: saving.changeKind = nil
        case .change: saving.milestone = nil; if saving.changeKind == nil { saving.changeKind = .movedLocation }
        }
        do { try JournalStore.save(saving, plant: plant, entry: entry, context: context); dismiss() }
        catch { errorMessage = "Couldn't save this entry. Your draft is kept here. Try again." }
    }
}
