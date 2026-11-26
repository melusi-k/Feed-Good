import Foundation

/// An immutable value snapshot of one user-recorded journal entry, used at the
/// persistence boundary so the insight calculator stays pure and testable
/// without SwiftData.
struct PlantInsightJournalSnapshot: Equatable {
    let id: UUID
    let plantID: UUID
    let date: Date
    let milestone: JournalMilestone?
    let changeKind: PlantChangeKind?
    let hasPhoto: Bool

    init(
        id: UUID,
        plantID: UUID,
        date: Date,
        milestone: JournalMilestone?,
        changeKind: PlantChangeKind?,
        hasPhoto: Bool
    ) {
        self.id = id
        self.plantID = plantID
        self.date = date
        self.milestone = milestone
        self.changeKind = changeKind
        self.hasPhoto = hasPhoto
    }

    @MainActor
    init(entry: JournalEntry) {
        id = entry.id
        plantID = entry.plant?.id ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        date = entry.date
        milestone = entry.milestone
        changeKind = entry.changeKind
        hasPhoto = entry.photoData != nil
    }
}

enum PlantInsightsError: Error, Equatable {
    case duplicateRecord(UUID)
    /// A record that is both a milestone and a change violates the journal's
    /// one-kind-per-record invariant; fail closed rather than guess.
    case invalidRecord(UUID)
}

/// The PRD-024 evidence classes. No diagnosis, scoring or interpretation is
/// representable here by construction.
enum PlantInsightKind: String, Equatable {
    case recordedObservation
    case changeOverTime
    case pattern
    case evidenceGap
}

/// One evidence-led statement about a plant, always traceable to the source
/// records that support it.
struct PlantInsight: Identifiable, Equatable {
    /// Deterministic identity derived from the kind and source record IDs.
    let id: String
    let kind: PlantInsightKind
    let plantID: UUID
    /// Set for milestone observations, changes over time and patterns.
    let milestone: JournalMilestone?
    /// Set for plant-change observations.
    let changeKind: PlantChangeKind?
    /// True when the insight is a comparable-photo observation.
    let isPhoto: Bool
    /// Number of supporting records (patterns and photo comparisons).
    let recordCount: Int
    /// The half-open span of supporting records, where one exists.
    let period: DateInterval?
    /// Every source record behind the statement, oldest first.
    let sourceRecordIDs: [UUID]
}

/// Deterministic, evidence-led plant insights over journal records only.
///
/// The calculator never interprets free text, never diagnoses, and never
/// combines unrelated signals. A single observation is never a trend: patterns
/// require at least `patternThreshold` comparable records of the same kind,
/// and two comparable records are presented as a change over time, nothing
/// more. Plants with no comparable records receive an honest evidence gap.
/// Results recompute from source records on every call; nothing is persisted.
enum PlantInsights {
    /// Minimum comparable same-kind records before a pattern may be stated.
    static let patternThreshold = 3

    static func insights(
        plantID: UUID,
        entries: [PlantInsightJournalSnapshot]
    ) throws -> [PlantInsight] {
        var seenIDs = Set<UUID>()
        var plantEntries: [PlantInsightJournalSnapshot] = []
        for entry in entries {
            guard entry.plantID == plantID else { continue }
            guard seenIDs.insert(entry.id).inserted else {
                throw PlantInsightsError.duplicateRecord(entry.id)
            }
            guard !(entry.milestone != nil && entry.changeKind != nil) else {
                throw PlantInsightsError.invalidRecord(entry.id)
            }
            plantEntries.append(entry)
        }

        // Deterministic ordering: date, then stable source ID.
        plantEntries.sort {
            ($0.date, $0.id.uuidString) < ($1.date, $1.id.uuidString)
        }

        guard !plantEntries.isEmpty else {
            return [evidenceGap(plantID: plantID)]
        }

        var result: [PlantInsight] = []

        // Milestones: same-kind repeats are the only comparable observations.
        for milestone in JournalMilestone.allCases {
            let records = plantEntries.filter { $0.milestone == milestone }
            guard let first = records.first, let last = records.last else { continue }
            if records.count >= patternThreshold {
                result.append(PlantInsight(
                    id: "pattern.\(milestone.rawValue).\(first.id.uuidString)",
                    kind: .pattern,
                    plantID: plantID,
                    milestone: milestone,
                    changeKind: nil,
                    isPhoto: false,
                    recordCount: records.count,
                    period: DateInterval(start: first.date, end: last.date),
                    sourceRecordIDs: records.map(\.id)
                ))
            } else if records.count == 2 {
                result.append(PlantInsight(
                    id: "change.\(milestone.rawValue).\(first.id.uuidString)",
                    kind: .changeOverTime,
                    plantID: plantID,
                    milestone: milestone,
                    changeKind: nil,
                    isPhoto: false,
                    recordCount: 2,
                    period: DateInterval(start: first.date, end: last.date),
                    sourceRecordIDs: records.map(\.id)
                ))
            } else {
                result.append(observation(
                    plantID: plantID,
                    record: last,
                    milestone: milestone
                ))
            }
        }

        // Plant changes: each recorded change is an observation. Changes never
        // form trends.
        for changeKind in PlantChangeKind.allCases {
            let records = plantEntries.filter { $0.changeKind == changeKind }
            guard let last = records.last else { continue }
            result.append(PlantInsight(
                id: "observation.change.\(changeKind.rawValue).\(last.id.uuidString)",
                kind: .recordedObservation,
                plantID: plantID,
                milestone: nil,
                changeKind: changeKind,
                isPhoto: false,
                recordCount: 1,
                period: nil,
                sourceRecordIDs: [last.id]
            ))
        }

        // Photos: two or more photo records are comparable through Growth
        // Review; one photo is a plain observation.
        let photos = plantEntries.filter(\.hasPhoto)
        if photos.count >= 2, let first = photos.first, let last = photos.last {
            result.append(PlantInsight(
                id: "change.photos.\(first.id.uuidString)",
                kind: .changeOverTime,
                plantID: plantID,
                milestone: nil,
                changeKind: nil,
                isPhoto: true,
                recordCount: photos.count,
                period: DateInterval(start: first.date, end: last.date),
                sourceRecordIDs: photos.map(\.id)
            ))
        } else if let only = photos.only {
            result.append(observation(
                plantID: plantID,
                record: only,
                milestone: nil,
                isPhoto: true
            ))
        }

        if result.isEmpty {
            // Records exist but none are comparable (free-text notes only).
            return [evidenceGap(plantID: plantID)]
        }
        return result
    }

    private static func observation(
        plantID: UUID,
        record: PlantInsightJournalSnapshot,
        milestone: JournalMilestone?,
        isPhoto: Bool = false
    ) -> PlantInsight {
        PlantInsight(
            id: "observation.\(record.id.uuidString)",
            kind: .recordedObservation,
            plantID: plantID,
            milestone: milestone,
            changeKind: nil,
            isPhoto: isPhoto,
            recordCount: 1,
            period: nil,
            sourceRecordIDs: [record.id]
        )
    }

    private static func evidenceGap(plantID: UUID) -> PlantInsight {
        PlantInsight(
            id: "gap.\(plantID.uuidString)",
            kind: .evidenceGap,
            plantID: plantID,
            milestone: nil,
            changeKind: nil,
            isPhoto: false,
            recordCount: 0,
            period: nil,
            sourceRecordIDs: []
        )
    }
}

private extension Array {
    var only: Element? { count == 1 ? first : nil }
}
