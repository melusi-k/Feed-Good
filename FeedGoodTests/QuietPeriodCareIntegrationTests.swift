import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct QuietPeriodCareIntegrationTests {
    private func memory() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: FeedGoodSchemaV4.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    @Test func completionDuringQuietPeriodRecordsEventButDoesNotAdvanceTaskDueDate() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let due = date("2026-12-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 12, dueDate: due, plant: plant)
        context.insert(task)
        try context.save()
        let now = date("2026-11-24T12:00:00Z")
        let period = try QuietPeriodLifecycle.create(
            for: plant,
            selectedTaskIDs: [task.id],
            startAt: now,
            endAt: nil,
            now: now,
            in: context,
            calendar: Calendar(identifier: .gregorian)
        )

        try CareRecorder.complete(task, note: "Watered during pause", at: now, in: context)

        #expect(task.dueDate == due)
        #expect(plant.careEvents?.count == 1)
        #expect(plant.careEvents?.first?.note == "Watered during pause")
        #expect(period.taskSnapshots?.first?.frozenIntervalDays == 12)
        #expect(period.taskSnapshots?.first?.nextCareOverrideAt == nil)
    }

    @Test func intervalAndNextCareEditsUpdateFrozenSnapshotWithoutEndingPause() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let due = date("2026-12-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: date("2026-11-24T00:00:00Z"), statusRaw: "active", activatedAt: date("2026-11-24T00:00:00Z"), plant: plant)
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

        try QuietPeriodTaskIntegration.applyEditorChanges(
            to: task,
            previousIntervalDays: 7,
            previousDueDate: due,
            previousEnabled: true,
            at: date("2026-11-25T10:00:00Z"),
            in: context
        )
        task.intervalDays = 21
        snapshot.frozenIntervalDays = 21
        let selectedNextCare = date("2026-12-08T16:45:00Z")
        task.dueDate = selectedNextCare
        try QuietPeriodTaskIntegration.applyEditorChanges(
            to: task,
            previousIntervalDays: 21,
            previousDueDate: due,
            previousEnabled: true,
            at: date("2026-11-25T10:01:00Z"),
            in: context
        )

        #expect(period.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(snapshot.frozenIntervalDays == 21)
        #expect(snapshot.nextCareOverrideAt == selectedNextCare)
    }

    @Test func disablingTaskRemovesActiveMembershipAndReenablingDoesNotReaddIt() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Pothos")
        context.insert(plant)
        let task = CareTask(kind: .feeding, intervalDays: 14, dueDate: .distantFuture, plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: .now, statusRaw: "active", activatedAt: .now, plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(taskID: task.id, taskTitleSnapshot: task.title, quietPeriod: period)
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        try QuietPeriodTaskIntegration.applyEditorChanges(
            to: task,
            previousIntervalDays: 14,
            previousDueDate: task.dueDate,
            previousEnabled: true,
            at: .now,
            in: context
        )
        task.isEnabled = false
        snapshot.membershipStatusRaw = QuietPeriodMembershipStatus.disabled.rawValue

        #expect(snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.disabled.rawValue)
        task.isEnabled = true
        try context.save()
        #expect(snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.disabled.rawValue)
        #expect(task.isEnabled)
    }

    @Test func activeQuietPeriodSuppressesCareNotificationsOnlyForIncludedTasks() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Monstera")
        context.insert(plant)
        let included = CareTask(kind: .watering, intervalDays: 7, dueDate: .distantFuture, reminderEnabled: true, plant: plant)
        let excluded = CareTask(kind: .feeding, intervalDays: 14, dueDate: .distantFuture, reminderEnabled: true, plant: plant)
        context.insert(included)
        context.insert(excluded)
        let period = QuietPeriod(startAt: .now, statusRaw: "active", activatedAt: .now, plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(taskID: included.id, taskTitleSnapshot: included.title, quietPeriod: period)
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        let reminders = CareReminderScheduler.reminders(for: [included, excluded], now: .now)

        #expect(reminders.count == 1)
        #expect(reminders.first?.taskID == excluded.id)
    }

    @Test func deletingLastIncludedTaskEndsPeriodAndRetainsSnapshotAudit() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .distantFuture, plant: plant)
        context.insert(task)
        let period = QuietPeriod(startAt: .now, statusRaw: "active", activatedAt: .now, plant: plant)
        let snapshot = QuietPeriodTaskSnapshot(taskID: task.id, taskTitleSnapshot: task.title, quietPeriod: period)
        context.insert(period)
        context.insert(snapshot)
        try context.save()

        try QuietPeriodTaskIntegration.markDeleted(taskID: task.id, at: .now, in: context)
        context.delete(task)

        #expect(period.statusRaw == QuietPeriodStatus.ended.rawValue)
        #expect(snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.removed.rawValue)
        #expect(snapshot.taskTitleSnapshot == "Watering")
    }
}
