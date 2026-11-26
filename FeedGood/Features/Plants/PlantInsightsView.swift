import SwiftUI
import SwiftData

/// A plant-scoped, read-only view of evidence-led insights derived only from
/// the user's own journal records. Statements describe what was recorded;
/// they are never a diagnosis, a health conclusion or a care judgement.
struct PlantInsightsView: View {
    let plant: Plant

    @Query private var journalEntries: [JournalEntry]

    /// nil when a record failed validation; the failure state is shown and
    /// no records are changed.
    private var insights: [PlantInsight]? {
        try? PlantInsights.insights(
            plantID: plant.id,
            entries: journalEntries.map(PlantInsightJournalSnapshot.init)
        )
    }

    var body: some View {
        List {
            Section {
                Text("These statements come only from your journal records for this plant. They describe what you recorded; they are not a plant-health or care score.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                if plant.archivedAt != nil {
                    Label("Archived plant · history is read-only", systemImage: "archivebox")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            if let insights {
                Section {
                    ForEach(insights) { insight in
                        NavigationLink {
                            if insight.kind == .changeOverTime && insight.isPhoto {
                                GrowthReviewView(plant: plant)
                            } else {
                                JournalView(plant: plant)
                            }
                        } label: {
                            insightRow(insight)
                        }
                        .accessibilityIdentifier("plantInsights.insight.\(insight.id)")
                    }
                } header: {
                    Text("Insights")
                } footer: {
                    Text("Every statement links to the journal records behind it. A pattern is only reported after at least \(PlantInsights.patternThreshold) matching records; fewer records are shown as single observations or comparisons.")
                }

            } else {
                Section {
                    ContentUnavailableView(
                        "Insights unavailable",
                        systemImage: "exclamationmark.circle",
                        description: Text("A journal record could not be validated. Your records have not been changed.")
                    )
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(FeedGoodTheme.background)
        .feedGoodHeader("Plant insights")
    }

    private func insightRow(_ insight: PlantInsight) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(insightTitle(insight))
                    .font(.headline)
                Spacer()
                Text(kindLabel(insight.kind))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            if let detail = insightDetail(insight) {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            ForEach(insight.sourceRecordIDs, id: \.self) { recordID in
                Text(sourceRecordLabel(recordID))
                    .font(.caption2.monospaced())
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 3)
    }

    private func insightTitle(_ insight: PlantInsight) -> String {
        switch insight.kind {
        case .recordedObservation:
            if let milestone = insight.milestone {
                return "\(milestone.title) recorded"
            }
            if let change = insight.changeKind {
                return "\(change.title) recorded"
            }
            return "Photo recorded"
        case .changeOverTime:
            if insight.isPhoto {
                return "\(insight.recordCount) photos to compare"
            }
            return "\(insight.milestone?.title ?? "Observation") recorded twice"
        case .pattern:
            return "\(insight.milestone?.title ?? "Observation") recorded \(insight.recordCount) times"
        case .evidenceGap:
            return "Not enough records yet"
        }
    }

    private func insightDetail(_ insight: PlantInsight) -> String? {
        let last = insight.sourceRecordIDs.last.flatMap { id in
            journalEntries.first { $0.id == id }?.date
        }
        switch insight.kind {
        case .recordedObservation:
            guard let last else { return nil }
            return "Recorded \(last.formatted(date: .abbreviated, time: .omitted))"
        case .changeOverTime:
            guard let period = insight.period else { return nil }
            let range = "\(period.start.formatted(date: .abbreviated, time: .omitted)) – \(period.end.formatted(date: .abbreviated, time: .omitted))"
            return insight.isPhoto
                ? "\(range) · Compare them in Growth review"
                : range
        case .pattern:
            guard let period = insight.period else { return nil }
            return "\(period.start.formatted(date: .abbreviated, time: .omitted)) – \(period.end.formatted(date: .abbreviated, time: .omitted))"
        case .evidenceGap:
            return "Milestones, plant changes and photos you record for this plant will appear here. Notes without one of those stay in the plant journal."
        }
    }

    private func sourceRecordLabel(_ recordID: UUID) -> String {
        let shortID = recordID.uuidString.prefix(8)
        guard let entry = journalEntries.first(where: { $0.id == recordID }) else {
            return "Journal record \(shortID)"
        }
        return "Journal record \(shortID) · \(entry.date.formatted(date: .abbreviated, time: .omitted))"
    }

    private func kindLabel(_ kind: PlantInsightKind) -> String {
        switch kind {
        case .recordedObservation: return "Recorded"
        case .changeOverTime: return "Comparison"
        case .pattern: return "Pattern"
        case .evidenceGap: return "More records needed"
        }
    }
}
