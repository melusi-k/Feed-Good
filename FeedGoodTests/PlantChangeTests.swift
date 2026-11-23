import Foundation
import SwiftData
import Testing
import UIKit
@testable import FeedGood

@MainActor
struct PlantChangeTests {
    private func memory() throws -> ModelContainer {
        let schema = Schema([Plant.self, CareTask.self, CareEvent.self, JournalEntry.self])
        return try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    @Test func changeKindsCoverThePRDSetWithStableTitles() {
        #expect(PlantChangeKind.allCases.map(\.rawValue) == ["movedLocation", "repotted", "potOrSoilChange", "growLightStarted", "growLightStopped", "movedIndoorsOrOutdoors", "custom"])
        #expect(PlantChangeKind.allCases.map(\.title) == ["Moved location", "Repotted", "Changed pot or soil", "Grow light started", "Grow light stopped", "Moved indoors or outdoors", "Custom change"])
        #expect(Set(PlantChangeKind.allCases.map(\.rawValue)).count == PlantChangeKind.allCases.count)
    }

    @Test func changeOnlyDraftValidatesAndCustomChangeRequiresItsNote() {
        #expect(JournalDraft(changeKind: .repotted).isValid)
        #expect(JournalDraft(changeKind: .movedLocation).isValid)
        #expect(JournalDraft(changeKind: .custom).isValid == false)
        #expect(JournalDraft(note: "Switched to a terracotta pot", changeKind: .custom).isValid)
        #expect(JournalDraft(changeKind: nil, milestone: nil).isValid == false)
    }

    @Test func oneRecordIsOneKindNeverBothMilestoneAndChange() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        #expect(throws: (any Error).self) {
            try JournalStore.save(JournalDraft(milestone: .newLeaf, changeKind: .repotted), plant: plant, entry: nil, context: context)
        }
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
    }

    @Test func changeRecordSavesEditsAndClearsWithoutTouchingNoteOrPhoto() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        try JournalStore.save(JournalDraft(note: "Closer to the window", changeKind: .movedLocation), plant: plant, entry: nil, context: context)
        let entry = try #require(context.fetch(FetchDescriptor<JournalEntry>()).first)
        let id = entry.id
        #expect(entry.changeKind == .movedLocation)
        #expect(entry.milestoneRaw == nil)
        try JournalStore.save(JournalDraft(date: entry.date, note: entry.note, changeKind: .growLightStarted), plant: plant, entry: entry, context: context)
        #expect(entry.id == id)
        #expect(entry.changeKind == .growLightStarted)
        #expect(entry.note == "Closer to the window")
        // Clearing the structured kind returns the record to an ordinary observation.
        try JournalStore.save(JournalDraft(date: entry.date, note: entry.note), plant: plant, entry: entry, context: context)
        #expect(entry.changeKindRaw == nil)
        #expect(entry.note == "Closer to the window")
        #expect(throws: (any Error).self) { try JournalStore.save(JournalDraft(), plant: plant, entry: entry, context: context) }
        #expect(entry.note == "Closer to the window")
    }

    @Test func storyProjectsChangeForItsOwnPlantOnlyWithDeterministicEqualDateOrder() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); let other = Plant(name: "Aloe")
        context.insert(plant); context.insert(other)
        let date = Date(timeIntervalSince1970: 500)
        let change = JournalEntry(date: date, note: "North room", changeKindRaw: "movedLocation", plant: plant)
        let foreign = JournalEntry(date: date, note: "Not this plant", changeKindRaw: "repotted", plant: other)
        context.insert(change); context.insert(foreign); try context.save()
        let items = PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: [foreign, change])
        #expect(items.map(\.id) == ["journal.\(change.id.uuidString)"])
        if case .journal(let entry) = items[0] { #expect(entry.changeKind == .movedLocation) } else { Issue.record("Expected change record") }
        // Equal timestamps keep the documented tie-break: namespaced stable ID, ascending.
        let first = PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: [change])
        let second = PlantStory.items(plantID: plant.id, careEvents: [], journalEntries: [change])
        #expect(first.map(\.id) == second.map(\.id))
        #expect(PlantStory.items(plantID: other.id, careEvents: [], journalEntries: [foreign, change]).map(\.id) == ["journal.\(foreign.id.uuidString)"])
    }

    @Test func editingOrDeletingOneChangeLeavesOtherRecordsIntact() throws {
        let container = try memory(); let context = ModelContext(container)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant); context.insert(task)
        let event = CareEvent(task: task, completedAt: Date(timeIntervalSince1970: 200)); context.insert(event)
        let change = JournalEntry(date: Date(timeIntervalSince1970: 300), note: "New pot", changeKindRaw: "potOrSoilChange", plant: plant)
        let observation = JournalEntry(date: Date(timeIntervalSince1970: 100), note: "Kept observation", plant: plant)
        context.insert(change); context.insert(observation); try context.save()
        try JournalStore.delete(change, context: context)
        let remaining = try context.fetch(FetchDescriptor<JournalEntry>())
        #expect(remaining.map(\.id) == [observation.id])
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).count == 1)
        #expect(try context.fetch(FetchDescriptor<CareTask>()).count == 1)
        try JournalStore.save(JournalDraft(date: observation.date, note: "Still only this record", changeKind: .repotted), plant: plant, entry: observation, context: context)
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).count == 1)
        #expect(event.note.isEmpty)
    }

    @Test func archiveRoundTripPreservesChangeKindPhotoAndPlantIdentity() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Fern"); context.insert(plant)
        let photo = UIImage(systemName: "leaf").flatMap { $0.pngData() }
        try JournalStore.save(JournalDraft(note: "Balcony move", photoData: photo, changeKind: .movedIndoorsOrOutdoors), plant: plant, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let data = try JournalArchive.export(plants: [plant], entries: entries)
        let archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(archive.version == 2)
        #expect(archive.entries.first?.changeKindRaw == "movedIndoorsOrOutdoors")
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: recovery) == 1)
        let restored = try #require(recovery.fetch(FetchDescriptor<JournalEntry>()).first)
        #expect(restored.changeKind == .movedIndoorsOrOutdoors)
        #expect(restored.photoData == photo)
        #expect(restored.plant?.id == plant.id)
        // Identical content recovers as a no-op; a locally changed kind conflicts and restores nothing new.
        #expect(try JournalArchive.recover(data, context: recovery) == 0)
        restored.changeKindRaw = PlantChangeKind.repotted.rawValue; try recovery.save()
        #expect(throws: (any Error).self) { try JournalArchive.recover(data, context: recovery) }
        #expect(try recovery.fetch(FetchDescriptor<JournalEntry>()).count == 1)
    }

    @Test func archiveRejectsUnknownOrConflictingChangeKinds() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Fern"); context.insert(plant)
        try JournalStore.save(JournalDraft(changeKind: .repotted), plant: plant, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let exported = try JournalArchive.export(plants: [plant], entries: entries)
        var object = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        var records = try #require(object["entries"] as? [[String: Any]])
        records[0]["changeKindRaw"] = "radioactiveRepotting"; object["entries"] = records
        let tampered = try JSONSerialization.data(withJSONObject: object)
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(throws: (any Error).self) { try JournalArchive.recover(tampered, context: recovery) }
        #expect(try recovery.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
        // A custom change without its note is not a valid record.
        var objectTwo = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        var recordsTwo = try #require(objectTwo["entries"] as? [[String: Any]])
        recordsTwo[0]["changeKindRaw"] = PlantChangeKind.custom.rawValue
        recordsTwo[0]["note"] = "   "; objectTwo["entries"] = recordsTwo
        let blankCustom = try JSONSerialization.data(withJSONObject: objectTwo)
        #expect(throws: (any Error).self) { try JournalArchive.recover(blankCustom, context: recovery) }
    }

    @Test func preChangeArchivesDecodeWithNilKindAndRecoverAsObservations() throws {
        let source = try memory(); let context = ModelContext(source)
        let plant = Plant(name: "Legacy fern"); context.insert(plant)
        let entry = JournalEntry(note: "Legacy note", milestoneRaw: "newLeaf", plant: plant); context.insert(entry); try context.save()
        let exported = try JournalArchive.export(plants: [plant], entries: [entry])
        var object = try #require(JSONSerialization.jsonObject(with: exported) as? [String: Any])
        var records = try #require(object["entries"] as? [[String: Any]])
        records[0].removeValue(forKey: "changeKindRaw"); object["entries"] = records
        let legacy = try JSONSerialization.data(withJSONObject: object)
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: legacy)
        #expect(decoded.entries.first?.changeKindRaw == nil)
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(try JournalArchive.recover(legacy, context: recovery) == 1)
        let restored = try #require(recovery.fetch(FetchDescriptor<JournalEntry>()).first)
        #expect(restored.changeKind == nil)
        #expect(restored.milestone == .newLeaf)
    }
}
