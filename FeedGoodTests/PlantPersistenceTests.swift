import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class PlantPersistenceTests: XCTestCase {
    private func makeContainer() throws -> ModelContainer {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        return try ModelContainer(for: Plant.self, configurations: configuration)
    }

    func testProfileEditsAndPhotoPersistAcrossContexts() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Monstera")
        context.insert(plant)

        var draft = PlantProfileDraft(plant: plant)
        draft.name = "  Monty  "
        draft.species = " Monstera deliciosa "
        draft.notes = " New leaf unfurling "
        draft.applying(to: plant)
        plant.photoData = Data([0x01, 0x02, 0x03])
        try context.save()

        // A fresh context proves the values came back from the store,
        // not from in-memory view state.
        let verificationContext = ModelContext(container)
        let stored = try verificationContext.fetch(FetchDescriptor<Plant>())

        XCTAssertEqual(stored.count, 1)
        let reloaded = try XCTUnwrap(stored.first)
        XCTAssertEqual(reloaded.name, "Monty")
        XCTAssertEqual(reloaded.species, "Monstera deliciosa")
        XCTAssertEqual(reloaded.notes, "New leaf unfurling")
        XCTAssertEqual(reloaded.photoData, Data([0x01, 0x02, 0x03]))
    }

    func testDeletingPlantRemovesItFromStore() throws {
        let container = try makeContainer()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        try context.save()

        context.delete(plant)
        try context.save()

        let stored = try context.fetch(FetchDescriptor<Plant>())
        XCTAssertTrue(stored.isEmpty)
    }
}
