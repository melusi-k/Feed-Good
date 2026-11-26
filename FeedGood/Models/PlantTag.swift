import Foundation
import SwiftData

/// An optional, user-authored label for grouping plants (issue #75).
/// Tags are never inferred from photos, location or notes, are not lifecycle
/// states, and deleting a tag never deletes a plant or any of its records.
@Model
final class PlantTag {
    var id: UUID = UUID()
    /// Display name as first written, trimmed of surrounding whitespace.
    var name: String = ""
    /// Uniqueness key: whitespace-trimmed, whitespace-collapsed, case- and
    /// diacritic-folded in a fixed POSIX locale, matching collection search.
    var normalizedName: String = ""
    @Relationship(inverse: \Plant.tags) var plants: [Plant]? = []

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = PlantTag.trimmed(name)
        self.normalizedName = PlantTag.normalized(name)
    }

    static func trimmed(_ name: String) -> String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
            .components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    static func normalized(_ name: String) -> String {
        trimmed(name).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
    }
}

@MainActor
enum PlantTagStore {
    static func trimmed(_ name: String) -> String { PlantTag.trimmed(name) }
    static func normalized(_ name: String) -> String { PlantTag.normalized(name) }

    /// Creates a tag, or returns the existing one whose normalized name matches.
    /// "Fern", " fern  " and "FERN" are one tag; the first spelling wins display.
    static func tag(named name: String, context: ModelContext) throws -> PlantTag? {
        let key = normalized(name)
        guard !key.isEmpty else { return nil }
        if let existing = try context.fetch(FetchDescriptor<PlantTag>()).first(where: { $0.normalizedName == key }) {
            return existing
        }
        let tag = PlantTag(name: name)
        context.insert(tag)
        return tag
    }

    /// Renames a tag. If another tag already owns the normalized target name,
    /// the two merge: plants move to the surviving tag and the renamed one is removed.
    static func rename(_ tag: PlantTag, to name: String, context: ModelContext) throws {
        let key = normalized(name)
        guard !key.isEmpty else { throw JournalArchiveError.invalidRecord }
        if let other = try context.fetch(FetchDescriptor<PlantTag>()).first(where: { $0.normalizedName == key && $0.id != tag.id }) {
            for plant in tag.plants ?? [] where !(other.plants ?? []).contains(where: { $0.id == plant.id }) {
                other.plants?.append(plant)
            }
            context.delete(tag)
        } else {
            tag.name = trimmed(name)
            tag.normalizedName = key
        }
        do { try context.save() }
        catch { context.rollback(); throw error }
    }

    /// Deletes only the tag. Plants and all their records stay.
    static func delete(_ tag: PlantTag, context: ModelContext) throws {
        context.delete(tag)
        do { try context.save() }
        catch { context.rollback(); throw error }
    }
}
