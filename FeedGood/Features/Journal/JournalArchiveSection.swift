import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct JournalArchiveSection: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [JournalEntry]
    @Query private var plants: [Plant]
    @State private var errorMessage: String?
    @State private var exporting = false
    @State private var importing = false
    @State private var archive: JournalArchiveDocument?
    @State private var statusMessage: String?

    var body: some View {
        Group {
            if let statusMessage { Text(statusMessage).font(.callout).accessibilityIdentifier("journal.status") }
                Section("Local journal archive") {
                    Text("Export includes all journal notes/photos and plant identity, not care records, profile photos or settings. Save outside the app before deletion. Archives contain private text and photos.").font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("journal.archiveScope")
                    Button("Export journal") { export() }.accessibilityIdentifier("journal.export")
                    Button("Recover journal") { importing = true }.accessibilityIdentifier("journal.recover")
                    Text("Recovery adds missing entries, recreates missing plants and skips identical entries. Existing details are never overwritten. Conflicting IDs reject the import. Recovering an old archive can restore deleted entries.").font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("journal.recoveryPolicy")
                }
        }
        .alert("Journal archive", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
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
