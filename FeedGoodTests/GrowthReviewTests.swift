import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct GrowthReviewTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func photo() -> Data { Data([0x01, 0x02]) }

    @Test func onlyThisPlantsPhotoEntriesNewestFirst() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); let other = Plant(name: "Aloe")
        context.insert(plant); context.insert(other)
        let old = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "Old", photoData: photo(), plant: plant)
        let new = JournalEntry(date: Date(timeIntervalSince1970: 200), note: "New", photoData: photo(), milestoneRaw: "newLeaf", plant: plant)
        let noPhoto = JournalEntry(date: Date(timeIntervalSince1970: 300), note: "Note only", plant: plant)
        let otherPlant = JournalEntry(date: Date(timeIntervalSince1970: 400), note: "Other", photoData: photo(), plant: other)
        for entry in [old, new, noPhoto, otherPlant] { context.insert(entry) }
        try context.save()
        let all = try context.fetch(FetchDescriptor<JournalEntry>())
        let items = GrowthReview.entries(plantID: plant.id, from: all)
        #expect(items.map(\.id) == [new.id, old.id])
    }

    @Test func equalDatesDeterministicRegardlessOfInputOrder() throws {
        let plant = Plant(name: "Fern")
        let date = Date(timeIntervalSince1970: 10)
        let a = JournalEntry(date: date, note: "A", photoData: photo(), plant: plant)
        let b = JournalEntry(date: date, note: "B", photoData: photo(), plant: plant)
        let first = GrowthReview.entries(plantID: plant.id, from: [a, b]).map(\.id)
        let second = GrowthReview.entries(plantID: plant.id, from: [b, a]).map(\.id)
        let expected = [a.id, b.id].sorted { $0.uuidString < $1.uuidString }
        #expect(first == second)
        #expect(first == expected)
    }

    @Test func comparisonOrdersEarlierThenLaterAndRejectsInvalidSelection() throws {
        let plant = Plant(name: "Fern")
        let older = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "Older", photoData: photo(), plant: plant)
        let newer = JournalEntry(date: Date(timeIntervalSince1970: 200), note: "Newer", photoData: photo(), plant: plant)
        let comparison = try #require(GrowthReview.comparison([newer, older]))
        #expect(comparison.earlier.id == older.id)
        #expect(comparison.later.id == newer.id)
        let single = GrowthReview.comparison([older])
        #expect(single == nil)
        let empty = GrowthReview.comparison([])
        #expect(empty == nil)
        let duplicate = GrowthReview.comparison([older, older])
        #expect(duplicate == nil)
    }

    @Test func comparisonRejectsEntriesFromDifferentPlants() throws {
        let fern = Plant(name: "Fern"); let aloe = Plant(name: "Aloe")
        let a = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "A", photoData: photo(), plant: fern)
        let b = JournalEntry(date: Date(timeIntervalSince1970: 200), note: "B", photoData: photo(), plant: aloe)
        let cross = GrowthReview.comparison([a, b])
        #expect(cross == nil)
    }

    @Test func photoRemovalAndDeletionReprojectWithoutLosingUnrelatedEntries() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); let other = Plant(name: "Aloe")
        context.insert(plant); context.insert(other)
        let keep = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "Keep", photoData: photo(), plant: plant)
        let losesPhoto = JournalEntry(date: Date(timeIntervalSince1970: 200), note: "Loses photo", photoData: photo(), plant: plant)
        let deleted = JournalEntry(date: Date(timeIntervalSince1970: 300), note: "Deleted", photoData: photo(), plant: plant)
        let unrelated = JournalEntry(date: Date(timeIntervalSince1970: 400), note: "Other plant", photoData: photo(), plant: other)
        for entry in [keep, losesPhoto, deleted, unrelated] { context.insert(entry) }
        try context.save()
        losesPhoto.photoData = nil
        try context.save()
        try JournalStore.delete(deleted, context: context)
        let all = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(GrowthReview.entries(plantID: plant.id, from: all).map(\.id) == [keep.id])
        #expect(GrowthReview.entries(plantID: other.id, from: all).map(\.id) == [unrelated.id])
    }
}
