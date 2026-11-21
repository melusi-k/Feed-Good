import Foundation
import SwiftData

@Model
final class Plant {
    var id: UUID
    var name: String
    var species: String
    var notes: String
    @Attribute(.externalStorage) var photoData: Data?
    // Optional additions preserve existing plant records during lightweight migration.
    var growingEnvironment: String? = nil
    var lightCondition: String? = nil
    var growingLocation: String? = nil
    @Relationship(deleteRule: .cascade, inverse: \\CareTask.plant) var careTasks: [CareTask]? = []
    @Relationship(deleteRule: .cascade, inverse: \\CareEvent.plant) var careEvents: [CareEvent]? = []
    @Relationship(deleteRule: .cascade, inverse: \\JournalEntry.plant) var journalEntries: [JournalEntry]? = []
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        species: String = "",
        notes: String = "",
        photoData: Data? = nil,
        growingEnvironment: String? = nil,
        lightCondition: String? = nil,
        growingLocation: String? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.notes = notes
        self.photoData = photoData
        self.growingEnvironment = growingEnvironment
        self.lightCondition = lightCondition
        self.growingLocation = growingLocation
        self.createdAt = createdAt
    }
}
