import XCTest
@testable import FeedGood

final class PlantProfileDraftTests: XCTestCase {
    func testDraftStartsFromPlantValues() {
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa", notes: "New leaf")
        let draft = PlantProfileDraft(plant: plant)

        XCTAssertEqual(draft.name, "Monstera")
        XCTAssertEqual(draft.species, "Monstera deliciosa")
        XCTAssertEqual(draft.notes, "New leaf")
    }

    func testBlankNameIsInvalid() {
        let draft = PlantProfileDraft(name: "")
        XCTAssertFalse(draft.isValid)
    }

    func testWhitespaceOnlyNameIsInvalid() {
        let draft = PlantProfileDraft(name: "   \n  ")
        XCTAssertFalse(draft.isValid)
    }

    func testNameWithContentIsValid() {
        let draft = PlantProfileDraft(name: " Fern ")
        XCTAssertTrue(draft.isValid)
    }

    func testApplyingTrimsAndWritesBackOntoPlant() {
        let plant = Plant(name: "Monstera")
        var draft = PlantProfileDraft(plant: plant)
        draft.name = "  Monty  "
        draft.species = "  Monstera deliciosa "
        draft.notes = "\n Moved to the window  \n"

        draft.applying(to: plant)

        XCTAssertEqual(plant.name, "Monty")
        XCTAssertEqual(plant.species, "Monstera deliciosa")
        XCTAssertEqual(plant.notes, "Moved to the window")
    }

    func testApplyingBlankSpeciesAndNotesStoresEmptyStrings() {
        let plant = Plant(name: "Monstera", species: "Deliciosa", notes: "Old note")
        var draft = PlantProfileDraft(plant: plant)
        draft.species = "   "
        draft.notes = ""

        draft.applying(to: plant)

        XCTAssertEqual(plant.species, "")
        XCTAssertEqual(plant.notes, "")
    }
}
