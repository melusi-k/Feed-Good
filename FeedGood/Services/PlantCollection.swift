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
