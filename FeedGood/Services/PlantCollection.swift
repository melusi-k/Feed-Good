import Foundation

enum PlantCollectionSort: String, CaseIterable, Identifiable {
    case recentlyAdded, name
    var id: String { rawValue }
    var title: String { self == .name ? "Name" : "Recently added" }
}

/// Searches only the user's stored name/species, with deterministic ordering.
/// Fixed comparison locale avoids device-locale changes moving equal-looking names.
enum PlantCollection {
    private static let locale = Locale(identifier: "en_US_POSIX")
    private static func key(_ value: String) -> String {
        value.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: locale)
    }

    /// Active (non-archived) plants: the collection's default care surface.
    static func active(from plants: [Plant], query: String, sort: PlantCollectionSort) -> [Plant] {
        return self.plants(from: plants.filter { $0.archivedAt == nil }, query: query, sort: sort)
    }

    /// Archived plants only, for the archived collection view.
    static func archived(from plants: [Plant], query: String, sort: PlantCollectionSort) -> [Plant] {
        return self.plants(from: plants.filter { $0.archivedAt != nil }, query: query, sort: sort)
    }

    /// Tag filtering uses OR semantics (decided for #75 and documented in the
    /// implementation PR): tags are lightweight find-again labels, so selecting
    /// several shows plants carrying ANY of them. An empty selection filters
    /// nothing. Deterministic ordering is unchanged.
    static func tagged(_ plants: [Plant], selectedTagIDs: Set<UUID>) -> [Plant] {
        guard !selectedTagIDs.isEmpty else { return plants }
        return plants.filter { plant in
            (plant.tags ?? []).contains { selectedTagIDs.contains($0.id) }
        }
    }

    static func plants(from plants: [Plant], query: String, sort: PlantCollectionSort) -> [Plant] {
        let search = key(query.trimmingCharacters(in: .whitespacesAndNewlines))
        return plants.filter { search.isEmpty || key($0.name).contains(search) || key($0.species).contains(search) }.sorted {
            if sort == .recentlyAdded, $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            let left = key($0.name); let right = key($1.name)
            if left != right { return left < right }
            if $0.createdAt != $1.createdAt { return $0.createdAt > $1.createdAt }
            return $0.id.uuidString < $1.id.uuidString
        }
    }
}
