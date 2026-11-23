import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
private final class CareTaskEditorNotificationSpy: CareNotificationBoundary {
    var status: ReminderPermission = .allowed
    var pending: [String: CareReminder] = [:]
    var removed: [String] = []
    var additions: [CareReminder] = []
    var pendingReadCount = 0

    func permission() async -> ReminderPermission { status }
    func requestPermission() async throws -> Bool { status == .allowed }
    func pendingIDs() async -> [String] { pendingReadCount += 1; return Array(pending.keys) }
    func remove(_ ids: [String]) {
        removed.append(contentsOf: ids)
        for id in ids { pending[id] = nil }
    }
    func add(_ reminder: CareReminder) async throws {
        additions.append(reminder)
        pending[reminder.id] = reminder
    }
}

@MainActor
struct CareTaskEditorPersistenceTests {
    private func memory() throws -> ModelContainer {
        try ModelContainer(
            for: Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func failedSaveLeavesSelectedTaskAndPendingRemindersUnchangedWithoutRollingBackOtherEdits() async throws {
        let container = try memory()
        let viewContext = ModelContext(container)
        let plant = Plant(name: "Fern")
        let otherPlant = Plant(name: "Aloe")
        viewContext.insert(plant)
        viewContext.insert(otherPlant)

        let dueDate = Date(timeIntervalSince1970: 2_000_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: dueDate,
            reminderEnabled: true,
            plant: plant
        )
        let unrelatedTask = CareTask(
            kind: .feeding,
            intervalDays: 14,
            dueDate: dueDate,
            plant: otherPlant
        )
        viewContext.insert(task)
        viewContext.insert(unrelatedTask)
        try viewContext.save()

        let originalReminder = CareReminder(
            id: CareReminderScheduler.prefix + task.id.uuidString,
            title: "A moment with Fern",
            body: "Watering",
            date: dueDate,
            taskID: task.id,
            plantID: plant.id
        )
        let notifications = CareTaskEditorNotificationSpy()
        notifications.pending[originalReminder.id] = originalReminder
        let scheduler = CareReminderScheduler(boundary: notifications)

        unrelatedTask.customTitle = "Unrelated pending edit"
        let selectedOriginalDate = task.dueDate
        let selectedOriginalInterval = task.intervalDays

        do {
            _ = try CareTaskEditorPersistence.save(
                plantID: plant.id,
                taskID: task.id,
                kind: .watering,
                customTitle: "",
                intervalDays: 30,
                dueDate: Date(timeIntervalSince1970: 2_100_000_000),
                isEnabled: true,
                reminderEnabled: true,
                in: container,
                now: Date(timeIntervalSince1970: 1_900_000_000),
                saveContext: { _ in throw TestSaveError.failed }
            )
            Issue.record("Expected the injected persistence failure.")
        } catch TestSaveError.failed {
            // Expected: no reminder reconciliation is requested after a throw.
        }

        #expect(task.dueDate == selectedOriginalDate)
        #expect(task.intervalDays == selectedOriginalInterval)
        #expect(unrelatedTask.customTitle == "Unrelated pending edit")
        #expect(viewContext.hasChanges)
        #expect(notifications.pending[originalReminder.id] == originalReminder)
        #expect(notifications.removed.isEmpty)
        #expect(notifications.additions.isEmpty)
        #expect(notifications.pendingReadCount == 0)
        let verificationContext = ModelContext(container)
        let descriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == task.id })
        let persisted = try #require(verificationContext.fetch(descriptor).first)
        #expect(persisted.dueDate == selectedOriginalDate)
        #expect(persisted.intervalDays == selectedOriginalInterval)
    }

    @Test func successfulSaveReturnsReminderProjectionOnlyAfterCommit() async throws {
        let container = try memory()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let originalDate = Date(timeIntervalSince1970: 2_000_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: originalDate,
            reminderEnabled: true,
            plant: plant
        )
        context.insert(task)
        try context.save()

        let nextDate = Date(timeIntervalSince1970: 2_100_000_000)
        let reminders = try CareTaskEditorPersistence.save(
            plantID: plant.id,
            taskID: task.id,
            kind: .watering,
            customTitle: "",
            intervalDays: 30,
            dueDate: nextDate,
            isEnabled: true,
            reminderEnabled: true,
            in: container,
            now: Date(timeIntervalSince1970: 2_000_000_001)
        )

        #expect(reminders.count == 1)
        #expect(reminders.first?.date == nextDate)
        #expect(reminders.first?.taskID == task.id)

        let verificationContext = ModelContext(container)
        let descriptor = FetchDescriptor<CareTask>(
            predicate: #Predicate { $0.id == task.id }
        )
        let persisted = try #require(verificationContext.fetch(descriptor).first)
        #expect(persisted.intervalDays == 30)
        #expect(persisted.dueDate == nextDate)

        let notifications = CareTaskEditorNotificationSpy()
        let scheduler = CareReminderScheduler(boundary: notifications)
        await scheduler.reconcile(reminders)
        #expect(notifications.pending.count == 1)
        #expect(notifications.pending.values.first?.date == nextDate)
        #expect(notifications.pendingReadCount == 1)
    }

    @Test func saveRejectsTasksThatDoNotBelongToTheSelectedPlant() throws {
        let container = try memory()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        let otherPlant = Plant(name: "Aloe")
        context.insert(plant)
        context.insert(otherPlant)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: .distantFuture,
            plant: otherPlant
        )
        context.insert(task)
        try context.save()

        #expect(throws: CareTaskEditorPersistenceError.taskBelongsToAnotherPlant) {
            try CareTaskEditorPersistence.save(
                plantID: plant.id,
                taskID: task.id,
                kind: .watering,
                customTitle: "",
                intervalDays: 7,
                dueDate: .distantFuture,
                isEnabled: true,
                reminderEnabled: false,
                in: container
            )
        }
    }
}

private enum TestSaveError: Error {
    case failed
}
