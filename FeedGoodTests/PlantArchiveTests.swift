import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct PlantArchiveTests {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema(versionedSchema: FeedGoodSchemaV5.self), configurations: configuration)
        return ModelContext(container)
    }

    @Test func archivePersistsWithoutTouchingRecordsAndRestoreKeepsIdentity() throws {
        let context = try makeContext()
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        context.insert(task)
        let event = CareEvent(task: task, note: "Checked soil")
        context.insert(event)
        try JournalStore.save(JournalDraft(note: "A new frond"), plant: plant, entry: nil, context: context)
        try context.save()

        let archivedDate = Date(timeIntervalSince1970: 1_700_000_000)
        try PlantArchive.archive(plant, at: archivedDate, in: context)

        let stored = try context.fetch(FetchDescriptor<Plant>())
        let reloaded = try #require(stored.first)
        #expect(reloaded.archivedAt == archivedDate)
        #expect(reloaded.careTasks?.count == 1)
        #expect(reloaded.careEvents?.count == 1)
        #expect(reloaded.journalEntries?.count == 1)
        #expect(PlantArchive.isArchived(reloaded))

        try PlantArchive.restore(plant, in: context)
        let restored = try #require(try context.fetch(FetchDescriptor<Plant>()).first)
        #expect(restored.archivedAt == nil)
        #expect(restored.id == plant.id)
        #expect(restored.careTasks?.count == 1)
        #expect(restored.careEvents?.count == 1)
        #expect(restored.journalEntries?.count == 1)
    }

    @Test func archiveAndRestoreAreIdempotent() throws {
        let context = try makeContext()
        let plant = Plant(name: "Aloe")
        context.insert(plant)
        try context.save()

        let first = Date(timeIntervalSince1970: 1_700_000_000)
        try PlantArchive.archive(plant, at: first, in: context)
        try PlantArchive.archive(plant, at: .now, in: context)
        #expect(plant.archivedAt == first)

        try PlantArchive.restore(plant, in: context)
        try PlantArchive.restore(plant, in: context)
        #expect(plant.archivedAt == nil)
        #expect(PlantArchive.isArchived(plant) == false)
    }

    @Test func failedArchiveSaveRollsBackAndLeavesPlantActive() throws {
        enum InjectedSaveFailure: Error { case failed }
        let context = try makeContext()
        let plant = Plant(name: "Cactus")
        context.insert(plant)
        try context.save()
        plant.name = "Pending cactus edit"

        #expect(throws: InjectedSaveFailure.self) {
            try PlantArchive.archive(plant, in: context) { _ in
                throw InjectedSaveFailure.failed
            }
        }
        #expect(plant.archivedAt == nil)
        #expect(plant.name == "Pending cactus edit")
        #expect(context.hasChanges)
        #expect(try context.fetch(FetchDescriptor<Plant>()).first?.archivedAt == nil)
    }

    @Test func failedRestoreSaveRollsBackAndLeavesPlantArchived() throws {
        enum InjectedSaveFailure: Error { case failed }
        let context = try makeContext()
        let archivedDate = Date(timeIntervalSince1970: 1_700_000_000)
        let plant = Plant(name: "Fern", archivedAt: archivedDate)
        context.insert(plant)
        try context.save()
        plant.name = "Pending fern edit"

        #expect(throws: InjectedSaveFailure.self) {
            try PlantArchive.restore(plant, in: context) { _ in
                throw InjectedSaveFailure.failed
            }
        }
        #expect(plant.archivedAt == archivedDate)
        #expect(plant.name == "Pending fern edit")
        #expect(context.hasChanges)
        #expect(try context.fetch(FetchDescriptor<Plant>()).first?.archivedAt == archivedDate)
    }
    @Test func archivedPlantCannotReceiveCareCompletion() throws {
        let context = try makeContext()
        let plant = Plant(name: "Fern", archivedAt: Date(timeIntervalSince1970: 1_700_000_000))
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        context.insert(task)
        try context.save()

        #expect(throws: CareRecorderError.archivedPlant) {
            try CareRecorder.complete(task, note: "Should not be recorded", in: context)
        }
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
    }


    @Test func failedArchiveRestoresQuietPeriodOpportunityIdentityAndSchedule() throws {
        enum InjectedFailure: Error { case save }
        let context = try makeContext()
        let plant = Plant(name: "Calathea")
        context.insert(plant)
        let originalDue = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: originalDue, plant: plant)
        context.insert(task)
        let periodStart = Date(timeIntervalSince1970: 1_790_000_000)
        let period = QuietPeriod(
            startAt: periodStart,
            statusRaw: QuietPeriodStatus.active.rawValue,
            activatedAt: periodStart,
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
        let opportunity = try #require(CareOpportunityLifecycle.ensureCurrent(for: task, at: periodStart, in: context))
        try context.save()

        #expect(throws: InjectedFailure.self) {
            try PlantArchive.archive(
                plant,
                at: Date(timeIntervalSince1970: 1_795_000_000),
                in: context,
                save: { _ in throw InjectedFailure.save }
            )
        }

        #expect(plant.archivedAt == nil)
        #expect(period.statusRaw == QuietPeriodStatus.active.rawValue)
        #expect(task.dueDate == originalDue)
        #expect(opportunity.status == .open)
        #expect(try context.fetch(FetchDescriptor<CareOpportunity>()).count == 1)
    }

}
