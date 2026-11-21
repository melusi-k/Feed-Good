import Foundation

/// User-described growing context. These values are observations, not measurements.
enum GrowingEnvironment: String, CaseIterable, Identifiable {
    case indoors = "Indoors"
    case outdoors = "Outdoors"
    case balcony = "Balcony"
    case other = "Other"
    var id: String { rawValue }
}

enum LightCondition: String, CaseIterable, Identifiable {
    case low = "Low light"
    case indirect = "Bright indirect"
    case direct = "Direct sun"
    case mixed = "Mixed light"
    case unsure = "Not sure"
    var id: String { rawValue }
}

/// A working copy of a plant's editable profile details.
/// Trimming and validation live here so the SwiftUI views stay declarative
/// and the rules stay unit-testable.
struct PlantProfileDraft: Equatable {
    var name: String
    var species: String
    var notes: String
    var growingEnvironment: String
    var lightCondition: String
    var growingLocation: String

    init(name: String = "", species: String = "", notes: String = "", growingEnvironment: String = "", lightCondition: String = "", growingLocation: String = "") {
        self.name = name
        self.species = species
        self.notes = notes
        self.growingEnvironment = growingEnvironment
        self.lightCondition = lightCondition
        self.growingLocation = growingLocation
    }

    init(plant: Plant) {
        self.init(
            name: plant.name,
            species: plant.species,
            notes: plant.notes,
            growingEnvironment: plant.growingEnvironment ?? "",
            lightCondition: plant.lightCondition ?? "",
            growingLocation: plant.growingLocation ?? ""
        )
    }

    var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// A plant must keep a name. Species, notes and context are optional.
    var isValid: Bool {
        !trimmedName.isEmpty
    }

    /// Writes the trimmed values back onto the authoritative Plant record.
    func applying(to plant: Plant) {
        plant.name = trimmedName
        plant.species = species.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.growingEnvironment = growingEnvironment.isEmpty ? nil : growingEnvironment
        plant.lightCondition = lightCondition.isEmpty ? nil : lightCondition
        let location = growingLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        plant.growingLocation = location.isEmpty ? nil : location
    }
}
