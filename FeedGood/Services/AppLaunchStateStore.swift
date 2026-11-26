import Foundation

/// Establishes first-run eligibility before SwiftData creates its persistent
/// store. The store's existence is the migration signal for installations that
/// predate onboarding: absence of a new onboarding preference must never make
/// an existing installation look like a fresh install.
struct AppLaunchStateStore {
    static let onboardingCompletedKey = "feedGood.onboarding.completed"
    static let whatsNewLastSeenVersionKey = "feedGood.whatsNew.lastSeenVersion"

    private let defaults: UserDefaults
    private let hasExistingPersistentStore: Bool

    init(
        defaults: UserDefaults = .standard,
        hasExistingPersistentStore: Bool
    ) {
        self.defaults = defaults
        self.hasExistingPersistentStore = hasExistingPersistentStore
    }

    /// Run before constructing the app's ModelContainer. A fresh install is
    /// marked onboarding-pending and its installing release is acknowledged so
    /// it does not receive a What's New sheet after onboarding. An existing
    /// installation with no onboarding key is treated as already onboarded.
    func bootstrap(versionIdentity: String) {
        if defaults.object(forKey: Self.onboardingCompletedKey) == nil {
            defaults.set(hasExistingPersistentStore, forKey: Self.onboardingCompletedKey)
        }

        if hasExistingPersistentStore == false,
           defaults.string(forKey: Self.whatsNewLastSeenVersionKey) == nil {
            defaults.set(versionIdentity, forKey: Self.whatsNewLastSeenVersionKey)
        }
    }

    var shouldPresentOnboarding: Bool {
        defaults.bool(forKey: Self.onboardingCompletedKey) == false
    }

    /// Call only after a deliberate Skip or final onboarding choice. Merely
    /// opening the app or interrupting onboarding must not complete it.
    func completeOnboarding() {
        defaults.set(true, forKey: Self.onboardingCompletedKey)
    }

    /// Returns true only when this installation is eligible and bundled notes
    /// exist. An existing installation upgrading from a build that predates
    /// this feature has no last-seen value, so its first notes-bearing update
    /// is eligible. A fresh install records its installing version in bootstrap.
    func shouldPresentWhatsNew(
        versionIdentity: String,
        hasReleaseNotes: Bool
    ) -> Bool {
        guard hasReleaseNotes else { return false }
        guard let lastSeen = defaults.string(forKey: Self.whatsNewLastSeenVersionKey) else {
            return hasExistingPersistentStore
        }
        return lastSeen != versionIdentity
    }

    /// Call only when the user deliberately dismisses the release notes.
    func markWhatsNewSeen(versionIdentity: String) {
        defaults.set(versionIdentity, forKey: Self.whatsNewLastSeenVersionKey)
    }
}
