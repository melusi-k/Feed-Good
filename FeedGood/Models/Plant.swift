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
    var growingEnvironmentRaw: String = "unspecified"
    var lightConditionRaw: String = "unspecified"
    @Attribute(.externalStorage) var photoData: Data?
    @Relationship(deleteRule: .cascade, inverse: \CareTask.plant) var careTasks: [CareTask]? = []
    @Relationship(deleteRule: .cascade, inverse: \CareEvent.plant) var careEvents: [CareEvent]? = []
    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.plant) var journalEntries: [JournalEntry]? = []
    /// Optional user-authored tags (#75). No cascade: deleting a plant removes its
    /// assignments but never the shared tags; deleting a tag never deletes a plant.
    @Relationship var tags: [PlantTag]? = []
    /// Quiet Period history is owned by the plant and removed on hard deletion.
    @Relationship(deleteRule: .cascade, inverse: \QuietPeriod.plant) var quietPeriods: [QuietPeriod]? = []
    var createdAt: Date
    /// Reversible archive marker. Nil means active. Archiving never deletes the plant or any related record.
    var archivedAt: Date?

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
        createdAt: Date = .now,
        archivedAt: Date? = nil
    ) {
        self.id = id
        self.name = name
        self.species = species
        self.notes = notes
        self.growingEnvironmentRaw = growingEnvironment.rawValue
        self.lightConditionRaw = lightCondition.rawValue
        self.photoData = photoData
        self.createdAt = createdAt
        self.archivedAt = archivedAt
    }
}


enum PlantCheckInSign: String, CaseIterable, Identifiable, Codable {
    case yellowing
    case wilting
    case spots
    case visiblePests
    case slowGrowth
    case notSure

    var id: String { rawValue }

    var title: String {
        switch self {
        case .yellowing: "Yellowing"
        case .wilting: "Wilting"
        case .spots: "Spots or marks"
        case .visiblePests: "Visible pests"
        case .slowGrowth: "Slow growth"
        case .notSure: "I'm not sure"
        }
    }
}

struct PlantCheckInDraft {
    var observedAt: Date = .now
    var signs: [PlantCheckInSign] = []
    var note: String = ""
    var photoData: Data?

    var isValid: Bool {
        guard !signs.isEmpty,
              Set(signs).count == signs.count else { return false }
        return !signs.contains(.notSure) || signs.count == 1
    }
}

enum PlantCheckInStoreError: LocalizedError, Equatable {
    case invalidRecord
    case plantNotFound
    case archivedPlant

    var errorDescription: String? {
        switch self {
        case .invalidRecord:
            "Choose one or more observations. “I'm not sure” must be selected on its own."
        case .plantNotFound:
            "This plant no longer exists. The check-in wasn't saved."
        case .archivedPlant:
            "New check-ins can't be added to an archived plant."
        }
    }
}

/// A private, local observation. It is deliberately not linked to care completion
/// or to the JournalEntry model; plant ownership is a stable UUID foreign key.
@Model
final class PlantCheckIn {
    var id: UUID
    var plantID: UUID
    var observedAt: Date
    var signRawValues: [String]
    var note: String
    @Attribute(.externalStorage) var photoData: Data?

    var signs: [PlantCheckInSign] {
        signRawValues.compactMap(PlantCheckInSign.init(rawValue:))
    }

    init(
        id: UUID = UUID(),
        plantID: UUID,
        observedAt: Date = .now,
        signRawValues: [String],
        note: String = "",
        photoData: Data? = nil
    ) {
        self.id = id
        self.plantID = plantID
        self.observedAt = observedAt
        self.signRawValues = signRawValues
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.photoData = photoData
    }
}

@MainActor
enum PlantCheckInStore {
    static func save(
        _ draft: PlantCheckInDraft,
        for plant: Plant,
        editing checkIn: PlantCheckIn? = nil,
        in context: ModelContext
    ) throws {
        guard draft.isValid else { throw PlantCheckInStoreError.invalidRecord }
        let storedPlants = try context.fetch(FetchDescriptor<Plant>())
        guard let storedPlant = storedPlants.first(where: { $0.id == plant.id }) else {
            throw PlantCheckInStoreError.plantNotFound
        }
        if checkIn == nil, storedPlant.archivedAt != nil {
            throw PlantCheckInStoreError.archivedPlant
        }
        if let checkIn, checkIn.plantID != storedPlant.id {
            throw PlantCheckInStoreError.invalidRecord
        }

        let record = checkIn ?? PlantCheckIn(plantID: storedPlant.id, signRawValues: [])
        if checkIn == nil { context.insert(record) }
        record.observedAt = draft.observedAt
        record.signRawValues = draft.signs.map { $0.rawValue }.sorted()
        record.note = draft.note.trimmingCharacters(in: .whitespacesAndNewlines)
        record.photoData = draft.photoData

        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }

    static func delete(_ checkIn: PlantCheckIn, in context: ModelContext) throws {
        context.delete(checkIn)
        do {
            try context.save()
        } catch {
            context.rollback()
            throw error
        }
    }
}
