import Foundation
import OnboardingKit

/// What the launch flow decided to present.
enum LaunchFlowStep: Equatable {
    case onboarding
    case whatsNew(ReleaseNotesEntry)
    case none
}

/// Owns the launch sequence: first-run onboarding exactly once, then the
/// per-version "What's New" sheet. Onboarding state lives in OnboardingKit;
/// the What's New gate is the app's own `WhatsNewStore`.
struct AppLaunchFlow {
    let onboarding: Onboarding
    let whatsNewStore: WhatsNewStore

    /// What to present at launch. Onboarding always wins; the What's New check
    /// only runs once onboarding is complete.
    func step() -> LaunchFlowStep {
        if onboarding.shouldBePresented {
            return .onboarding
        }
        if let entry = whatsNewStore.entryToPresent() {
            return .whatsNew(entry)
        }
        return .none
    }

    /// Call after the onboarding flow closes by any path (Skip included), so
    /// it never appears again.
    func completeOnboarding() {
        onboarding.presentationCount = max(1, onboarding.presentationCount)
    }

    /// The What's New entry to show once onboarding is done, if any.
    func whatsNewEntry() -> ReleaseNotesEntry? {
        whatsNewStore.entryToPresent()
    }

    func markWhatsNewSeen() {
        whatsNewStore.markCurrentVersionSeen()
    }

    /// Builds the launch flow, honoring UI-test launch arguments:
    /// - `FEEDGOOD_UI_TESTING`: onboarding is treated as completed so existing
    ///   journeys are unaffected, unless `FEEDGOOD_ONBOARDING_RESET` is also
    ///   passed to force the flow.
    /// - `FEEDGOOD_ONBOARDING_RESET`: clears onboarding state so the flow
    ///   appears.
    /// - `FEEDGOOD_WHATS_NEW_LAST_SEEN <identity>` / `FEEDGOOD_WHATS_NEW_FRESH_INSTALL`:
    ///   the What's New seams from `WhatsNewStore`.
    static func makeDefault(defaults: UserDefaults = .standard) -> AppLaunchFlow {
        let arguments = ProcessInfo.processInfo.arguments
        let onboarding = Onboarding(id: "feedGood.onboarding.v1", store: defaults)
        if arguments.contains("FEEDGOOD_ONBOARDING_RESET") {
            onboarding.reset()
        } else if arguments.contains("FEEDGOOD_UI_TESTING") {
            onboarding.presentationCount = max(1, onboarding.presentationCount)
        }

        let whatsNewStore: WhatsNewStore
        if let index = arguments.firstIndex(of: "FEEDGOOD_WHATS_NEW_LAST_SEEN"), index + 1 < arguments.count {
            whatsNewStore = WhatsNewStore(defaults: defaults, lastSeen: arguments[index + 1])
        } else if arguments.contains("FEEDGOOD_WHATS_NEW_FRESH_INSTALL") {
            whatsNewStore = WhatsNewStore(defaults: defaults, lastSeen: nil)
        } else {
            whatsNewStore = WhatsNewStore(defaults: defaults)
        }
        return AppLaunchFlow(onboarding: onboarding, whatsNewStore: whatsNewStore)
    }
}
