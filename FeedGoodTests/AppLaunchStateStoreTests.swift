import Foundation
import Testing
@testable import FeedGood

struct AppLaunchStateStoreTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "AppLaunchStateStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        #expect(defaults != nil)
        return defaults ?? .standard
    }

    @Test func freshInstallStartsWithOnboardingPendingAndSuppressesWhatsNew() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: false)

        store.bootstrap(versionIdentity: "0.1.0 (1)")

        #expect(store.shouldPresentOnboarding)
        #expect(store.shouldPresentWhatsNew(versionIdentity: "0.1.0 (1)", hasReleaseNotes: true) == false)
        #expect(defaults.string(forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey) == "0.1.0 (1)")
    }

    @Test func existingInstallWithoutNewOnboardingKeyDoesNotSeeOnboarding() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)

        store.bootstrap(versionIdentity: "0.1.46 (46)")

        #expect(store.shouldPresentOnboarding == false)
        #expect(defaults.bool(forKey: AppLaunchStateStore.onboardingCompletedKey))
    }

    @Test func interruptedFreshInstallKeepsOnboardingPendingAfterStoreAppears() {
        let defaults = makeDefaults()
        let firstLaunch = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: false)
        firstLaunch.bootstrap(versionIdentity: "0.1.0 (1)")
        #expect(firstLaunch.shouldPresentOnboarding)

        // The SwiftData store now exists on the next launch, but the persisted
        // incomplete state takes precedence over the existing-store signal.
        let relaunch = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        relaunch.bootstrap(versionIdentity: "0.1.0 (1)")
        #expect(relaunch.shouldPresentOnboarding)
    }

    @Test func deliberateCompletionPersistsAcrossLaunches() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: false)
        store.bootstrap(versionIdentity: "0.1.0 (1)")
        store.completeOnboarding()

        let relaunch = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        relaunch.bootstrap(versionIdentity: "0.1.0 (1)")
        #expect(relaunch.shouldPresentOnboarding == false)
    }

    @Test func existingInstallUpgradeWithNotesIsEligibleAndAcknowledgementIsOnceOnly() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        store.bootstrap(versionIdentity: "0.1.46 (46)")

        #expect(store.shouldPresentWhatsNew(versionIdentity: "0.1.46 (46)", hasReleaseNotes: true))
        store.markWhatsNewSeen(versionIdentity: "0.1.46 (46)")
        #expect(store.shouldPresentWhatsNew(versionIdentity: "0.1.46 (46)", hasReleaseNotes: true) == false)
    }

    @Test func missingReleaseNotesDoNotAcknowledgeAnUpgrade() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        store.bootstrap(versionIdentity: "9.9.9 (99)")

        #expect(store.shouldPresentWhatsNew(versionIdentity: "9.9.9 (99)", hasReleaseNotes: false) == false)
        #expect(defaults.string(forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey) == nil)
        #expect(store.shouldPresentWhatsNew(versionIdentity: "9.9.10 (100)", hasReleaseNotes: true))
    }

    @Test func onboardingAndWhatsNewAcknowledgementsRemainIndependent() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: false)
        store.bootstrap(versionIdentity: "0.1.0 (1)")
        store.completeOnboarding()

        #expect(store.shouldPresentOnboarding == false)
        #expect(store.shouldPresentWhatsNew(versionIdentity: "0.1.1 (2)", hasReleaseNotes: true) == true)
    }
}
