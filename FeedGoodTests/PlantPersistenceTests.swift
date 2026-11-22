import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct PlantPersistenceTests {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Plant.self, configurations: configuration)
    }

    @Test func profileEditsPhotoAndGrowingContextPersistAcrossContexts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Monstera")
        context.insert(plant)

        var draft = PlantProfileDraft(plant: plant)
        draft.name = "  Monty  "
        draft.species = " Monstera deliciosa "
        draft.notes = " New leaf unfurling "
        draft.growingEnvironment = .balcony
        draft.lightCondition = .indirect
        draft.applying(to: plant)
        plant.photoData = Data([0x01, 0x02, 0x03])
        try context.save()

        let verificationContext = ModelContext(container)
        let stored = try verificationContext.fetch(FetchDescriptor<Plant>())
        #expect(stored.count == 1)
        let reloaded = try #require(stored.first)
        #expect(reloaded.name == "Monty")
        #expect(reloaded.species == "Monstera deliciosa")
        #expect(reloaded.notes == "New leaf unfurling")
        #expect(reloaded.photoData == Data([0x01, 0x02, 0x03]))
        #expect(reloaded.growingEnvironment == .balcony)
        #expect(reloaded.lightCondition == .indirect)
    }

    @Test func newPlantsHaveNoAssumedGrowingContext() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()

        let stored = try #require(context.fetch(FetchDescriptor<Plant>()).first)
        #expect(stored.growingEnvironment == .unspecified)
        #expect(stored.lightCondition == .unspecified)
    }

    @Test func deletingPlantRemovesItFromStore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()
        context.delete(plant)
        try context.save()

        #expect(try context.fetch(FetchDescriptor<Plant>()).isEmpty)
    }
}
