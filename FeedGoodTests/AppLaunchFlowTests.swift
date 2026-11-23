import Foundation
import Testing
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
        hasExistingStore: Bool,
        shortVersion: String = "0.1.0",
        buildNumber: String = "1"
    ) -> AppLaunchFlow {
        let versionIdentity = "\(shortVersion) (\(buildNumber))"
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: hasExistingStore)
        store.bootstrap(versionIdentity: versionIdentity)
        return AppLaunchFlow(stateStore: store, shortVersion: shortVersion, versionIdentity: versionIdentity)
    }

    @Test func freshInstallPresentsOnboardingAndThenEntersAppWithoutWhatsNew() {
        let defaults = makeDefaults()
        let flow = makeFlow(defaults: defaults, hasExistingStore: false)

        #expect(flow.step() == .onboarding)
        flow.completeOnboarding()
        #expect(flow.step() == .none)
    }

    @Test func existingInstallUpgradePresentsWhatsNewWithoutOnboarding() throws {
        let defaults = makeDefaults()
        let flow = makeFlow(defaults: defaults, hasExistingStore: true)
        let step = flow.step()
        let entry = try #require(ReleaseNotes.entry(forVersion: "0.1.0"))

        #expect(step == .whatsNew(entry))
    }

    @Test func onboardingTakesPriorityWhenBothExperiencesArePending() throws {
        let defaults = makeDefaults()
        defaults.set(false, forKey: AppLaunchStateStore.onboardingCompletedKey)
        defaults.set("0.0.9 (9)", forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey)
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        store.bootstrap(versionIdentity: "0.1.0 (1)")
        let flow = AppLaunchFlow(stateStore: store, shortVersion: "0.1.0", versionIdentity: "0.1.0 (1)")

        #expect(flow.step() == .onboarding)
        flow.completeOnboarding()
        let entry = try #require(ReleaseNotes.entry(forVersion: "0.1.0"))
        #expect(flow.step() == .whatsNew(entry))
    }

    @Test func releaseWithoutNotesDoesNotShowAnEmptySheetOrAcknowledgeVersion() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        store.bootstrap(versionIdentity: "9.9.9 (99)")
        let flow = AppLaunchFlow(stateStore: store, shortVersion: "9.9.9", versionIdentity: "9.9.9 (99)")

        #expect(flow.step() == .none)
        #expect(defaults.string(forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey) == nil)
    }

    @Test func dismissingWhatsNewAcknowledgesOnlyTheReleaseNotesState() {
        let defaults = makeDefaults()
        let store = AppLaunchStateStore(defaults: defaults, hasExistingPersistentStore: true)
        store.bootstrap(versionIdentity: "0.1.0 (1)")
        let flow = AppLaunchFlow(stateStore: store, shortVersion: "0.1.0", versionIdentity: "0.1.0 (1)")

        flow.markWhatsNewSeen()

        #expect(store.shouldPresentOnboarding == false)
        #expect(flow.step() == .none)
        #expect(defaults.string(forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey) == "0.1.0 (1)")
    }
}
