import Foundation
import SwiftData

@Model
final class Plant {
    var id: UUID
    var name: String
    var species: String
    var notes: String
    @Attribute(.externalStorage) var photoData: Data?
    @Relationship(deleteRule: .cascade, inverse: \CareTask.plant) var careTasks: [CareTask]? = []
    @Relationship(deleteRule: .cascade, inverse: \CareEvent.plant) var careEvents: [CareEvent]? = []
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        species: String = "",
        notes: String = "",
        photoData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.notes = notes
        self.photoData = photoData
        self.createdAt = createdAt
    }
}
