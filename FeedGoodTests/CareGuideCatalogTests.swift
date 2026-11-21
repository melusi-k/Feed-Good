import XCTest
@testable import FeedGood

final class CareGuideCatalogTests: XCTestCase {
    private func article(
        id: String,
        title: String,
        summary: String = "",
        body: String = "",
        tags: [String] = [],
        status: CareGuideReviewStatus = .approved,
        reviewer: String? = "Horticultural reviewer",
        reviewedAt: Date? = Date(timeIntervalSince1970: 1_800_000_000)
    ) -> CareGuideArticle {
        CareGuideArticle(
            id: id,
            title: title,
            summary: summary,
            sections: [CareGuideSection(title: "Details", body: body)],
            tags: tags,
            sources: [CareGuideSource(title: "Source", publisher: "Publisher", url: "https://example.org/guide")],
            reviewStatus: status,
            reviewedBy: reviewer,
            reviewedAt: reviewedAt
        )
    }

    func testDraftCatalogIsOfflineAndHiddenUntilEditorialApproval() {
        XCTAssertFalse(CareGuideCatalog.articles.isEmpty)
        XCTAssertTrue(CareGuideCatalog.articles.allSatisfy { $0.reviewStatus == .draft })
        XCTAssertTrue(CareGuideCatalog.publishedArticles().isEmpty)
        XCTAssertTrue(CareGuideCatalog.search("watering").isEmpty)
        XCTAssertTrue(CareGuideCatalog.articles.flatMap(\.sources).allSatisfy { $0.url.hasPrefix("https://") })
    }

    func testApprovalRequiresNamedReviewerAndReviewDate() {
        let approved = article(id: "approved", title: "Watering")
        let noReviewer = article(id: "no-reviewer", title: "Light", reviewer: nil)
        let blankReviewer = article(id: "blank-reviewer", title: "Soil", reviewer: "  ")
        let noDate = article(id: "no-date", title: "Drainage", reviewedAt: nil)
        let draft = article(id: "draft", title: "Pruning", status: .draft)

        let published = CareGuideCatalog.publishedArticles(in: [approved, noReviewer, blankReviewer, noDate, draft])
        XCTAssertEqual(published.map(\.id), ["approved"])
    }

    func testSearchMatchesTitleSummaryBodyAndTagsButOnlyPublishedContent() {
        let watering = article(
            id: "watering",
            title: "Water with care",
            summary: "Check soil moisture",
            body: "Observe the potting mix before watering.",
            tags: ["drainage"]
        )
        let light = article(id: "light", title: "Finding light", body: "Watch for stretched growth.")
        let draft = article(id: "draft", title: "Watering draft", status: .draft)

        XCTAssertEqual(CareGuideCatalog.search("moisture", in: [watering, light, draft]).map(\.id), ["watering"])
        XCTAssertEqual(CareGuideCatalog.search("stretched", in: [watering, light, draft]).map(\.id), ["light"])
        XCTAssertEqual(CareGuideCatalog.search("DRAINAGE", in: [watering, light, draft]).map(\.id), ["watering"])
        XCTAssertEqual(CareGuideCatalog.search("   ", in: [light, watering]).map(\.id), ["light", "watering"])
        XCTAssertTrue(CareGuideCatalog.search("Watering draft", in: [draft]).isEmpty)
    }
}
