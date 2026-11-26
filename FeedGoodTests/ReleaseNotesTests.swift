import Testing
@testable import FeedGood

struct ReleaseNotesTests {
    @Test func everyBundledEntryHasAUniqueVersionAndAtLeastOneHighlight() {
        let entries = ReleaseNotes.entries
        #expect(entries.isEmpty == false)
        #expect(Set(entries.map(\\.version)).count == entries.count)
        #expect(entries.allSatisfy { $0.highlights.isEmpty == false })
    }

    @Test func lookupReturnsOnlyAnExactMarketingVersionMatch() {
        for entry in ReleaseNotes.entries {
            #expect(ReleaseNotes.entry(forVersion: entry.version) == entry)
        }
        #expect(ReleaseNotes.entry(forVersion: "9.9.9") == nil)
        #expect(ReleaseNotes.entry(forVersion: "0.1.46 (46)") == nil)
    }
}
