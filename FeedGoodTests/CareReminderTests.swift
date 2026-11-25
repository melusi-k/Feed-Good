import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
private final class FakeCareNotifications: CareNotificationBoundary {
    var status: ReminderPermission = .allowed
    var pending: [String: CareReminder] = [:]
    var requestCount = 0
    var readCount = 0
    var removed: [String] = []
    var failAdds = false
    func permission() async -> ReminderPermission { status }
    func requestPermission() async throws -> Bool { requestCount += 1; return status == .allowed }
    func pendingIDs() async -> [String] { readCount += 1; await Task.yield(); return Array(pending.keys) }
    func remove(_ ids: [String]) { removed += ids; for id in ids { pending[id] = nil } }
    func add(_ reminder: CareReminder) async throws {
        if failAdds { throw NSError(domain: "Test", code: 1) }
        pending[reminder.id] = reminder
    }
}

@MainActor
struct CareReminderTests {
    private func reminder(_ suffix: String = "one", date: Date = .distantFuture) -> CareReminder {
        CareReminder(id: CareReminderScheduler.prefix + suffix, title: "Fern", body: "Check soil", date: date)
    }

    @Test func reconcileReschedulesCancelsAndDoesNotDuplicateOrAskPermission() async {
        let fake = FakeCareNotifications()
        let scheduler = CareReminderScheduler(boundary: fake)
        let first = reminder()
        await scheduler.reconcile([first])
        await scheduler.reconcile([first])
        #expect(fake.pending.count == 1)
        #expect(fake.requestCount == 0)
        let changed = reminder(date: Date(timeIntervalSince1970: 2_000_000_000))
        await scheduler.reconcile([changed])
        #expect(fake.pending[first.id]?.date == changed.date)
        await scheduler.reconcile([])
        #expect(fake.pending.isEmpty)
        #expect(fake.removed.contains(first.id))
    }

    @Test func deniedPermissionCancelsAndSettingsGrantRestoresWithoutPrompt() async {
        let fake = FakeCareNotifications()
        let scheduler = CareReminderScheduler(boundary: fake)
        await scheduler.reconcile([reminder()])
        fake.status = .denied
        await scheduler.reconcile([reminder()])
        #expect(fake.pending.isEmpty)
        #expect(scheduler.message.contains("Settings"))
        fake.status = .allowed
        await scheduler.reconcile([reminder()])
        #expect(fake.pending.count == 1)
        #expect(fake.requestCount == 0)
        await scheduler.requestPermission()
        #expect(fake.requestCount == 1)
    }

    @Test func notDeterminedNeverPromptsDuringReconcileAndFailureIsVisible() async {
        let fake = FakeCareNotifications()
        fake.status = .notDetermined
        let scheduler = CareReminderScheduler(boundary: fake)
        await scheduler.reconcile([reminder()])
        #expect(fake.requestCount == 0)
        #expect(fake.pending.isEmpty)
        fake.status = .allowed; fake.failAdds = true
        await scheduler.reconcile([reminder()])
        #expect(scheduler.message.contains("couldn't"))
    }

    @Test func onlyFutureEnabledOptInTasksWithAPlantAreScheduled() {
        let plant = Plant(name: "Fern")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(kind: .watering, intervalDays: 3, dueDate: now.addingTimeInterval(3600), plant: plant)
        #expect(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
        task.reminderEnabled = true
        #expect(CareReminderScheduler.reminders(for: [task], now: now).count == 1)
        task.isEnabled = false
        #expect(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
        task.isEnabled = true; task.dueDate = now
        #expect(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
        task.dueDate = now.addingTimeInterval(3600); task.plant = nil
        #expect(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
    }

    @Test func quietPeriodWithholdsOnlySelectedRemindersAndRestoresEligibilityOnEnd() throws {
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let selected = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: now.addingTimeInterval(3 * 86_400),
            reminderEnabled: true,
            plant: plant
        )
        let unaffected = CareTask(
            kind: .feeding,
            intervalDays: 14,
            dueDate: now.addingTimeInterval(5 * 86_400),
            reminderEnabled: true,
            plant: plant
        )
        context.insert(selected)
        context.insert(unaffected)
        try context.save()

