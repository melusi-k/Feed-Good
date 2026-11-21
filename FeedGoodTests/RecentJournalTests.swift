import XCTest
import SwiftData
@testable import FeedGood

@MainActor
final class RecentJournalTests: XCTestCase {
    func testNewestThreeWithStableTiesAndNoOrphans() {
        let plant = Plant(name: "Fern")
        let entries = (0..<5).map { JournalEntry(date: Date(timeIntervalSince1970: Double($0)), note: "Note \($0)", plant: plant) }
        let orphan = JournalEntry(date: .distantFuture, note: "Orphan", plant: plant); orphan.plant = nil
        XCTAssertEqual(RecentJournal.entries(from: entries + [orphan]).map(\.id), [entries[4].id, entries[3].id, entries[2].id])
        entries[0].date = entries[4].date
        let forward = RecentJournal.entries(from: entries).map(\.id)
        XCTAssertEqual(forward, RecentJournal.entries(from: entries.reversed()).map(\.id))
        XCTAssertEqual(Set(forward).count, 3)
        XCTAssertTrue(RecentJournal.entries(from: entries, limit: 0).isEmpty)
        XCTAssertTrue(RecentJournal.entries(from: [], limit: 3).isEmpty)
    }

    func testSourceEditsAndDeletionAreReflectedWithoutCopies() throws {
        let schema = Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self])
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = ModelContext(container)
        let first = Plant(name: "Fern"); let second = Plant(name: "Aloe")
        context.insert(first); context.insert(second)
        let older = JournalEntry(date: Date(timeIntervalSince1970: 1), note: "Before", plant: first)
        let newer = JournalEntry(date: Date(timeIntervalSince1970: 2), note: "Other", milestoneRaw: "flowering", plant: second)
        context.insert(older); context.insert(newer); try context.save()
        func recent() throws -> [JournalEntry] { RecentJournal.entries(from: try context.fetch(FetchDescriptor<JournalEntry>())) }
        XCTAssertEqual(try recent().first?.plant?.id, second.id)
        try JournalStore.save(JournalDraft(date: Date(timeIntervalSince1970: 3), note: "After"), plant: first, entry: older, context: context)
        XCTAssertEqual(try recent().first?.id, older.id)
        XCTAssertEqual(try recent().first?.note, "After")
        XCTAssertEqual(try recent().count, 2)
        try JournalStore.delete(older, context: context)
        XCTAssertEqual(try recent().map(\.id), [newer.id])
        XCTAssertEqual(newer.milestone, .flowering)
        try JournalStore.delete(newer, context: context)
        XCTAssertTrue(try recent().isEmpty)
        XCTAssertEqual(try context.fetch(FetchDescriptor<Plant>()).count, 2)
    }
}
