import XCTest
@testable import FeedGood

final class PlantModelTests: XCTestCase {
    func testPlantKeepsProvidedDetails() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let plant = Plant(
            name: "Monstera",
            species: "Monstera deliciosa",
            notes: "New leaf unfurling",
            createdAt: createdAt
        )

        XCTAssertEqual(plant.name, "Monstera")
        XCTAssertEqual(plant.species, "Monstera deliciosa")
        XCTAssertEqual(plant.notes, "New leaf unfurling")
        XCTAssertEqual(plant.createdAt, createdAt)
    }

    func testPlantHasUniqueIdentityByDefault() {
        let first = Plant(name: "Fern")
        let second = Plant(name: "Fern")

        XCTAssertNotEqual(first.id, second.id)
    }
}
