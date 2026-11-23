import Foundation

/// One release's "What's New" content. Data-only: shipping notes for a new
/// version means adding one entry here, with no view changes.
struct ReleaseNotesEntry: Equatable, Identifiable {
    let version: String
    let title: String
    let highlights: [String]

    var id: String { version }
}

enum ReleaseNotes {
    static let entries: [ReleaseNotesEntry] = [
        ReleaseNotesEntry(
            version: "0.1.46",
            title: "Care, reviewed",
            highlights: [
                "Review and confirm your care routine before it is saved",
                "Compare two journal photos per plant in Growth Review",
                "Clearer VoiceOver feedback in Growth Review"
            ]
        ),
        ReleaseNotesEntry(
            version: "0.1.0",
            title: "Welcome to Feed Good",
            highlights: [
                "Track every plant in your garden",
                "Gentle care reminders on your schedule",
                "A journal for each plant's story"
            ]
        )
    ]

    static func entry(forVersion version: String) -> ReleaseNotesEntry? {
        entries.first { $0.version == version }
    }
}

/// Decides whether the "What's New" sheet appears on this launch and records
/// the versions it has already been shown for.
///
/// Gating rules:
/// - First launch ever (nothing recorded): the current version is recorded and
///   nothing is shown. A fresh install is covered by onboarding, and users
///   updating from a build that predates this feature are not greeted with
///   notes for a version they already experienced.
/// - Same version as last seen: nothing.
/// - New version with a matching release-notes entry: the sheet appears once,
///   and dismissing it records the version.
/// - New version without an entry: nothing, and the version is not recorded,
///   so the next version that ships notes still appears.
struct WhatsNewStore {
    static let lastSeenVersionKey = "feedGood.whatsNew.lastSeenVersion"

    private let defaults: UserDefaults
    private let shortVersion: String
    private let buildNumber: String
    private let seededLastSeen: String??

    var versionIdentity: String { "\(shortVersion) (\(buildNumber))" }

    init(
        defaults: UserDefaults = .standard,
        shortVersion: String = WhatsNewStore.currentShortVersion,
        buildNumber: String = WhatsNewStore.currentBuildNumber
    ) {
        self.defaults = defaults
        self.shortVersion = shortVersion
        self.buildNumber = buildNumber
        self.seededLastSeen = nil
    }

    /// Testing seam: `lastSeen` replaces the persisted value (`nil` simulates a
    /// fresh install). Used by UI tests via launch arguments.
    init(
        defaults: UserDefaults = .standard,
        shortVersion: String = WhatsNewStore.currentShortVersion,
        buildNumber: String = WhatsNewStore.currentBuildNumber,
        lastSeen: String?
    ) {
        self.defaults = defaults
        self.shortVersion = shortVersion
        self.buildNumber = buildNumber
        self.seededLastSeen = .some(lastSeen)
    }

    static var currentShortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
    }

    static var currentBuildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
    }

    private var lastSeen: String? {
        if let seeded = seededLastSeen {
            return seeded
        }
        return defaults.string(forKey: Self.lastSeenVersionKey)
    }

    /// The entry to present this launch, if any. A first-ever launch records
    /// the current version so a fresh install never sees the sheet.
    func entryToPresent(
        lookup: (String) -> ReleaseNotesEntry? = ReleaseNotes.entry(forVersion:)
    ) -> ReleaseNotesEntry? {
        guard let lastSeen else {
            markCurrentVersionSeen()
            return nil
        }
        guard lastSeen != versionIdentity else {
            return nil
        }
        return lookup(shortVersion)
    }

    func markCurrentVersionSeen() {
        defaults.set(versionIdentity, forKey: Self.lastSeenVersionKey)
    }
}
