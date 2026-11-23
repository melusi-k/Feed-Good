import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct PlantArchiveTests {
    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self]), configurations: configuration)
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

}
