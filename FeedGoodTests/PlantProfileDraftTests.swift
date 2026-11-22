import Testing
@testable import FeedGood

struct PlantProfileDraftTests {
    @Test func draftStartsFromPlantValues() {
        let plant = Plant(
            name: "Monstera",
            species: "Monstera deliciosa",
            notes: "New leaf",
            growingEnvironment: .balcony,
            lightCondition: .indirect
        )
        let draft = PlantProfileDraft(plant: plant)

        #expect(draft.name == "Monstera")
        #expect(draft.species == "Monstera deliciosa")
        #expect(draft.notes == "New leaf")
        #expect(draft.growingEnvironment == .balcony)
        #expect(draft.lightCondition == .indirect)
    }

    @Test func blankAndWhitespaceOnlyNamesAreInvalid() {
        #expect(PlantProfileDraft(name: "").isValid == false)
        #expect(PlantProfileDraft(name: "   \n  ").isValid == false)
        #expect(PlantProfileDraft(name: " Fern ").isValid)
    }

    @Test func applyingTrimsAndWritesBackOntoPlant() {
        let plant = Plant(name: "Monstera")
        var draft = PlantProfileDraft(plant: plant)
        draft.name = "  Monty  "
        draft.species = "  Monstera deliciosa "
        draft.notes = "\n Moved to the window  \n"
        draft.growingEnvironment = .indoor
        draft.lightCondition = .direct

        draft.applying(to: plant)

        #expect(plant.name == "Monty")
        #expect(plant.species == "Monstera deliciosa")
        #expect(plant.notes == "Moved to the window")
        #expect(plant.growingEnvironment == .indoor)
        #expect(plant.lightCondition == .direct)
    }

    @Test func draftDefaultsGrowingContextToUnspecified() {
        let draft = PlantProfileDraft(name: "Fern")
        #expect(draft.growingEnvironment == .unspecified)
        #expect(draft.lightCondition == .unspecified)
    }

    @Test func optionalGrowingContextCanBeCleared() {
        let plant = Plant(name: "Fern", growingEnvironment: .balcony, lightCondition: .low)
        var draft = PlantProfileDraft(plant: plant)
        draft.growingEnvironment = .unspecified
        draft.lightCondition = .unspecified

        draft.applying(to: plant)

        #expect(plant.growingEnvironment == .unspecified)
        #expect(plant.lightCondition == .unspecified)
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
