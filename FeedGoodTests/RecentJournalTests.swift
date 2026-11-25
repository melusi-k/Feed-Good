import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct RecentJournalTests {
    @Test func newestThreeWithStableTiesAndNoOrphans() {
        let plant = Plant(name: "Fern")
        let entries = (0..<5).map { JournalEntry(date: Date(timeIntervalSince1970: Double($0)), note: "Note \($0)", plant: plant) }
        let orphan = JournalEntry(date: .distantFuture, note: "Orphan", plant: plant); orphan.plant = nil
        #expect(RecentJournal.entries(from: entries + [orphan]).map(\.id) == [entries[4].id, entries[3].id, entries[2].id])
        entries[0].date = entries[4].date
        let forward = RecentJournal.entries(from: entries).map(\.id)
        #expect(forward == RecentJournal.entries(from: entries.reversed()).map(\.id))
        #expect(Set(forward).count == 3)
        #expect(RecentJournal.entries(from: entries, limit: 0).isEmpty)
        #expect(RecentJournal.entries(from: [], limit: 3).isEmpty)
    }

    @Test func sourceEditsAndDeletionAreReflectedWithoutCopies() throws {
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let first = Plant(name: "Fern"); let second = Plant(name: "Aloe")
        context.insert(first); context.insert(second)
        let older = JournalEntry(date: Date(timeIntervalSince1970: 1), note: "Before", plant: first)
        let newer = JournalEntry(date: Date(timeIntervalSince1970: 2), note: "Other", milestoneRaw: "flowering", plant: second)
        context.insert(older); context.insert(newer); try context.save()
        func recent() throws -> [JournalEntry] { RecentJournal.entries(from: try context.fetch(FetchDescriptor<JournalEntry>())) }
        #expect(try recent().first?.plant?.id == second.id)
        try JournalStore.save(JournalDraft(date: Date(timeIntervalSince1970: 3), note: "After"), plant: first, entry: older, context: context)
        #expect(try recent().first?.id == older.id)
        #expect(try recent().first?.note == "After")
        #expect(try recent().count == 2)
        try JournalStore.delete(older, context: context)
        #expect(try recent().map(\.id) == [newer.id])
        #expect(newer.milestone == .flowering)
        try JournalStore.delete(newer, context: context)
        #expect(try recent().isEmpty)
        #expect(try context.fetch(FetchDescriptor<Plant>()).count == 2)
    }
}
