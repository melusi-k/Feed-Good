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
    var onPendingRead: (() -> Void)?

    func permission() async -> ReminderPermission { status }
    func requestPermission() async throws -> Bool { status == .allowed }
    func pendingIDs() async -> [String] { pendingReadCount += 1; onPendingRead?(); return Array(pending.keys) }
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
            for: Schema(versionedSchema: FeedGoodSchemaV5.self),
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
        unrelatedTask.customTitle = "Unrelated pending edit"
        let selectedOriginalDate = task.dueDate
        let selectedOriginalInterval = task.intervalDays

        do {
            try await CareTaskEditorPersistence.saveAndReconcile(
                plantID: plant.id,
                taskID: task.id,
                kind: .watering,
                customTitle: "",
                intervalDays: 30,
                dueDate: Date(timeIntervalSince1970: 2_100_000_000),
                isEnabled: true,
                reminderEnabled: true,
                in: container,
                scheduler: CareReminderScheduler(boundary: notifications),
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
        let selectedTaskID = task.id
        let descriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == selectedTaskID })
        let persisted = try #require(verificationContext.fetch(descriptor).first)
        #expect(persisted.dueDate == selectedOriginalDate)
        #expect(persisted.intervalDays == selectedOriginalInterval)
    }

    @Test func successfulSaveReturnsReminderProjectionOnlyAfterCommit() async throws {
        let container = try memory()
        let context = container.mainContext
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
        let notifications = CareTaskEditorNotificationSpy()
        let scheduler = CareReminderScheduler(boundary: notifications)
        var didCommit = false
        notifications.onPendingRead = { #expect(didCommit) }
        try await CareTaskEditorPersistence.saveAndReconcile(
            plantID: plant.id,
            taskID: task.id,
            kind: .watering,
            customTitle: "",
            intervalDays: 30,
            dueDate: nextDate,
            isEnabled: true,
            reminderEnabled: true,
            in: container,
            scheduler: scheduler,
            now: Date(timeIntervalSince1970: 2_000_000_001),
            saveContext: { context in
                try context.save()
                didCommit = true
            }
        )

        #expect(didCommit)
        #expect(notifications.pendingReadCount == 1)
        #expect(notifications.pending.count == 1)
        #expect(notifications.pending.values.first?.date == nextDate)
        #expect(notifications.pending.values.first?.taskID == task.id)

        let selectedTaskID = task.id
        let descriptor = FetchDescriptor<CareTask>(
            predicate: #Predicate { $0.id == selectedTaskID }
        )
        let refreshedMainContextTask = try #require(context.fetch(descriptor).first)
        #expect(refreshedMainContextTask.intervalDays == 30)
        #expect(refreshedMainContextTask.dueDate == nextDate)

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

    @Test func failedDeletePreservesTaskHistoryPendingRemindersAndUnrelatedViewEdits() async throws {
        let container = try memory()
        let viewContext = ModelContext(container)
        let plant = Plant(name: "Fern")
        let otherPlant = Plant(name: "Aloe")
        viewContext.insert(plant)
        viewContext.insert(otherPlant)
        let dueDate = Date(timeIntervalSince1970: 2_000_000_000)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: dueDate, reminderEnabled: true, plant: plant)
        let unrelatedTask = CareTask(kind: .feeding, intervalDays: 14, dueDate: dueDate, plant: otherPlant)
        let event = CareEvent(task: task, completedAt: dueDate, note: "Watered")
        viewContext.insert(task)
        viewContext.insert(unrelatedTask)
        viewContext.insert(event)
        try viewContext.save()

        let reminder = CareReminder(
            id: CareReminderScheduler.prefix + task.id.uuidString,
            title: "A moment with Fern",
            body: "Watering",
            date: dueDate,
            taskID: task.id,
            plantID: plant.id
        )
        let notifications = CareTaskEditorNotificationSpy()
        notifications.pending[reminder.id] = reminder
        unrelatedTask.customTitle = "Unrelated pending edit"

        do {
            try await CareTaskEditorPersistence.deleteAndReconcile(
                plantID: plant.id,
                taskID: task.id,
                in: container,
                scheduler: CareReminderScheduler(boundary: notifications),
                now: Date(timeIntervalSince1970: 1_900_000_000),
                saveContext: { _ in throw TestSaveError.failed }
            )
            Issue.record("Expected the injected deletion failure.")
        } catch TestSaveError.failed {
            // Expected: a failed delete must not reconcile reminders.
        }

        #expect(viewContext.hasChanges)
        #expect(unrelatedTask.customTitle == "Unrelated pending edit")
        #expect(notifications.pending[reminder.id] == reminder)
        #expect(notifications.pendingReadCount == 0)
        #expect(notifications.removed.isEmpty)
        #expect(notifications.additions.isEmpty)

        let verificationContext = ModelContext(container)
        let taskID = task.id
        let taskDescriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == taskID })
        let eventID = event.id
        let eventDescriptor = FetchDescriptor<CareEvent>(predicate: #Predicate { $0.id == eventID })
        #expect(try verificationContext.fetch(taskDescriptor).count == 1)
        #expect(try verificationContext.fetch(eventDescriptor).count == 1)
    }

    @Test func successfulDeleteCommitsBeforeReminderReconciliationAndRetainsCareHistory() async throws {
        let container = try memory()
        let context = container.mainContext
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let dueDate = Date(timeIntervalSince1970: 2_000_000_000)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: dueDate, reminderEnabled: true, plant: plant)
        let event = CareEvent(task: task, completedAt: dueDate, note: "Watered")
        context.insert(task)
        context.insert(event)
        try context.save()

        let notifications = CareTaskEditorNotificationSpy()
        let scheduler = CareReminderScheduler(boundary: notifications)
        var didCommit = false
        notifications.onPendingRead = { #expect(didCommit) }
        try await CareTaskEditorPersistence.deleteAndReconcile(
            plantID: plant.id,
            taskID: task.id,
            in: container,
            scheduler: scheduler,
            now: Date(timeIntervalSince1970: 2_100_000_000),
            saveContext: { context in
                try context.save()
                didCommit = true
            }
        )

        #expect(didCommit)
        #expect(notifications.pendingReadCount == 1)
        let taskID = task.id
        let taskDescriptor = FetchDescriptor<CareTask>(predicate: #Predicate { $0.id == taskID })
        let eventID = event.id
        let eventDescriptor = FetchDescriptor<CareEvent>(predicate: #Predicate { $0.id == eventID })
        #expect(try context.fetch(taskDescriptor).isEmpty)
        #expect(try context.fetch(eventDescriptor).count == 1)
        #expect(try context.fetch(eventDescriptor).first?.taskID == task.id)
        #expect(try context.fetch(eventDescriptor).first?.taskTitle == "Watering")
    }


    @Test func deleteRejectsArchivedPlantWithoutChangingItsTask() throws {
        let container = try memory()
        let context = ModelContext(container)
        let plant = Plant(name: "Archived fern")
        plant.archivedAt = Date(timeIntervalSince1970: 2_000_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: Date(timeIntervalSince1970: 2_100_000_000),
            plant: plant
        )
        context.insert(plant)
        context.insert(task)
        try context.save()

        #expect(throws: CareTaskEditorPersistenceError.archivedPlant) {
            try CareTaskEditorPersistence.delete(
                plantID: plant.id,
                taskID: task.id,
                in: container
            )
        }

        let verificationContext = ModelContext(container)
        let taskID = task.id
        let descriptor = FetchDescriptor<CareTask>(
            predicate: #Predicate { $0.id == taskID }
        )
        #expect(try verificationContext.fetch(descriptor).count == 1)
    }

    @Test func deleteRejectsTaskOwnedByAnotherPlantWithoutDeletingIt() throws {
        let container = try memory()
        let context = ModelContext(container)
        let selectedPlant = Plant(name: "Fern")
        let owningPlant = Plant(name: "Aloe")
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: Date(timeIntervalSince1970: 2_100_000_000),
            plant: owningPlant
        )
        context.insert(selectedPlant)
        context.insert(owningPlant)
        context.insert(task)
        try context.save()

        #expect(throws: CareTaskEditorPersistenceError.taskBelongsToAnotherPlant) {
            try CareTaskEditorPersistence.delete(
                plantID: selectedPlant.id,
                taskID: task.id,
                in: container
            )
        }

        let verificationContext = ModelContext(container)
        let taskID = task.id
        let descriptor = FetchDescriptor<CareTask>(
            predicate: #Predicate { $0.id == taskID }
        )
        #expect(try verificationContext.fetch(descriptor).count == 1)
    }

    @Test func taskCreationRescheduleDisableAndDeleteMaintainOpportunityLedger() throws {
        let container = try memory()
        let context = container.mainContext
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()
        let now = Date(timeIntervalSince1970: 1_900_000_000)
        let firstDue = Date(timeIntervalSince1970: 2_000_000_000)

        _ = try CareTaskEditorPersistence.save(
            plantID: plant.id,
            taskID: nil,
            kind: .watering,
            customTitle: "",
            intervalDays: 7,
            dueDate: firstDue,
            isEnabled: true,
            reminderEnabled: false,
            in: container,
            now: now
        )
        var verify = ModelContext(container)
        var task = try #require(verify.fetch(FetchDescriptor<CareTask>()).first)
        let taskID = task.id
        var opportunities = try verify.fetch(FetchDescriptor<CareOpportunity>())
        #expect(opportunities.count == 1)
        let firstOpportunity = try #require(opportunities.first)
        #expect(firstOpportunity.status == .open)
        #expect(firstOpportunity.scheduledDueAt == firstDue)

        let replacementDue = Date(timeIntervalSince1970: 2_050_000_000)
        _ = try CareTaskEditorPersistence.save(
            plantID: plant.id,
            taskID: taskID,
            kind: .watering,
            customTitle: "",
            intervalDays: 7,
            dueDate: replacementDue,
            isEnabled: true,
            reminderEnabled: false,
            in: container,
            now: now
        )
        verify = ModelContext(container)
        opportunities = try verify.fetch(FetchDescriptor<CareOpportunity>())
        #expect(opportunities.count == 2)
        #expect(opportunities.first { $0.id == firstOpportunity.id }?.status == .cancelled)
        #expect(opportunities.first { $0.status == .open }?.scheduledDueAt == replacementDue)

        _ = try CareTaskEditorPersistence.save(
            plantID: plant.id,
            taskID: taskID,
            kind: .watering,
            customTitle: "",
            intervalDays: 7,
            dueDate: replacementDue,
            isEnabled: false,
            reminderEnabled: false,
            in: container,
            now: now
        )
        verify = ModelContext(container)
        opportunities = try verify.fetch(FetchDescriptor<CareOpportunity>())
        #expect(opportunities.allSatisfy { $0.status == .cancelled })

        _ = try CareTaskEditorPersistence.save(
            plantID: plant.id,
            taskID: taskID,
            kind: .watering,
            customTitle: "",
            intervalDays: 7,
            dueDate: replacementDue,
            isEnabled: true,
            reminderEnabled: false,
            in: container,
            now: now
        )
        try CareTaskEditorPersistence.delete(plantID: plant.id, taskID: taskID, in: container, now: now)
        verify = ModelContext(container)
        opportunities = try verify.fetch(FetchDescriptor<CareOpportunity>())
        #expect(opportunities.allSatisfy { $0.status == .cancelled })
        #expect(try verify.fetch(FetchDescriptor<CareTask>()).isEmpty)
    }

}

private enum TestSaveError: Error {
    case failed
}
