import XCTest
@testable import FeedGood

final class AppearanceTests: XCTestCase {
    func testAppearanceOffersSystemLightAndDark() {
        XCTAssertEqual(FeedGoodAppearance.allCases, [.system, .light, .dark])
    }

    func testSystemAppearanceDoesNotOverrideDeviceSetting() {
        XCTAssertNil(FeedGoodAppearance.system.preferredColorScheme)
    }

    func testLightAndDarkAppearanceAreExplicit() {
        XCTAssertEqual(FeedGoodAppearance.light.preferredColorScheme, .light)
        XCTAssertEqual(FeedGoodAppearance.dark.preferredColorScheme, .dark)
    }

    func testUnknownStoredAppearanceFallsBackToSystem() {
        let storedValue = "sepia"
        let appearance = FeedGoodAppearance(rawValue: storedValue) ?? .system
        XCTAssertEqual(appearance, .system)
    }
}