        let period = try QuietPeriodLifecycle.create(
            for: plant,
            selectedTaskIDs: [selected.id],
            startAt: now,
            endAt: nil,
            now: now,
            in: context
        )
        #expect(CareReminderScheduler.reminders(for: [selected, unaffected], now: now).map(\.taskID) == [unaffected.id])

        try QuietPeriodLifecycle.end(period, at: now.addingTimeInterval(2 * 86_400), in: context)
        #expect(Set(CareReminderScheduler.reminders(for: [selected, unaffected], now: now).compactMap(\.taskID)) == Set([selected.id, unaffected.id]))
    }

    @Test func capacityPreservesUnrelatedRequestsAndConcurrentLatestCancelWins() async {
        let fake = FakeCareNotifications()
        let unrelated = CareReminder(id: "other.feature", title: "Other", body: "", date: .distantFuture)
        fake.pending[unrelated.id] = unrelated
        let scheduler = CareReminderScheduler(boundary: fake)
        await scheduler.reconcile((0..<70).map { reminder(String($0)) })
        #expect(fake.pending.count == 64)
        #expect(fake.pending[unrelated.id] == unrelated)
        #expect(scheduler.message.contains("63"))
        let oldReadCount = fake.readCount
        let adding = Task { await scheduler.reconcile([reminder()]) }
        while fake.readCount == oldReadCount { await Task.yield() }
        await scheduler.reconcile([])
        await adding.value
        #expect(fake.pending.count == 1)
        #expect(fake.pending[unrelated.id] == unrelated)
    }


    @Test func notificationPayloadRoundTripsPlantAndTaskIdentityAndRejectsMalformedValues() {
        let taskID = UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!
        let plantID = UUID(uuidString: "11111111-2222-3333-4444-555555555555")!
        let payload = CareNotificationPayload.make(taskID: taskID, plantID: plantID)
        let destination = CareNotificationPayload.destination(from: payload)
        #expect(destination?.taskID == taskID)
        #expect(destination?.plantID == plantID)
        #expect(CareNotificationPayload.destination(from: [:])?.taskID == nil)
        #expect(CareNotificationPayload.destination(from: [CareNotificationPayload.taskIDKey: "not-a-uuid", CareNotificationPayload.plantIDKey: plantID.uuidString])?.taskID == nil)
    }

    @Test func reminderComponentsPreserveTheSameInstantAcrossTimeZoneChanges() throws {
        let dueDate = try #require(ISO8601DateFormatter().date(from: "2026-11-22T18:45:30Z"))
        for identifier in ["Africa/Johannesburg", "America/Los_Angeles"] {
            let timeZone = try #require(TimeZone(identifier: identifier))
            let components = CareNotificationTrigger.dateComponents(for: dueDate, timeZone: timeZone)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = timeZone
            #expect(calendar.date(from: components) == dueDate)
        }
    }

    @Test func archivedPlantsAreNotScheduledForCareReminders() {
        let archivedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let plant = Plant(name: "Fern", archivedAt: archivedAt)
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: now.addingTimeInterval(3600), reminderEnabled: true, plant: plant)
        #expect(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
    }

    @Test func archivingCancelsReminderProjectionAndRestoreMakesItEligibleAgain() {
        let plant = Plant(name: "Fern")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: now.addingTimeInterval(3600),
            reminderEnabled: true,
            plant: plant
        )
        #expect(CareReminderScheduler.reminders(for: [task], now: now).count == 1)

        plant.archivedAt = Date(timeIntervalSince1970: 1_700_000_000)
        #expect(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)

        plant.archivedAt = nil
        #expect(CareReminderScheduler.reminders(for: [task], now: now).count == 1)
    }

}
