import Foundation
import Testing
@testable import FeedGood

struct WhatsNewTests {
    private func makeDefaults() -> UserDefaults {
        let suiteName = "WhatsNewTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName)
        #expect(defaults != nil)
        return defaults ?? .standard
    }

    @Test func freshInstallRecordsTheVersionAndShowsNothing() {
        let defaults = makeDefaults()
        let store = WhatsNewStore(defaults: defaults, shortVersion: "0.1.46", buildNumber: "46")
        #expect(store.entryToPresent() == nil)
        #expect(defaults.string(forKey: WhatsNewStore.lastSeenVersionKey) == "0.1.46 (46)")
    }

    @Test func relaunchOnTheSameVersionShowsNothing() {
        let defaults = makeDefaults()
        defaults.set("0.1.46 (46)", forKey: WhatsNewStore.lastSeenVersionKey)
        let store = WhatsNewStore(defaults: defaults, shortVersion: "0.1.46", buildNumber: "46")
        #expect(store.entryToPresent() == nil)
    }

    @Test func updateToAVersionWithNotesShowsTheEntryUntilDismissed() {
        let defaults = makeDefaults()
        defaults.set("0.1.0 (1)", forKey: WhatsNewStore.lastSeenVersionKey)
        let store = WhatsNewStore(defaults: defaults, shortVersion: "0.1.46", buildNumber: "46")
        let expected = ReleaseNotes.entry(forVersion: "0.1.46")
        #expect(store.entryToPresent() == expected)
        #expect(store.entryToPresent() == expected)
        store.markCurrentVersionSeen()
        #expect(store.entryToPresent() == nil)
        #expect(defaults.string(forKey: WhatsNewStore.lastSeenVersionKey) == "0.1.46 (46)")
    }

    @Test func updateToAVersionWithoutNotesShowsNothingAndStaysPending() {
        let defaults = makeDefaults()
        defaults.set("0.1.0 (1)", forKey: WhatsNewStore.lastSeenVersionKey)
        let store = WhatsNewStore(defaults: defaults, shortVersion: "9.9.9", buildNumber: "1")
        #expect(store.entryToPresent() == nil)
        // The version is not recorded as seen, so the next release that ships
        // notes still appears.
        #expect(defaults.string(forKey: WhatsNewStore.lastSeenVersionKey) == "0.1.0 (1)")
    }

    @Test func releaseNotesLookupFindsKnownVersionsOnly() {
        #expect(ReleaseNotes.entries.isEmpty == false)
        for entry in ReleaseNotes.entries {
            #expect(entry.highlights.isEmpty == false)
            #expect(ReleaseNotes.entry(forVersion: entry.version) == entry)
        }
        #expect(ReleaseNotes.entry(forVersion: "0.0.0") == nil)
    }

    @Test func seededLastSeenReplacesThePersistedValue() {
        let defaults = makeDefaults()
        let updated = WhatsNewStore(defaults: defaults, shortVersion: "0.1.46", buildNumber: "46", lastSeen: "0.1.0 (1)")
        #expect(updated.entryToPresent() == ReleaseNotes.entry(forVersion: "0.1.46"))
        let fresh = WhatsNewStore(defaults: defaults, shortVersion: "0.1.46", buildNumber: "46", lastSeen: nil)
        #expect(fresh.entryToPresent() == nil)
        #expect(defaults.string(forKey: WhatsNewStore.lastSeenVersionKey) == "0.1.46 (46)")
    }
}
