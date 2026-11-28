import SwiftUI
import SwiftData
import UniformTypeIdentifiers

struct JournalArchiveSection: View {
    @Environment(\.modelContext) private var context
    @Query private var entries: [JournalEntry]
    @Query private var plants: [Plant]
    @Query private var careTasks: [CareTask]
    @Query private var careEvents: [CareEvent]
    @Query private var careOpportunities: [CareOpportunity]
    @Query private var quietPeriods: [QuietPeriod]
    @Query private var quietPeriodTaskSnapshots: [QuietPeriodTaskSnapshot]
    @Query private var tags: [PlantTag]
    @Query private var plantCheckIns: [PlantCheckIn]
    @State private var errorMessage: String?
    @State private var exporting = false
    @State private var importing = false
    @State private var archive: JournalArchiveDocument?
    @State private var statusMessage: String?
    @State private var pendingRecoveryData: Data?
    @State private var recoveryPreview: JournalArchivePreview?
    @State private var showingRecoveryConfirmation = false

    var body: some View {
        Group {
            if let statusMessage {
                Text(statusMessage)
                    .font(.callout)
                    .accessibilityIdentifier("journal.status")
            }
            Section("Local garden archive") {
                Text("Version 6 exports plant details and photos, care routines and history, scheduled-care opportunities, Quiet Period history, plus journal notes, photos and plant check-ins. It excludes app settings and notification permissions. Save the archive outside the app; it contains private text and photos.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .accessibilityIdentifier("journal.archiveScope")
                Button("Export garden data") { export() }
                    .accessibilityIdentifier("journal.export")
                Button("Recover garden data") { importing = true }
                    .accessibilityIdentifier("journal.recover")
                Text("Recovery adds missing records, recreates missing plants, skips identical records and rejects conflicting IDs before writing. Existing records are never overwritten. Versions 1–5 remain supported; older archives cannot contain check-in records.")
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
                let data = try Data(contentsOf: url)
                recoveryPreview = try JournalArchive.preview(data, context: context)
                pendingRecoveryData = data
                showingRecoveryConfirmation = true
            } catch {
                errorMessage = "Recovery preview failed: \(error.localizedDescription)"
            }
        }
        .confirmationDialog(
            "Review garden recovery",
            isPresented: $showingRecoveryConfirmation,
            titleVisibility: .visible
        ) {
            Button("Recover garden data", role: .destructive) { recoverPendingArchive() }
                .accessibilityIdentifier("journal.recover.confirm")
            Button("Cancel", role: .cancel) { clearPendingRecovery() }
        } message: {
            Text(recoveryPreview?.confirmationMessage ?? "Review the archive before recovering your garden.")
        }
    }

    private func export() {
        do {
            archive = JournalArchiveDocument(data: try JournalArchive.export(
                plants: plants,
                entries: entries,
                careTasks: careTasks,
                careEvents: careEvents,
                careOpportunities: careOpportunities,
                tags: tags,
                quietPeriods: quietPeriods,
                quietPeriodTaskSnapshots: quietPeriodTaskSnapshots,
                plantCheckIns: plantCheckIns
            ))
            exporting = true
        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
        }
    }

    private func recoverPendingArchive() {
        guard let data = pendingRecoveryData, let preview = recoveryPreview else { return }
        do {
            _ = try JournalArchive.recover(data, context: context)
            statusMessage = "Recovered \(preview.plantsToAdd) plants, \(preview.entriesToAdd) journal entries, \(preview.careTasksToAdd) care routines, \(preview.careEventsToAdd) care-history records, \(preview.careOpportunitiesToAdd) scheduled-care opportunities, \(preview.quietPeriodsToAdd) Quiet Periods, \(preview.quietPeriodSnapshotsToAdd) Quiet Period task snapshots and \(preview.plantCheckInsToAdd) plant check-ins. Existing records were kept."
        } catch {
            errorMessage = "Recovery failed: \(error.localizedDescription)"
        }
        clearPendingRecovery()
    }

    private func clearPendingRecovery() {
        pendingRecoveryData = nil
        recoveryPreview = nil
    }
}
