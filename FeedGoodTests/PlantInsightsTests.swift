import Foundation
import Testing
@testable import FeedGood

struct PlantInsightsTests {
    private let plantID = UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
    private let otherPlantID = UUID(uuidString: "00000000-0000-0000-0000-000000000002")!

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    private func entry(
        _ id: Int,
        plantID: UUID? = nil,
        date: TimeInterval,
        milestone: JournalMilestone? = nil,
        changeKind: PlantChangeKind? = nil,
        hasPhoto: Bool = false
    ) -> PlantInsightJournalSnapshot {
        PlantInsightJournalSnapshot(
            id: UUID(uuidString: String(format: "00000000-0000-0000-0000-%012d", id))!,
            plantID: plantID ?? self.plantID,
            date: self.date(date),
            milestone: milestone,
            changeKind: changeKind,
            hasPhoto: hasPhoto
        )
    }

    private let day: TimeInterval = 86_400

    @Test func plantWithoutRecordsShowsEvidenceGap() throws {
        let insights = try PlantInsights.insights(plantID: plantID, entries: [])
        #expect(insights.count == 1)
        #expect(insights[0].kind == .evidenceGap)
        #expect(insights[0].sourceRecordIDs.isEmpty)
    }

    @Test func singleObservationIsNeverATrend() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [entry(1, date: 0, milestone: .newLeaf)]
        )
        #expect(insights.count == 1)
        #expect(insights[0].kind == .recordedObservation)
        #expect(insights[0].milestone == .newLeaf)
        #expect(insights[0].sourceRecordIDs.count == 1)
        #expect(insights[0].period == nil)
    }

    @Test func twoComparableRecordsShowChangeOverTimeNotPattern() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, date: 7 * day, milestone: .flowering),
                entry(2, date: 0, milestone: .flowering)
            ]
        )
        #expect(insights.count == 1)
        let insight = insights[0]
        #expect(insight.kind == .changeOverTime)
        #expect(insight.recordCount == 2)
        #expect(insight.period == DateInterval(start: date(0), end: date(7 * day)))
        // Oldest first, regardless of input order.
        #expect(insight.sourceRecordIDs == [
            UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
            UUID(uuidString: "00000000-0000-0000-0000-000000000001")!
        ])
    }

    @Test func patternRequiresThreeComparableRecords() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, date: 0, milestone: .newLeaf),
                entry(2, date: 7 * day, milestone: .newLeaf),
                entry(3, date: 14 * day, milestone: .newLeaf)
            ]
        )
        #expect(insights.count == 1)
        let insight = insights[0]
        #expect(insight.kind == .pattern)
        #expect(insight.recordCount == 3)
        #expect(insight.sourceRecordIDs.count == 3)
    }

    @Test func differentKindsNeverCombine() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, date: 0, milestone: .newLeaf),
                entry(2, date: day, milestone: .newLeaf),
                entry(3, date: 2 * day, milestone: .flowering)
            ]
        )
        #expect(insights.count == 2)
        #expect(insights.contains { $0.kind == .changeOverTime && $0.milestone == .newLeaf })
        #expect(insights.contains { $0.kind == .recordedObservation && $0.milestone == .flowering })
        #expect(!insights.contains { $0.kind == .pattern })
    }

    @Test func plantChangesAreObservationsOnly() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, date: 0, changeKind: .repotted),
                entry(2, date: 7 * day, changeKind: .repotted),
                entry(3, date: 14 * day, changeKind: .repotted)
            ]
        )
        // Even three records of the same change kind never form a trend.
        #expect(insights.count == 1)
        #expect(insights[0].kind == .recordedObservation)
        #expect(insights[0].changeKind == .repotted)
        // The most recent record is the one surfaced.
        #expect(insights[0].sourceRecordIDs == [
            UUID(uuidString: "00000000-0000-0000-0000-000000000003")!
        ])
    }

    @Test func twoOrMorePhotosBecomeComparableThroughGrowthReview() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, date: 0, hasPhoto: true),
                entry(2, date: 7 * day, hasPhoto: true),
                entry(3, date: 14 * day, hasPhoto: true)
            ]
        )
        #expect(insights.count == 1)
        let insight = insights[0]
        #expect(insight.kind == .changeOverTime)
        #expect(insight.isPhoto)
        #expect(insight.recordCount == 3)
        #expect(insight.period == DateInterval(start: date(0), end: date(14 * day)))
    }

    @Test func singlePhotoIsAnObservation() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [entry(1, date: 0, hasPhoto: true)]
        )
        #expect(insights.count == 1)
        #expect(insights[0].kind == .recordedObservation)
        #expect(insights[0].isPhoto)
    }

    @Test func notesOnlyRecordsShowEvidenceGap() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [entry(1, date: 0), entry(2, date: day)]
        )
        #expect(insights.count == 1)
        #expect(insights[0].kind == .evidenceGap)
    }

    @Test func otherPlantsRecordsAreExcluded() throws {
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, plantID: otherPlantID, date: 0, milestone: .newLeaf),
                entry(2, plantID: otherPlantID, date: day, milestone: .newLeaf),
                entry(3, plantID: otherPlantID, date: 2 * day, milestone: .newLeaf)
            ]
        )
        #expect(insights.count == 1)
        #expect(insights[0].kind == .evidenceGap)
    }

    @Test func duplicateRecordIDsFailClosed() throws {
        let record = entry(1, date: 0, milestone: .newLeaf)
        #expect(throws: PlantInsightsError.self) {
            try PlantInsights.insights(plantID: plantID, entries: [record, record])
        }
    }

    @Test func recordThatIsBothMilestoneAndChangeFailsClosed() throws {
        let invalid = entry(1, date: 0, milestone: .newLeaf, changeKind: .repotted)
        #expect(throws: PlantInsightsError.self) {
            try PlantInsights.insights(plantID: plantID, entries: [invalid])
        }
    }

    @Test func outputOrderIsDeterministicRegardlessOfInputOrder() throws {
        let records = [
            entry(1, date: 0, milestone: .newLeaf),
            entry(2, date: day, milestone: .newLeaf),
            entry(3, date: 2 * day, milestone: .newLeaf),
            entry(4, date: 3 * day, changeKind: .repotted),
            entry(5, date: 4 * day, hasPhoto: true),
            entry(6, date: 5 * day, hasPhoto: true)
        ]
        let forward = try PlantInsights.insights(plantID: plantID, entries: records)
        let reversed = try PlantInsights.insights(plantID: plantID, entries: records.reversed())
        #expect(forward == reversed)
        #expect(forward.map(\.kind) == [.pattern, .recordedObservation, .changeOverTime])
    }

    @Test func periodsStayInstantAnchoredAcrossDaylightSaving() throws {
        // A pattern spanning the America/New_York spring-forward keeps exact
        // instants: the wall-clock day is 23 hours, the period is not.
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "America/New_York")!
        let first = calendar.date(from: DateComponents(
            year: 2026, month: 3, day: 8, hour: 1, minute: 30
        ))!
        let second = first.addingTimeInterval(7 * 86_400)
        let third = second.addingTimeInterval(7 * 86_400)
        let insights = try PlantInsights.insights(
            plantID: plantID,
            entries: [
                entry(1, date: first.timeIntervalSince1970, milestone: .newLeaf),
                entry(2, date: second.timeIntervalSince1970, milestone: .newLeaf),
                entry(3, date: third.timeIntervalSince1970, milestone: .newLeaf)
            ]
        )
        #expect(insights[0].kind == .pattern)
        #expect(insights[0].period == DateInterval(start: first, end: third))
    }
}
