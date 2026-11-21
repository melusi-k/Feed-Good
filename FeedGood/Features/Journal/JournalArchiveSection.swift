import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct JournalArchiveSection: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [JournalEntry]
    @Query private var plants: [Plant]
    @Query private var careTasks: [CareTask]
    @Query private var careEvents: [CareEvent]
    @State private var errorMessage: String?
    @State private var exporting = false
    @State private var importing = false
    @State private var archive: JournalArchiveDocument?
    @State private var statusMessage: String?

    var body: some View {
        Group {
            if let statusMessage {
                Text(statusMessage)
                    .font(.callout)
                    .accessibilityIdentifier("journal.status")
            }
            Section("Local garden archive") {
                Text("Version 2 exports plant details and profile photos, care routines and history, plus journal notes and photos. It excludes app settings and notification permissions. Save the archive outside the app; it contains private text and photos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("journal.archiveScope")
                Button("Export garden data") { export() }
                    .accessibilityIdentifier("journal.export")
                Button("Recover garden data") { importing = true }
                    .accessibilityIdentifier("journal.recover")
                Text("Recovery adds missing records, recreates missing plants, skips identical records and rejects conflicting IDs before writing. Existing records are never overwritten. Version 1 journal archives remain supported.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("journal.recoveryPolicy")
            }
        }
        .alert("Garden archive", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK") { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
        .fileExporter(isPresented: $exporting, document: archive, contentType: .json, defaultFilename: "FeedGood-Garden") { result in
            switch result {
            case .success:
                statusMessage = "Garden data exported. Keep the archive somewhere safe outside the app."
            case .failure(let error):
                errorMessage = "Export failed: \(error.localizedDescription)"
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
                statusMessage = "Recovered \(count) journal entries and related garden records. Existing records were kept. Save a fresh export after reviewing your garden."
            } catch {
                errorMessage = "Recovery failed: \(error.localizedDescription)"
            }
        }
    }

    private func export() {
        do {
            archive = JournalArchiveDocument(data: try JournalArchive.export(
                plants: plants,
                entries: entries,
                careTasks: careTasks,
                careEvents: careEvents
            ))
            exporting = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}
