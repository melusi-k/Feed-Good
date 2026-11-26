import Foundation

enum LaunchFlowStep: Equatable {
    case onboarding
    case whatsNew(ReleaseNotesEntry)
    case none
}

/// Coordinates presentation order while keeping onboarding and release-note
/// acknowledgement in their independent persisted keys.
struct AppLaunchFlow {
    let stateStore: AppLaunchStateStore
    let shortVersion: String
    let versionIdentity: String

    func step() -> LaunchFlowStep {
        if stateStore.shouldPresentOnboarding {
            return .onboarding
        }
        return whatsNewEntry().map(LaunchFlowStep.whatsNew) ?? .none
    }

    func completeOnboarding() {
        stateStore.completeOnboarding()
    }

    func whatsNewEntry() -> ReleaseNotesEntry? {
        let entry = ReleaseNotes.entry(forVersion: shortVersion)
        guard stateStore.shouldPresentWhatsNew(
            versionIdentity: versionIdentity,
            hasReleaseNotes: entry != nil
        ) else {
            return nil
        }
        return entry
    }

    func markWhatsNewSeen() {
        stateStore.markWhatsNewSeen(versionIdentity: versionIdentity)
    }
}
