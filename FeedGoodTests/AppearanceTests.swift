import Testing
@testable import FeedGood

struct AppearanceTests {
    @Test func appearanceOffersSystemLightAndDark() {
        #expect(FeedGoodAppearance.allCases == [.system, .light, .dark])
    }

    @Test func systemAppearanceDoesNotOverrideDeviceSetting() {
        #expect(FeedGoodAppearance.system.preferredColorScheme == nil)
    }

    @Test func lightAndDarkAppearanceAreExplicit() {
        #expect(FeedGoodAppearance.light.preferredColorScheme == .light)
        #expect(FeedGoodAppearance.dark.preferredColorScheme == .dark)
    }

    @Test func unknownStoredAppearanceFallsBackToSystem() {
        let storedValue = "sepia"
        let appearance = FeedGoodAppearance(rawValue: storedValue) ?? .system
        #expect(appearance == .system)
    }
}
