import XCTest
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
final class CareReminderTests: XCTestCase {
    private func reminder(_ suffix: String = "one", date: Date = .distantFuture) -> CareReminder {
        CareReminder(id: CareReminderScheduler.prefix + suffix, title: "Fern", body: "Check soil", date: date)
    }

    func testReconcileReschedulesCancelsAndDoesNotDuplicateOrAskPermission() async {
        let fake = FakeCareNotifications()
        let scheduler = CareReminderScheduler(boundary: fake)
        let first = reminder()
        await scheduler.reconcile([first])
        await scheduler.reconcile([first])
        XCTAssertEqual(fake.pending.count, 1)
        XCTAssertEqual(fake.requestCount, 0)
        let changed = reminder(date: Date(timeIntervalSince1970: 2_000_000_000))
        await scheduler.reconcile([changed])
        XCTAssertEqual(fake.pending[first.id]?.date, changed.date)
        await scheduler.reconcile([])
        XCTAssertTrue(fake.pending.isEmpty)
        XCTAssertTrue(fake.removed.contains(first.id))
    }

    func testDeniedPermissionCancelsAndSettingsGrantRestoresWithoutPrompt() async {
        let fake = FakeCareNotifications()
        let scheduler = CareReminderScheduler(boundary: fake)
        await scheduler.reconcile([reminder()])
        fake.status = .denied
        await scheduler.reconcile([reminder()])
        XCTAssertTrue(fake.pending.isEmpty)
        XCTAssertTrue(scheduler.message.contains("Settings"))
        fake.status = .allowed
        await scheduler.reconcile([reminder()])
        XCTAssertEqual(fake.pending.count, 1)
        XCTAssertEqual(fake.requestCount, 0)
        await scheduler.requestPermission()
        XCTAssertEqual(fake.requestCount, 1)
    }

    func testNotDeterminedNeverPromptsDuringReconcileAndFailureIsVisible() async {
        let fake = FakeCareNotifications()
        fake.status = .notDetermined
        let scheduler = CareReminderScheduler(boundary: fake)
        await scheduler.reconcile([reminder()])
        XCTAssertEqual(fake.requestCount, 0)
        XCTAssertTrue(fake.pending.isEmpty)
        fake.status = .allowed; fake.failAdds = true
        await scheduler.reconcile([reminder()])
        XCTAssertTrue(scheduler.message.contains("couldn't"))
    }

    func testOnlyFutureEnabledOptInTasksWithAPlantAreScheduled() {
        let plant = Plant(name: "Fern")
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(kind: .watering, intervalDays: 3, dueDate: now.addingTimeInterval(3600), plant: plant)
        XCTAssertTrue(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
        task.reminderEnabled = true
        XCTAssertEqual(CareReminderScheduler.reminders(for: [task], now: now).count, 1)
        task.isEnabled = false
        XCTAssertTrue(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
        task.isEnabled = true; task.dueDate = now
        XCTAssertTrue(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
        task.dueDate = now.addingTimeInterval(3600); task.plant = nil
        XCTAssertTrue(CareReminderScheduler.reminders(for: [task], now: now).isEmpty)
    }

    func testCapacityPreservesUnrelatedRequestsAndConcurrentLatestCancelWins() async {
        let fake = FakeCareNotifications()
        let unrelated = CareReminder(id: "other.feature", title: "Other", body: "", date: .distantFuture)
        fake.pending[unrelated.id] = unrelated
        let scheduler = CareReminderScheduler(boundary: fake)
        await scheduler.reconcile((0..<70).map { reminder(String($0)) })
        XCTAssertEqual(fake.pending.count, 64)
        XCTAssertEqual(fake.pending[unrelated.id], unrelated)
        XCTAssertTrue(scheduler.message.contains("63"))
        let oldReadCount = fake.readCount
        let adding = Task { await scheduler.reconcile([reminder()]) }
        while fake.readCount == oldReadCount { await Task.yield() }
        await scheduler.reconcile([])
        await adding.value
        XCTAssertEqual(fake.pending.count, 1)
        XCTAssertEqual(fake.pending[unrelated.id], unrelated)
    }
}
