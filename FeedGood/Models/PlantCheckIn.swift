import Foundation
import SwiftData

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

    /// Stages all observations for permanent plant deletion. The caller saves
    /// these deletions together with the plant and its other owned records.
    static func deleteAll(for plantID: UUID, in context: ModelContext) throws {
        let records = try context.fetch(FetchDescriptor<PlantCheckIn>())
        for record in records where record.plantID == plantID {
            context.delete(record)
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
