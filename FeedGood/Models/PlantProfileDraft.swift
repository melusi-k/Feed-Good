import Foundation

/// A working copy of a plant's editable profile details.
/// Trimming and validation live here so the SwiftUI views stay declarative
/// and the rules stay unit-testable.
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

    /// A plant must keep a name. Species and notes are optional.
    var isValid: Bool {
        !trimmedName.isEmpty
    }

    /// Writes the trimmed values back onto the authoritative Plant record.
    func applying(to plant: Plant) {
        plant.name = trimmedName
        plant.species = species.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.growingEnvironment = growingEnvironment
        plant.lightCondition = lightCondition
    }
}
