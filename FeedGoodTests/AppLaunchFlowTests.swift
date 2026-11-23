import Foundation
import Testing
import OnboardingKit
@testable import FeedGood

struct AppLaunchFlowTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppLaunchFlowTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        #expect(defaults != nil)
        return defaults ?? .standard
    }

    private func makeFlow(
        defaults: UserDefaults,
        onboardingID: String = "test.onboarding.\(UUID().uuidString)",
        shortVersion: String = "0.1.46",
        buildNumber: String = "46",
        lastSeen: String?? = .none
    ) -> AppLaunchFlow {
        let onboarding = Onboarding(id: onboardingID, store: defaults)
        let store: WhatsNewStore
        if let seeded = lastSeen {
            store = WhatsNewStore(defaults: defaults, shortVersion: shortVersion, buildNumber: buildNumber, lastSeen: seeded)
        } else {
            store = WhatsNewStore(defaults: defaults, shortVersion: shortVersion, buildNumber: buildNumber)
        }
        return AppLaunchFlow(onboarding: onboarding, whatsNewStore: store)
    }

    @Test func firstLaunchShowsOnboarding() {
        let flow = makeFlow(defaults: makeDefaults())
        #expect(flow.step() == .onboarding)
    }

    @Test func completedOnboardingOnAFreshInstallShowsNothing() {
        let defaults = makeDefaults()
        let flow = makeFlow(defaults: defaults)
        flow.completeOnboarding()
        // Fresh install: the What's New gate records the version and stays quiet.
        #expect(flow.step() == .none)
        #expect(flow.step() == .none)
    }

    @Test func completedOnboardingAfterAnUpdateShowsWhatsNewOnce() {
        let defaults = makeDefaults()
        let onboardingID = "test.onboarding.\(UUID().uuidString)"
        let flow = makeFlow(defaults: defaults, onboardingID: onboardingID, lastSeen: .some("0.1.0 (1)"))
        flow.completeOnboarding()
        let expected = ReleaseNotes.entry(forVersion: "0.1.46")
        #expect(flow.step() == .whatsNew(expected))
        flow.markWhatsNewSeen()
        // Seen is persisted in the real store: a fresh flow over the same
        // defaults with no seed stays quiet.
        let reloaded = makeFlow(defaults: defaults, onboardingID: onboardingID)
        #expect(reloaded.step() == .none)
    }

    @Test func onboardingIsNeverShownTwice() {
        let defaults = makeDefaults()
        let flow = makeFlow(defaults: defaults)
        #expect(flow.step() == .onboarding)
        flow.completeOnboarding()
        let reloaded = makeFlow(defaults: defaults)
        #expect(reloaded.step() != .onboarding)
    }
}
