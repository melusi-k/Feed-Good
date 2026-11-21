import XCTest
@testable import FeedGood

final class PlantProfileDraftTests: XCTestCase {
    func testDraftStartsFromPlantValues() {
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa", notes: "New leaf", growingEnvironment: .balcony, lightCondition: .indirect)
        let draft = PlantProfileDraft(plant: plant)

        XCTAssertEqual(draft.name, "Monstera")
        XCTAssertEqual(draft.species, "Monstera deliciosa")
        XCTAssertEqual(draft.notes, "New leaf")
        XCTAssertEqual(draft.growingEnvironment, .balcony)
        XCTAssertEqual(draft.lightCondition, .indirect)
    }

    func testBlankNameIsInvalid() {
        XCTAssertFalse(PlantProfileDraft(name: "").isValid)
        XCTAssertFalse(PlantProfileDraft(name: "   \n  ").isValid)
        XCTAssertTrue(PlantProfileDraft(name: " Fern ").isValid)
    }

    func testApplyingTrimsAndWritesBackOntoPlant() {
        let plant = Plant(name: "Monstera")
        var draft = PlantProfileDraft(plant: plant)
        draft.name = "  Monty  "
        draft.species = "  Monstera deliciosa "
        draft.notes = "\n Moved to the window  \n"
        draft.growingEnvironment = .indoor
        draft.lightCondition = .direct

        draft.applying(to: plant)

        XCTAssertEqual(plant.name, "Monty")
        XCTAssertEqual(plant.species, "Monstera deliciosa")
        XCTAssertEqual(plant.notes, "Moved to the window")
        XCTAssertEqual(plant.growingEnvironment, .indoor)
        XCTAssertEqual(plant.lightCondition, .direct)
    }

    func testOptionalContextDefaultsToUnspecifiedAndCanBeCleared() {
        let plant = Plant(name: "Fern", growingEnvironment: .balcony, lightCondition: .low)
        var draft = PlantProfileDraft(plant: plant)
        draft.growingEnvironment = .unspecified
        draft.lightCondition = .unspecified
        draft.applying(to: plant)

        XCTAssertEqual(plant.growingEnvironment, .unspecified)
        XCTAssertEqual(plant.lightCondition, .unspecified)
    }
}
