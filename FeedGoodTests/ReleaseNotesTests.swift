import Testing
@testable import FeedGood

struct ReleaseNotesTests {
    @Test func everyBundledEntryHasAUniqueVersionAndAtLeastOneHighlight() {
        let entries = ReleaseNotes.entries
        #expect(entries.isEmpty == false)
        #expect(Set(entries.map(\.version)).count == entries.count)
        #expect(entries.allSatisfy { $0.highlights.isEmpty == false })
    }

    @Test func lookupReturnsOnlyAnExactMarketingVersionMatch() {
        for entry in ReleaseNotes.entries {
            #expect(ReleaseNotes.entry(forVersion: entry.version) == entry)
        }
        #expect(ReleaseNotes.entry(forVersion: "9.9.9") == nil)
        #expect(ReleaseNotes.entry(forVersion: "0.1.46 (46)") == nil)
    }

    @Test func presentationLookupPrefersAnExactMatch() throws {
        for entry in ReleaseNotes.entries {
            #expect(ReleaseNotes.entryForPresentation(version: entry.version) == entry)
        }
    }

    @Test func presentationLookupFallsBackToTheNewestBundledRelease() throws {
        let newest = try #require(ReleaseNotes.entries.first)
        // A CI build stamped with the run number has no entry of its own.
        #expect(ReleaseNotes.entryForPresentation(version: "0.1.108") == newest)
        #expect(ReleaseNotes.entryForPresentation(version: "9.9.9") == newest)
        #expect(ReleaseNotes.entryForPresentation(version: "0.1.46 (46)") == newest)
    }
}
