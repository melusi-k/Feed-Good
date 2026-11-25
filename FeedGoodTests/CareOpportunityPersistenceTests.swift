import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct CareOpportunityPersistenceTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }

    @Test func opportunityPersistsItsImmutableIdentityAndOptionalCompletionLink() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(
            kind: .watering,
            intervalDays: 7,
            dueDate: date("2026-12-01T09:00:00Z"),
            plant: plant
        )
        context.insert(task)
        let event = CareEvent(task: task, completedAt: date("2026-12-01T09:05:00Z"))
        context.insert(event)
        let due = task.dueDate
        let opportunity = CareOpportunity(
            taskID: task.id,
            plantID: plant.id,
            scheduledDueAt: due,
            status: .completed,
            careEventID: event.id,
            createdAt: date("2026-11-25T12:00:00Z"),
            updatedAt: date("2026-12-01T09:05:00Z")
        )
        context.insert(opportunity)
        try context.save()

        let opportunityID = opportunity.id
        let fetched = try #require(
            context.fetch(FetchDescriptor<CareOpportunity>()).first { $0.id == opportunityID }
        )
        #expect(fetched.taskID == task.id)
        #expect(fetched.plantID == plant.id)
        #expect(fetched.scheduledDueAt == due)
        #expect(fetched.status == .completed)
        #expect(fetched.careEventID == event.id)
    }

    @Test func v4StoreMigratesToV5WithoutReconstructingHistoricalOpportunities() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let storeURL = folder.appendingPathComponent("v4-garden.store")

        let plantID = UUID()
        let taskID = UUID()
        let eventID = UUID()
        let due = date("2026-11-01T09:00:00Z")
        let completed = date("2026-10-25T09:00:00Z")

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV4.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            let context = ModelContext(container)
            let plant = Plant(id: plantID, name: "Legacy Fern")
            let task = CareTask(
                id: taskID,
                kind: .watering,
                intervalDays: 7,
                dueDate: due,
                plant: plant
            )
            let event = CareEvent(
                id: eventID,
                taskID: taskID,
                taskTitle: "Watering",
                completedAt: completed,
                note: "Historical event",
                plant: plant
            )
            context.insert(plant)
            context.insert(task)
            context.insert(event)
            try context.save()
        }

        do {
            let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
            let configuration = ModelConfiguration(schema: schema, url: storeURL)
            let container = try ModelContainer(
                for: schema,
                migrationPlan: FeedGoodMigrationPlan.self,
                configurations: [configuration]
            )
            let context = ModelContext(container)
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let tasks = try context.fetch(FetchDescriptor<CareTask>())
            let events = try context.fetch(FetchDescriptor<CareEvent>())
            let opportunities = try context.fetch(FetchDescriptor<CareOpportunity>())

            #expect(plants.count == 1)
            #expect(plants.first?.id == plantID)
            #expect(tasks.count == 1)
            #expect(tasks.first?.id == taskID)
            #expect(tasks.first?.dueDate == due)
            #expect(events.count == 1)
            #expect(events.first?.id == eventID)
            #expect(events.first?.completedAt == completed)
            #expect(opportunities.isEmpty)
        }
    }

    @Test func currentOpportunityIsIdempotentAndExplicitRescheduleReplacesIt() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let originalDue = date("2026-12-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: originalDue, plant: plant)
        context.insert(task)

        let first = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: date("2026-11-25T12:00:00Z"), in: context))
        let repeated = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: date("2026-11-25T12:01:00Z"), in: context))
        #expect(first.id == repeated.id)

        let replacementDue = date("2026-12-05T09:00:00Z")
        task.dueDate = replacementDue
        try CareOpportunityLifecycle.applyScheduleChange(
            to: task,
            previousDueDate: originalDue,
            at: date("2026-11-26T12:00:00Z"),
            in: context
        )

        let opportunities = try context.fetch(FetchDescriptor<CareOpportunity>())
        #expect(opportunities.count == 2)
        #expect(opportunities.first { $0.id == first.id }?.status == .cancelled)
        let replacement = try #require(opportunities.first { $0.status == .open })
        #expect(replacement.scheduledDueAt == replacementDue)
        #expect(replacement.id != first.id)
    }

    @Test func acceptedCompletionLinksExactlyOneEventAndDeletingItReopensWithoutRewindingTask() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        let due = date("2026-11-25T09:00:00Z")
        let completedAt = date("2026-11-25T09:05:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        let opportunity = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: date("2026-11-24T12:00:00Z"), in: context))

        try CareRecorder.complete(task, note: "Watered", at: completedAt, in: context)
        let event = try #require(try context.fetch(FetchDescriptor<CareEvent>()).first)
        #expect(opportunity.status == .completed)
        #expect(opportunity.careEventID == event.id)
        let nextDue = task.dueDate
        #expect(nextDue == CareSchedule.nextDate(after: completedAt, intervalDays: 7))
        #expect(try context.fetch(FetchDescriptor<CareOpportunity>()).filter { $0.status == .open }.count == 1)

        try CareRecorder.delete(event, in: context, at: date("2026-11-26T12:00:00Z"))
        #expect(opportunity.status == .open)
        #expect(opportunity.careEventID == nil)
        #expect(task.dueDate == nextDue)
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
    }

    @Test func earlyRecordedCareDoesNotCompleteTheFutureScheduledOpportunity() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Pothos")
        context.insert(plant)
        let due = date("2026-12-01T09:00:00Z")
        let completedAt = date("2026-11-25T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        let original = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: completedAt, in: context))

        try CareRecorder.complete(task, note: "Early check", at: completedAt, in: context)

        let event = try #require(try context.fetch(FetchDescriptor<CareEvent>()).first)
        let opportunities = try context.fetch(FetchDescriptor<CareOpportunity>())
        #expect(event.taskID == task.id)
        #expect(original.status == .cancelled)
        #expect(original.careEventID == nil)
        #expect(opportunities.filter { $0.status == .open }.count == 1)
        #expect(opportunities.first { $0.status == .open }?.scheduledDueAt == task.dueDate)
        #expect(opportunities.first { $0.status == .open }?.careEventID == nil)
    }

    @Test func failedCompletionRollsBackEventTaskDateAndOpportunityLifecycleTogether() throws {
        enum InjectedFailure: Error { case save }
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let due = date("2026-11-25T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        let opportunity = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: date("2026-11-24T12:00:00Z"), in: context))
        try context.save()

        #expect(throws: InjectedFailure.self) {
            try CareRecorder.complete(task, note: "Will fail", at: due, in: context) { _ in
                throw InjectedFailure.save
            }
        }

        #expect(task.dueDate == due)
        #expect(opportunity.status == .open)
        #expect(opportunity.careEventID == nil)
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<CareOpportunity>()).count == 1)
    }


    @Test func foregroundBootstrapCreatesOnlyTheCurrentScheduleInstance() throws {
        let container = try memory()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let due = date("2026-11-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: due, plant: plant)
        context.insert(task)
        let historical = CareEvent(
            taskID: task.id,
            taskTitle: "Watering",
            completedAt: date("2026-10-20T09:00:00Z"),
            note: "Old event",
            plant: plant
        )
        context.insert(historical)
        try context.save()

        try CareOpportunityLifecycle.bootstrap(in: container, at: date("2026-11-25T12:00:00Z"))

        let opportunities = try context.fetch(FetchDescriptor<CareOpportunity>())
        #expect(opportunities.count == 1)
        #expect(opportunities.first?.scheduledDueAt == due)
        #expect(opportunities.first?.status == .open)
        #expect(opportunities.first?.careEventID == nil)
        #expect(historical.completedAt == date("2026-10-20T09:00:00Z"))
    }

    @Test func quietPeriodResumeCancelsSupersededOpportunityAndCreatesResumedOne() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Calathea")
        context.insert(plant)
        let originalDue = date("2026-12-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: originalDue, plant: plant)
        context.insert(task)
        let period = QuietPeriod(
            startAt: date("2026-11-25T00:00:00Z"),
            statusRaw: QuietPeriodStatus.active.rawValue,
            activatedAt: date("2026-11-25T00:00:00Z"),
            plant: plant
        )
        let snapshot = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: task.title,
            remainingCalendarDays: 6,
            originalDueHour: 9,
            originalDueMinute: 0,
            originalDueSecond: 0,
            frozenIntervalDays: 7,
            quietPeriod: period
        )
        context.insert(period)
        context.insert(snapshot)
        let original = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: date("2026-11-24T12:00:00Z"), in: context))

        try QuietPeriodLifecycle.end(
            period,
            at: date("2026-11-26T12:00:00Z"),
            in: context,
            calendar: Calendar(identifier: .gregorian)
        )

        let opportunities = try context.fetch(FetchDescriptor<CareOpportunity>())
        #expect(original.status == .cancelled)
        #expect(task.dueDate == date("2026-12-03T09:00:00Z"))
        #expect(opportunities.filter { $0.status == .open }.count == 1)
        #expect(opportunities.first { $0.status == .open }?.scheduledDueAt == task.dueDate)
    }

    @Test func failedQuietPeriodResumeRestoresOriginalOpportunityIdentityAndDueDate() throws {
        enum InjectedFailure: Error { case save }
        let context = ModelContext(try memory())
        let plant = Plant(name: "Calathea")
        context.insert(plant)
        let originalDue = date("2026-12-01T09:00:00Z")
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: originalDue, plant: plant)
        context.insert(task)
        let period = QuietPeriod(
            startAt: date("2026-11-25T00:00:00Z"),
            statusRaw: QuietPeriodStatus.active.rawValue,
            activatedAt: date("2026-11-25T00:00:00Z"),
            plant: plant
        )
        let snapshot = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: task.title,
            remainingCalendarDays: 6,
            originalDueHour: 9,
            originalDueMinute: 0,
            originalDueSecond: 0,
            frozenIntervalDays: 7,
            quietPeriod: period
        )
        context.insert(period)
        context.insert(snapshot)
        let original = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: date("2026-11-24T12:00:00Z"), in: context))
        try context.save()

        #expect(throws: InjectedFailure.self) {
            try QuietPeriodLifecycle.end(
                period,
                at: date("2026-11-26T12:00:00Z"),
                in: context,
                calendar: Calendar(identifier: .gregorian),
                save: { _ in throw InjectedFailure.save }
            )
        }

        #expect(period.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(task.dueDate == originalDue)
        #expect(original.status == .open)
        #expect(try context.fetch(FetchDescriptor<CareOpportunity>()).count == 1)
    }

}
