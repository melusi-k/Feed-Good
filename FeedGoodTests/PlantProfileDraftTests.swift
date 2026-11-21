import Testing
@testable import FeedGood

struct PlantProfileDraftTests {
    @Test func draftStartsFromPlantValues() {
        let plant = Plant(name: "Monstera", species: "Monstera deliciosa", notes: "New leaf")
        let draft = PlantProfileDraft(plant: plant)

        #expect(draft.name == "Monstera")
        #expect(draft.species == "Monstera deliciosa")
        #expect(draft.notes == "New leaf")
    }

    @Test func blankNameIsInvalid() {
        let draft = PlantProfileDraft(name: "")
        #expect(!draft.isValid)
    }

    @Test func whitespaceOnlyNameIsInvalid() {
        let draft = PlantProfileDraft(name: "   \n  ")
        #expect(!draft.isValid)
    }

    @Test func nameWithContentIsValid() {
        let draft = PlantProfileDraft(name: " Fern ")
        #expect(draft.isValid)
    }

    @Test func applyingTrimsAndWritesBackOntoPlant() {
        let plant = Plant(name: "Monstera")
        var draft = PlantProfileDraft(plant: plant)
        draft.name = "  Monty  "
        draft.species = "  Monstera deliciosa "
        draft.notes = "\n Moved to the window  \n"

        draft.applying(to: plant)

        #expect(plant.name == "Monty")
        #expect(plant.species == "Monstera deliciosa")
        #expect(plant.notes == "Moved to the window")
    }

    @Test func applyingBlankSpeciesAndNotesStoresEmptyStrings() {
        let plant = Plant(name: "Monstera", species: "Deliciosa", notes: "Old note")
        var draft = PlantProfileDraft(plant: plant)
        draft.species = "   "
        draft.notes = ""

        draft.applying(to: plant)

        #expect(plant.species == "")
        #expect(plant.notes == "")
    }
}
