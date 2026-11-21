import Foundation
import Testing
@testable import FeedGood

struct PlantModelTests {
    @Test func plantKeepsProvidedDetails() {
        let createdAt = Date(timeIntervalSince1970: 1_700_000_000)
        let plant = Plant(
            name: "Monstera",
            species: "Monstera deliciosa",
            notes: "New leaf unfurling",
            createdAt: createdAt
        )

        #expect(plant.name == "Monstera")
        #expect(plant.species == "Monstera deliciosa")
        #expect(plant.notes == "New leaf unfurling")
        #expect(plant.createdAt == createdAt)
    }

    @Test func plantHasUniqueIdentityByDefault() {
        let first = Plant(name: "Fern")
        let second = Plant(name: "Fern")

        #expect(first.id != second.id)
    }
}
