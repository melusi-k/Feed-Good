import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct QuietPeriodLifecycleTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: FeedGoodSchemaV4.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    private func calendar(_ zone: String) -> Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = TimeZone(identifier: zone)!
        return value
    }

    @Test func scheduledPeriodDoesNotPauseUntilStartAndResumesFromFrozenCalendarOffset() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let due = date("2026-12-10T08:45:30+02:00")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        try context.save()

        let start = date("2026-12-01T00:00:00+02:00")
        let end = date("2026-12-05T17:30:00+02:00")
        let period = try QuietPeriodLifecycle.create(
            for: plant,
            selectedTaskIDs: [task.id],
            startAt: start,
            endAt: end,
            now: date("2026-11-24T12:00:00+02:00"),
            in: context,
            calendar: calendar("Africa/Johannesburg")
        )

        #expect(period.statusRaw == QuietPeriodStatus.scheduled.rawValue)
        #expect(task.dueDate == due)
        #expect(period.taskSnapshots?.first?.remainingCalendarDays == nil)

        try QuietPeriodLifecycle.advance(
            period,
            now: start.addingTimeInterval(-1),
            in: context,
            calendar: calendar("Africa/Johannesburg")
        )
        #expect(period.statusRaw == QuietPeriodStatus.scheduled.rawValue)
        #expect(task.dueDate == due)

        try QuietPeriodLifecycle.advance(
            period,
            now: start,
            in: context,
            calendar: calendar("Africa/Johannesburg")
        )
        #expect(period.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(period.taskSnapshots?.first?.remainingCalendarDays == 9)
        #expect(task.dueDate == due)

        try QuietPeriodLifecycle.advance(
            period,
            now: end,
            in: context,
            calendar: calendar("Africa/Johannesburg")
        )
        #expect(period.statusRaw == QuietPeriodStatus.ended.rawValue)
        #expect(period.endedAt == end)
        #expect(task.dueDate == date("2026-12-14T08:45:30+02:00"))
    }

    @Test func immediatePeriodPreservesOverdueOffsetAndOriginalLocalTime() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let due = date("2026-11-20T06:15:42+02:00")
        let task = CareTask(kind: .feeding, intervalDays: 14, dueDate: due, plant: plant)
        context.insert(task)
        try context.save()

        let now = date("2026-11-24T12:00:00+02:00")
        let period = try QuietPeriodLifecycle.create(
            for: plant,
            selectedTaskIDs: [task.id],
            startAt: now,
            endAt: nil,
            now: now,
            in: context,
            calendar: calendar("Africa/Johannesburg")
        )

        #expect(period.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(period.taskSnapshots?.first?.remainingCalendarDays == -4)
        #expect(task.dueDate == due)

        let resumedAt = date("2026-12-01T10:00:00+02:00")
        try QuietPeriodLifecycle.end(
            period,
            at: resumedAt,
            in: context,
            calendar: calendar("Africa/Johannesburg")
        )

        #expect(period.statusRaw == QuietPeriodStatus.ended.rawValue)
        #expect(task.dueDate == date("2026-11-27T06:15:42+02:00"))
    }

    @Test func explicitNextCareOverrideWinsOverFrozenOffset() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Monstera")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: date("2026-12-01T09:00:00Z"), plant: plant)
        context.insert(task)
        let period = QuietPeriod(
            startAt: date("2026-11-24T00:00:00Z"),
            plant: plant
        )
        let snapshot = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: task.title,
            remainingCalendarDays: 7,
            originalDueHour: 9,
            originalDueMinute: 0,
            originalDueSecond: 0,
            nextCareOverrideAt: date("2026-12-03T16:20:00Z"),
            quietPeriod: period
        )
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        try QuietPeriodLifecycle.end(
            period,
            at: date("2026-12-01T12:00:00Z"),
            in: context,
            calendar: calendar("UTC")
        )

        #expect(task.dueDate == date("2026-12-03T16:20:00Z"))
    }

    @Test func intervalSnapshotResumesFromFullIntervalAfterQuietPeriod() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Pothos")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 21, dueDate: date("2026-12-01T08:00:00Z"), plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: date("2026-11-24T00:00:00Z"), plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: task.title,
            remainingCalendarDays: 7,
            originalDueHour: 8,
            originalDueMinute: 0,
            originalDueSecond: 0,
            frozenIntervalDays: 14,
            quietPeriod: period
        )
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        try QuietPeriodLifecycle.end(
            period,
            at: date("2026-12-05T10:00:00Z"),
            in: context,
            calendar: calendar("UTC")
        )

        #expect(task.dueDate == date("2026-12-19T08:00:00Z"))
    }

    @Test func failedResumeRestoresDueDateAndActivePeriod() throws {
        enum SaveFailure: Error { case injected }
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let due = date("2026-12-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: date("2026-11-24T00:00:00Z"), plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: task.title,
            remainingCalendarDays: 7,
            originalDueHour: 9,
            originalDueMinute: 0,
            originalDueSecond: 0,
            quietPeriod: period
        )
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        #expect(throws: SaveFailure.self) {
            try QuietPeriodLifecycle.end(
                period,
                at: date("2026-12-01T12:00:00Z"),
                in: context,
                calendar: calendar("UTC"),
                save: { _ in throw SaveFailure.injected }
            )
        }
        #expect(task.dueDate == due)
        #expect(period.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(period.endedAt == nil)
    }

    @Test func scheduledCreationRejectsDisabledTasks() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, isEnabled: false, plant: plant)
        context.insert(task)
        try context.save()

        #expect(throws: QuietPeriodLifecycleError.taskNotEnabled) {
            try QuietPeriodLifecycle.create(
                for: plant,
                selectedTaskIDs: [task.id],
                startAt: .distantFuture,
                endAt: nil,
                now: .now,
                in: context
            )
        }
    }

    @Test func archivingCancelsScheduledPeriodAndRetainsHistory() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let period = QuietPeriod(startAt: .distantFuture, plant: plant)
        context.insert(period)
        try context.save()

        try QuietPeriodLifecycle.endForArchive(period, at: .now, in: context)

        #expect(period.statusRaw == QuietPeriodStatus.cancelled.rawValue)
        #expect(period.endedAt != nil)
        #expect(plant.quietPeriods?.contains(where: { $0.id == period.id }) == true)
    }
}
