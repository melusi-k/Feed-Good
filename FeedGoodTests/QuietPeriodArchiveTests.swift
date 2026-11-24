import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct QuietPeriodArchiveTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema([
            Plant.self, CareTask.self, CareEvent.self, JournalEntry.self,
            PlantTag.self, QuietPeriod.self, QuietPeriodTaskSnapshot.self
        ])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func versionThreeRoundTripsQuietPeriodAndTaskSnapshotIdempotently() throws {
        let source = try memory()
        let context = ModelContext(source)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 14, dueDate: Date(timeIntervalSince1970: 1_800_000_000), plant: plant)
        context.insert(task)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let period = QuietPeriod(
            createdAt: start.addingTimeInterval(-60),
            startAt: start,
            endAt: nil,
            statusRaw: QuietPeriodStatus.active.rawValue,
            reason: "Winter rest",
            activatedAt: start,
            plant: plant
        )
        let snapshot = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: task.title,
            membershipStatusRaw: QuietPeriodMembershipStatus.active.rawValue,
            remainingCalendarDays: -2,
            originalDueHour: 9,
            originalDueMinute: 30,
            originalDueSecond: 15,
            frozenIntervalDays: 14,
            nextCareOverrideAt: Date(timeIntervalSince1970: 1_800_100_000),
            capturedAt: start,
            updatedAt: start.addingTimeInterval(120),
            quietPeriod: period
        )
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        let data = try JournalArchive.export(
            plants: [plant],
            entries: [],
            careTasks: [task],
            quietPeriods: [period],
            quietPeriodTaskSnapshots: [snapshot]
        )
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(archive.version == 3)
        #expect(archive.quietPeriods?.count == 1)
        #expect(archive.quietPeriodTaskSnapshots?.count == 1)

        let destination = try memory()
        let recovery = ModelContext(destination)
        let preview = try JournalArchive.preview(data, context: recovery)
        #expect(preview.quietPeriodsToAdd == 1)
        #expect(preview.quietPeriodSnapshotsToAdd == 1)
        #expect(try JournalArchive.recover(data, context: recovery) == 0)

        let restoredPeriod = try #require(recovery.fetch(FetchDescriptor<QuietPeriod>()).first)
        let restoredSnapshot = try #require(recovery.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>()).first)
        #expect(restoredPeriod.id == period.id)
        #expect(restoredPeriod.plant?.id == plant.id)
        #expect(restoredPeriod.reason == "Winter rest")
        #expect(restoredPeriod.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(restoredSnapshot.id == snapshot.id)
        #expect(restoredSnapshot.quietPeriod?.id == period.id)
        #expect(restoredSnapshot.taskID == task.id)
        #expect(restoredSnapshot.taskTitleSnapshot == task.title)
        #expect(restoredSnapshot.remainingCalendarDays == -2)
        #expect(restoredSnapshot.originalDueHour == 9)
        #expect(restoredSnapshot.originalDueMinute == 30)
        #expect(restoredSnapshot.originalDueSecond == 15)
        #expect(restoredSnapshot.frozenIntervalDays == 14)
        #expect(restoredSnapshot.nextCareOverrideAt == snapshot.nextCareOverrideAt)
        #expect(try JournalArchive.recover(data, context: recovery) == 0)

        restoredSnapshot.taskTitleSnapshot = "Changed locally"
        try recovery.save()
        #expect(throws: JournalArchiveError.conflictingRecord) {
            try JournalArchive.recover(data, context: recovery)
        }
        #expect(restoredSnapshot.taskTitleSnapshot == "Changed locally")
    }

    @Test func invalidQuietPeriodReferencesAndActiveMembershipRejectBeforeWrites() throws {
        let plant = Plant(name: "Fern")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .distantFuture, plant: plant)
        let period = JournalArchive.QuietPeriodRecord(
            id: UUID(), plantID: plant.id, createdAt: .now, startAt: .now,
            endAt: nil, statusRaw: QuietPeriodStatus.active.rawValue,
            reason: nil, activatedAt: .now, endedAt: nil
        )
        let orphanSnapshot = JournalArchive.QuietPeriodTaskSnapshotRecord(
            id: UUID(), quietPeriodID: UUID(), taskID: task.id, taskTitleSnapshot: task.title,
            membershipStatusRaw: QuietPeriodMembershipStatus.active.rawValue,
            remainingCalendarDays: 2, originalDueHour: 9, originalDueMinute: 0,
            originalDueSecond: 0, frozenIntervalDays: nil, nextCareOverrideAt: nil,
            capturedAt: .now, updatedAt: .now
        )
        let orphan = JournalArchive(
            plants: [.init(id: plant.id, name: plant.name, species: "", notes: "", createdAt: plant.createdAt)],
            entries: [],
            careTasks: [.init(id: task.id, plantID: plant.id, kindRaw: task.kindRaw, customTitle: "", intervalDays: 7, dueDate: task.dueDate, isEnabled: true, reminderEnabled: true)],
            careEvents: [],
            quietPeriods: [period],
            quietPeriodTaskSnapshots: [orphanSnapshot]
        )
        #expect(throws: JournalArchiveError.invalidRecord) { try orphan.validate() }

        var noActiveMember = orphan
        noActiveMember.quietPeriodTaskSnapshots = []
        #expect(throws: JournalArchiveError.invalidRecord) { try noActiveMember.validate() }

        var disabledActiveMember = orphan
        disabledActiveMember.quietPeriodTaskSnapshots = [
            .init(
                id: UUID(), quietPeriodID: period.id, taskID: task.id, taskTitleSnapshot: task.title,
                membershipStatusRaw: QuietPeriodMembershipStatus.active.rawValue,
                remainingCalendarDays: 2, originalDueHour: 9, originalDueMinute: 0,
                originalDueSecond: 0, frozenIntervalDays: nil, nextCareOverrideAt: nil,
                capturedAt: .now, updatedAt: .now
            )
        ]
        disabledActiveMember.careTasks?[0].isEnabled = false
        #expect(throws: JournalArchiveError.invalidRecord) { try disabledActiveMember.validate() }

        let destination = try memory()
        let recovery = ModelContext(destination)
        #expect(throws: JournalArchiveError.invalidRecord) {
            try JournalArchive.recover(try JSONEncoder().encode(orphan), context: recovery)
        }
        #expect(try recovery.fetch(FetchDescriptor<Plant>()).isEmpty)
        #expect(try recovery.fetch(FetchDescriptor<QuietPeriod>()).isEmpty)
    }

    @Test func failedVersionThreeRecoveryRollsBackPeriodsAndSnapshotsWithGardenRecords() throws {
        enum InjectedFailure: Error { case save }
        let source = try memory()
        let context = ModelContext(source)
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .distantFuture, plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: .now, statusRaw: QuietPeriodStatus.active.rawValue, activatedAt: .now, plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(taskID: task.id, taskTitleSnapshot: task.title, quietPeriod: period)
        context.insert(period)
        context.insert(snapshot)
        try context.save()
        let data = try JournalArchive.export(
            plants: [plant], entries: [], careTasks: [task],
            quietPeriods: [period], quietPeriodTaskSnapshots: [snapshot]
        )

        let destination = try memory()
        let recovery = ModelContext(destination)
        #expect(throws: InjectedFailure.self) {
            try JournalArchive.recover(data, context: recovery) { _ in throw InjectedFailure.save }
        }
        let verify = ModelContext(destination)
        #expect(try verify.fetch(FetchDescriptor<Plant>()).isEmpty)
        #expect(try verify.fetch(FetchDescriptor<CareTask>()).isEmpty)
        #expect(try verify.fetch(FetchDescriptor<QuietPeriod>()).isEmpty)
        #expect(try verify.fetch(FetchDescriptor<QuietPeriodTaskSnapshot>()).isEmpty)
    }
}
