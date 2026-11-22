import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class PlantPersistenceTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Plant.self, configurations: configuration)
    }

    func testProfileEditsPhotoAndGrowingContextPersistAcrossContexts() throws {
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
        XCTAssertEqual(stored.count, 1)
        let reloaded = try XCTUnwrap(stored.first)
        XCTAssertEqual(reloaded.name, "Monty")
        XCTAssertEqual(reloaded.species, "Monstera deliciosa")
        XCTAssertEqual(reloaded.notes, "New leaf unfurling")
        XCTAssertEqual(reloaded.photoData, Data([0x01, 0x02, 0x03]))
        XCTAssertEqual(reloaded.growingEnvironment, .balcony)
        XCTAssertEqual(reloaded.lightCondition, .indirect)
    }

    func testNewPlantsHaveNoAssumedGrowingContext() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()

        let stored = try XCTUnwrap(context.fetch(FetchDescriptor<Plant>()).first)
        XCTAssertEqual(stored.growingEnvironment, .unspecified)
        XCTAssertEqual(stored.lightCondition, .unspecified)
    }

    func testDeletingPlantRemovesItFromStore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()
        context.delete(plant)
        try context.save()
        XCTAssertTrue(try context.fetch(FetchDescriptor<Plant>()).isEmpty)
    }
}
