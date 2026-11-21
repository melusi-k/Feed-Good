import Foundation

enum CareGuideReviewStatus: String, Codable, Hashable {
    case draft
    case approved
    case retired
}

struct CareGuideSource: Identifiable, Hashable {
    let title: String
    let publisher: String
    let url: String

    var id: String { url }
}

struct CareGuideSection: Identifiable, Hashable {
    let title: String
    let body: String
    var id: String { title }
}

/// Bundled editorial content. An entry is not visible in the app until a
/// named reviewer approves it and records a review date.
struct CareGuideArticle: Identifiable, Hashable {
    let id: String
    let title: String
    let summary: String
    let sections: [CareGuideSection]
    let tags: [String]
    let sources: [CareGuideSource]
    let reviewStatus: CareGuideReviewStatus
    let reviewedBy: String?
    let reviewedAt: Date?

    var isApprovedForPublication: Bool {
        reviewStatus == .approved &&
        !(reviewedBy?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true) &&
        reviewedAt != nil
    }

    var searchableText: String {
        ([title, summary] + tags + sections.flatMap { [$0.title, $0.body] })
            .joined(separator: " ")
    }
}

enum CareGuideCatalog {
    /// Draft entries are bundled with the app, but remain hidden until a
    /// horticultural/editorial reviewer approves them.
    static let articles: [CareGuideArticle] = [
        CareGuideArticle(
            id: "light-and-placement",
            title: "Finding the right light",
            summary: "Learn to observe the light in a space before choosing where a plant belongs.",
            sections: [
                CareGuideSection(title: "Start with the plant", body: "Different plants need different amounts of light. Check the needs of the plant you have rather than assuming one position suits every plant."),
                CareGuideSection(title: "Notice what happens", body: "Watch how direct sun moves across the space during the day and across the seasons. Too little light can lead to stretched or pale growth; too much intense light can scorch leaves on sensitive plants."),
                CareGuideSection(title: "Make changes gradually", body: "If you move a plant to a brighter position or outdoors, make the change gradually and watch how it responds. Your notes about the space are observations, not light measurements.")
            ],
            tags: ["light", "sun", "shade", "indoor", "placement", "leaves"],
            sources: [
                CareGuideSource(title: "Lighting for indoor plants", publisher: "University of Minnesota Extension", url: "https://extension.umn.edu/garden-and-home/yard-and-garden/gardening-in-minnesota/lighting-for-indoor-plants"),
                CareGuideSource(title: "How to grow houseplants", publisher: "Royal Horticultural Society", url: "https://www.rhs.org.uk/plants/types/houseplants/growing-guide")
            ],
            reviewStatus: .draft,
            reviewedBy: nil,
            reviewedAt: nil
        ),
        CareGuideArticle(
            id: "watering-with-observation",
            title: "Water with observation, not a calendar",
            summary: "A routine can remind you to check, but the plant and its growing conditions should guide the decision.",
            sections: [
                CareGuideSection(title: "Check before watering", body: "Check the potting mix and the plant's own requirements before watering. A fixed interval cannot account for every species, pot, room, season or growing position."),
                CareGuideSection(title: "Notice what changes drying time", body: "Light, temperature, pot material, plant size and season can all affect how quickly a container dries. Plants in cooler or lower-light conditions may use water more slowly."),
                CareGuideSection(title: "Let excess water escape", body: "When watering is appropriate for the plant, allow excess water to drain away. Avoid leaving a pot standing in collected water.")
            ],
            tags: ["water", "watering", "soil", "moisture", "routine", "overwatering"],
            sources: [
                CareGuideSource(title: "How to grow houseplants", publisher: "Royal Horticultural Society", url: "https://www.rhs.org.uk/plants/types/houseplants/growing-guide"),
                CareGuideSource(title: "Spring houseplant care", publisher: "University of Minnesota Extension", url: "https://extension.umn.edu/houseplants/spring-houseplant-care")
            ],
            reviewStatus: .draft,
            reviewedBy: nil,
            reviewedAt: nil
        ),
        CareGuideArticle(
            id: "pots-and-drainage",
            title: "Why drainage matters",
            summary: "Healthy roots need more than water: the growing medium also needs air.",
            sections: [
                CareGuideSection(title: "Look at the container", body: "For most potted plants, use a container with drainage so excess water can leave the pot. Check that drainage holes are not blocked."),
                CareGuideSection(title: "Avoid standing water", body: "When the growing medium stays waterlogged, air spaces around roots can fill with water. This can contribute to root stress and root rot."),
                CareGuideSection(title: "Check the saucer", body: "After watering, let the pot drain and empty collected water from its saucer or outer cover when appropriate for the plant.")
            ],
            tags: ["drainage", "pots", "containers", "roots", "soil", "waterlogging"],
            sources: [
                CareGuideSource(title: "How to grow houseplants", publisher: "Royal Horticultural Society", url: "https://www.rhs.org.uk/plants/types/houseplants/growing-guide"),
                CareGuideSource(title: "Houseplant care", publisher: "Smithsonian Gardens", url: "https://gardens.si.edu/learn/educational-resources/plant-care-sheets/houseplant-care/")
            ],
            reviewStatus: .draft,
            reviewedBy: nil,
            reviewedAt: nil
        ),
        CareGuideArticle(
            id: "seasonal-adjustments",
            title: "Let the seasons change the routine",
            summary: "Light, temperature and growth shift through the year, so care routines may need to change too.",
            sections: [
                CareGuideSection(title: "Observe seasonal changes", body: "Day length, sun angle and temperature affect growing conditions. A plant may use water more slowly during cooler or lower-light periods and more quickly in warmer, brighter conditions."),
                CareGuideSection(title: "Use your local seasons", body: "Seasonal advice written for another hemisphere or climate may not match your garden. Consider your local rainfall pattern, temperature and the needs of the individual plant."),
                CareGuideSection(title: "Review rather than reset", body: "Use your care routine as a prompt to observe. Adjust it when your notes and the plant's condition suggest that the old pattern no longer fits.")
            ],
            tags: ["seasons", "winter", "summer", "climate", "routine", "growth"],
            sources: [
                CareGuideSource(title: "Spring houseplant care", publisher: "University of Minnesota Extension", url: "https://extension.umn.edu/houseplants/spring-houseplant-care"),
                CareGuideSource(title: "How to grow houseplants", publisher: "Royal Horticultural Society", url: "https://www.rhs.org.uk/plants/types/houseplants/growing-guide")
            ],
            reviewStatus: .draft,
            reviewedBy: nil,
            reviewedAt: nil
        ),
        CareGuideArticle(
            id: "water-wise-western-cape",
            title: "Water-wise gardening in the Western Cape",
            summary: "A regional introduction to matching plants and planting times to local rainfall patterns.",
            sections: [
                CareGuideSection(title: "Work with the rainfall pattern", body: "South Africa has different rainfall regions. In the Western Cape's winter-rainfall region, autumn planting can make use of the rainy season while plants establish before the drier period."),
                CareGuideSection(title: "Group plants thoughtfully", body: "Grouping plants with similar water needs can make garden watering more efficient. Choose plants suited to your region and growing conditions."),
                CareGuideSection(title: "Keep advice regional", body: "This guidance is specific to the Western Cape winter-rainfall context. Do not apply it unchanged to summer-rainfall regions or to indoor plants.")
            ],
            tags: ["South Africa", "Western Cape", "water-wise", "rainfall", "outdoor", "regional"],
            sources: [
                CareGuideSource(title: "Water-wise Gardening", publisher: "South African National Biodiversity Institute — Kirstenbosch", url: "https://pza.sanbi.org/sites/default/files/info_library/water%20wise%20gardening%20poster%20white%20A3%20web.pdf")
            ],
            reviewStatus: .draft,
            reviewedBy: nil,
            reviewedAt: nil
        )
    ]

    static func publishedArticles() -> [CareGuideArticle] {
        publishedArticles(in: articles)
    }

    static func publishedArticles(in articles: [CareGuideArticle]) -> [CareGuideArticle] {
        articles.filter(\.isApprovedForPublication).sorted {
            $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }
    }

    static func search(_ query: String) -> [CareGuideArticle] {
        search(query, in: articles)
    }

    static func search(_ query: String, in articles: [CareGuideArticle]) -> [CareGuideArticle] {
        let published = publishedArticles(in: articles)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return published }
        return published.filter {
            $0.searchableText.range(of: trimmed, options: [.caseInsensitive, .diacriticInsensitive]) != nil
        }
    }
}
