import Foundation
import SwiftData

enum GrowingEnvironment: String, CaseIterable, Identifiable, Hashable {
    case unspecified
    case indoor
    case outdoor
    case balcony
    case other

    var id: String { rawValue }
    var title: String {
        switch self {
        case .unspecified: "Not set"
        case .indoor: "Indoors"
        case .outdoor: "Outdoors"
        case .balcony: "Balcony"
        case .other: "Other"
        }
    }
}

enum LightCondition: String, CaseIterable, Identifiable, Hashable {
    case unspecified
    case low
    case indirect
    case direct
    case mixed

    var id: String { rawValue }
    var title: String {
        switch self {
        case .unspecified: "Not set"
        case .low: "Low light"
        case .indirect: "Bright, indirect light"
        case .direct: "Direct sunlight"
        case .mixed: "A mix of light"
        }
    }
}

@Model
final class Plant {
    var id: UUID
    var name: String
    var species: String
    var notes: String
    /// User-described growing context. Empty/default values mean the user has not supplied context.
    var growingEnvironmentRaw: String = GrowingEnvironment.unspecified.rawValue
    var lightConditionRaw: String = LightCondition.unspecified.rawValue
    @Attribute(.externalStorage) var photoData: Data?
    @Relationship(deleteRule: .cascade, inverse: \CareTask.plant) var careTasks: [CareTask]? = []
    @Relationship(deleteRule: .cascade, inverse: \CareEvent.plant) var careEvents: [CareEvent]? = []
    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.plant) var journalEntries: [JournalEntry]? = []
    var createdAt: Date

    var growingEnvironment: GrowingEnvironment {
        get { GrowingEnvironment(rawValue: growingEnvironmentRaw) ?? .unspecified }
        set { growingEnvironmentRaw = newValue.rawValue }
    }

    var lightCondition: LightCondition {
        get { LightCondition(rawValue: lightConditionRaw) ?? .unspecified }
        set { lightConditionRaw = newValue.rawValue }
    }

    init(
        id: UUID = UUID(),
        name: String,
        species: String = "",
        notes: String = "",
        growingEnvironment: GrowingEnvironment = .unspecified,
        lightCondition: LightCondition = .unspecified,
        photoData: Data? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.notes = notes
        self.growingEnvironmentRaw = growingEnvironment.rawValue
        self.lightConditionRaw = lightCondition.rawValue
        self.photoData = photoData
        self.createdAt = createdAt
    }
}
