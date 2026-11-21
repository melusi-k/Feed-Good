import Foundation

/// A working copy of a plant's editable profile details.
struct PlantProfileDraft: Equatable {
    var name: String
    var species: String
    var notes: String
    var growingEnvironment: GrowingEnvironment
    var lightCondition: LightCondition

    init(
        name: String = "",
        species: String = "",
        notes: String = "",
        growingEnvironment: GrowingEnvironment = .unspecified,
        lightCondition: LightCondition = .unspecified
    ) {
        self.name = name
        self.species = species
        self.notes = notes
        self.growingEnvironment = growingEnvironment
        self.lightCondition = lightCondition
    }

    init(plant: Plant) {
        self.init(
            name: plant.name,
            species: plant.species,
            notes: plant.notes,
            growingEnvironment: plant.growingEnvironment,
            lightCondition: plant.lightCondition
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var isValid: Bool { !trimmedName.isEmpty }

    func applying(to plant: Plant) {
        plant.name = trimmedName
        plant.species = species.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.growingEnvironment = growingEnvironment
        plant.lightCondition = lightCondition
    }
}
