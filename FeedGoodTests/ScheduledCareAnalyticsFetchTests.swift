import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct ScheduledCareAnalyticsFetchTests {
    private func memory() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: FeedGoodSchemaV6.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSince1970: seconds)
    }

    @Test func opportunityAndEventFetchesAreScopedToPlantAndPeriodStart() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        let otherPlant = Plant(name: "Pothos")
        context.insert(plant)
        context.insert(otherPlant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: date(1_800_000_000), plant: plant)
        let otherTask = CareTask(kind: .watering, intervalDays: 7, dueDate: date(1_800_000_000), plant: otherPlant)
        context.insert(task)
        context.insert(otherTask)

        let periodStart = date(1_800_000_000)
        let inScope = CareOpportunity(
            taskID: task.id,
            plantID: plant.id,
            scheduledDueAt: periodStart.addingTimeInterval(86_400)
        )
        let beforeWindow = CareOpportunity(
            taskID: task.id,
            plantID: plant.id,
            scheduledDueAt: periodStart.addingTimeInterval(-86_400)
        )
        let otherPlantOpportunity = CareOpportunity(
            taskID: otherTask.id,
            plantID: otherPlant.id,
            scheduledDueAt: periodStart.addingTimeInterval(86_400)
        )
        context.insert(inScope)
        context.insert(beforeWindow)
        context.insert(otherPlantOpportunity)

        context.insert(CareEvent(task: task, completedAt: periodStart))
        context.insert(CareEvent(task: otherTask, completedAt: periodStart))
        try context.save()

        let opportunities = try context.fetch(
            ScheduledCareAnalyticsFetch.opportunities(plantID: plant.id, periodStart: periodStart)
        )
        #expect(opportunities.map(\.id) == [inScope.id])

        let history = try context.fetch(
            ScheduledCareAnalyticsFetch.opportunityHistory(plantID: plant.id)
        )
        #expect(Set(history.map(\.id)) == [inScope.id, beforeWindow.id])

        let events = try context.fetch(ScheduledCareAnalyticsFetch.events(plantID: plant.id))
        #expect(events.count == 1)
        #expect(events.first?.taskID == task.id)

        let tasks = try context.fetch(ScheduledCareAnalyticsFetch.tasks(plantID: plant.id))
        #expect(tasks.map(\.id) == [task.id])
    }

    @Test func quietMembershipFetchKeepsOnlyActiveMemberships() throws {
        let context = ModelContext(try memory())
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: date(1_800_000_000), plant: plant)
        context.insert(task)
        let quietPeriod = QuietPeriod(plant: plant)
        context.insert(quietPeriod)
        let active = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: "Watering",
            quietPeriod: quietPeriod
        )
        let removed = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: "Watering",
            membershipStatusRaw: QuietPeriodMembershipStatus.removed.rawValue,
            quietPeriod: quietPeriod
        )
        context.insert(active)
        context.insert(removed)
        let otherPlant = Plant(name: "Other")
        context.insert(otherPlant)
        let otherPeriod = QuietPeriod(plant: otherPlant)
        context.insert(otherPeriod)
        let otherActive = QuietPeriodTaskSnapshot(
            taskID: task.id,
            taskTitleSnapshot: "Watering",
            quietPeriod: otherPeriod
        )
        context.insert(otherActive)
        try context.save()

        let periods = try context.fetch(ScheduledCareAnalyticsFetch.quietPeriods(plantID: plant.id))
        // The fetch is plant-scoped on the owning period; the other plant's
        // period is never loaded.
        #expect(periods.map(\.id) == [quietPeriod.id])
        let memberships = ScheduledCareAnalyticsFetch.activeMemberships(in: periods)
        // Only this plant's active membership: ended history and other
        // plants' active memberships stay out of the read model.
        #expect(memberships.map(\.id) == [active.id])
    }
}
