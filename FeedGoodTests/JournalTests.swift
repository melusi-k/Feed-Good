import Testing
import SwiftData
import UIKit
@testable import FeedGood

@MainActor
struct JournalTests {
    private var schema: Schema { Schema(versionedSchema: FeedGoodSchemaV7.self) }
    private func memory() throws -> ModelContainer {
        try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
    }

    private func samplePhoto() -> Data {
        UIGraphicsImageRenderer(size: CGSize(width: 3, height: 3)).image { context in
            context.cgContext.setFillColor(UIColor.systemGreen.cgColor)
            context.cgContext.fill(CGRect(x: 0, y: 0, width: 3, height: 3))
        }.pngData()!
    }

    @Test func draftNeedsANoteOrPhoto() {
        #expect(JournalDraft(note: " \n ").isValid == false)
        #expect(JournalDraft(note: "New leaf").isValid)
        #expect(JournalDraft(photoData: Data([1])).isValid)
    }

    @Test func diskReopenAssociationEditDeleteAndCascade() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: folder) }
        let config = ModelConfiguration(schema: schema, url: folder.appendingPathComponent("journal.store"))
        let firstID: UUID
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container)
            let first = Plant(name: "Fern"); let second = Plant(name: "Aloe")
            firstID = first.id
            context.insert(first); context.insert(second)
            try JournalStore.save(JournalDraft(note: " First leaf "), plant: first, entry: nil, context: context)
            let saved = try #require(context.fetch(FetchDescriptor<JournalEntry>()).first)
            #expect(saved.note == "First leaf")
            try JournalStore.save(JournalDraft(note: "Second leaf"), plant: first, entry: saved, context: context)
        }
        do {
            let container = try ModelContainer(for: schema, configurations: config)
            let context = ModelContext(container)
            let entries = try context.fetch(FetchDescriptor<JournalEntry>())
            #expect(entries.count == 1)
            #expect(entries.first?.plant?.id == firstID)
            #expect(entries.first?.note == "Second leaf")
            let plants = try context.fetch(FetchDescriptor<Plant>())
            let first = try #require(plants.first { $0.id == firstID })
            #expect(first.journalEntries?.count == 1)
            #expect((plants.first { $0.id != firstID }?.journalEntries ?? []).isEmpty)
            try JournalStore.delete(try #require(entries.first), context: context)
            #expect(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
            try JournalStore.save(JournalDraft(note: "One more"), plant: first, entry: nil, context: context)
            context.delete(first); try context.save()
            #expect(try context.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
            #expect(try context.fetch(FetchDescriptor<Plant>()).count == 1)
        }
    }

    @Test func archiveRecoverIsAdditiveIdempotentAndPreservesExistingDetails() throws {
        let source = try memory(); let context = ModelContext(source)
        let fern = Plant(name: "Fern"); context.insert(fern)
        try JournalStore.save(JournalDraft(note: "A new leaf"), plant: fern, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        let data = try JournalArchive.export(plants: [fern], entries: entries)
        let destination = try memory(); let recovery = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: recovery) == 1)
        let restored = try #require(recovery.fetch(FetchDescriptor<Plant>()).first)
        restored.name = "My renamed fern"; try recovery.save()
        #expect(try JournalArchive.recover(data, context: recovery) == 0)
        #expect(restored.name == "My renamed fern")
        #expect(try recovery.fetch(FetchDescriptor<JournalEntry>()).first?.plant?.id == fern.id)
        #expect(try recovery.fetch(FetchDescriptor<JournalEntry>()).count == 1)
    }

    @Test func versionTwoRoundTripIncludesProfilePhotosCareTasksAndCareHistory() throws {
        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(
            name: "Fern", species: "Nephrolepis",
            growingEnvironment: .balcony, lightCondition: .indirect,
            photoData: samplePhoto(),
            archivedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        sourceContext.insert(plant)
        let dueDate = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 9,
            dueDate: dueDate,
            isEnabled: false,
            reminderEnabled: true,
            plant: plant
        )
        sourceContext.insert(task)
        let event = CareEvent(task: task, completedAt: dueDate.addingTimeInterval(-86_400), note: "Checked soil first")
        sourceContext.insert(event)
        try JournalStore.save(JournalDraft(note: "New frond", photoData: samplePhoto()), plant: plant, entry: nil, context: sourceContext)

        let data = try JournalArchive.export(
            plants: [plant],
            entries: sourceContext.fetch(FetchDescriptor<JournalEntry>()),
            careTasks: [task],
            careEvents: [event]
        )
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(decoded.version == 6)
        #expect(decoded.careTasks?.count == 1)
        #expect(decoded.careEvents?.count == 1)

        let destination = try memory()
        let destinationContext = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: destinationContext) == 1)

        let restoredPlant = try #require(destinationContext.fetch(FetchDescriptor<Plant>()).first)
        #expect(restoredPlant.id == plant.id)
        #expect(restoredPlant.name == "Fern")
        #expect(restoredPlant.photoData == plant.photoData)
        #expect(restoredPlant.growingEnvironment == .balcony)
        #expect(restoredPlant.lightCondition == .indirect)
        #expect(restoredPlant.archivedAt == plant.archivedAt)

        let restoredTask = try #require(destinationContext.fetch(FetchDescriptor<CareTask>()).first)
        #expect(restoredTask.id == task.id)
        #expect(restoredTask.intervalDays == 9)
        #expect(restoredTask.dueDate == dueDate)
        #expect(restoredTask.isEnabled == false)
        #expect(restoredTask.reminderEnabled)
        #expect(restoredTask.plant?.id == plant.id)

        let restoredEvent = try #require(destinationContext.fetch(FetchDescriptor<CareEvent>()).first)
        #expect(restoredEvent.id == event.id)
        #expect(restoredEvent.taskID == task.id)
        #expect(restoredEvent.taskTitle == task.title)
        #expect(restoredEvent.note == "Checked soil first")
        #expect(restoredEvent.plant?.id == plant.id)

        let restoredEntry = try #require(destinationContext.fetch(FetchDescriptor<JournalEntry>()).first)
        let sourcePhoto = try #require(sourceContext.fetch(FetchDescriptor<JournalEntry>()).first?.photoData)
        #expect(restoredEntry.photoData == sourcePhoto)
    }

    @Test func versionOneJournalArchiveRemainsImportable() throws {
        let plant = Plant(name: "Legacy fern")
        let entry = JournalArchive.EntryRecord(id: UUID(), plantID: plant.id, date: .now, note: "Legacy note", photoData: nil)
        var legacy = JournalArchive(
            plants: [JournalArchive.PlantRecord(id: plant.id, name: plant.name, species: "", notes: "", createdAt: plant.createdAt)],
            entries: [entry],
            careTasks: nil,
            careEvents: nil
        )
        legacy.version = 1
        let data = try JSONEncoder().encode(legacy)

        let destination = try memory()
        let context = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: context) == 1)
        #expect(try context.fetch(FetchDescriptor<Plant>()).first?.name == "Legacy fern")
        #expect(try context.fetch(FetchDescriptor<JournalEntry>()).first?.note == "Legacy note")
        #expect(try context.fetch(FetchDescriptor<CareTask>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).isEmpty)
    }

    @Test func archivePreviewShowsNewAndAlreadyPresentRecordCounts() throws {
        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(name: "Fern")
        sourceContext.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        sourceContext.insert(task)
        let event = CareEvent(task: task, note: "Checked soil")
        sourceContext.insert(event)
        try JournalStore.save(JournalDraft(note: "New frond"), plant: plant, entry: nil, context: sourceContext)

        let data = try JournalArchive.export(
            plants: [plant],
            entries: sourceContext.fetch(FetchDescriptor<JournalEntry>()),
            careTasks: [task],
            careEvents: [event]
        )
        let destination = try memory()
        let destinationContext = ModelContext(destination)
        destinationContext.insert(Plant(id: plant.id, name: "Existing fern"))
        try destinationContext.save()

        let preview = try JournalArchive.preview(data, context: destinationContext)
        #expect(preview.version == 6)
        #expect(preview.plantsToAdd == 0)
        #expect(preview.plantsAlreadyPresent == 1)
        #expect(preview.entriesToAdd == 1)
        #expect(preview.entriesAlreadyPresent == 0)
        #expect(preview.careTasksToAdd == 1)
        #expect(preview.careEventsToAdd == 1)
        #expect(preview.confirmationMessage.contains("any conflict"))
        #expect(preview.confirmationMessage.contains("existing same-ID plants keep their current state"))
    }

    @Test func archiveConflictAndMalformedReferencesRejectBeforeWrites() throws {
        let container = try memory(); let context = ModelContext(container)
        let fern = Plant(name: "Fern"); context.insert(fern)
        try JournalStore.save(JournalDraft(note: "Original"), plant: fern, entry: nil, context: context)
        let entries = try context.fetch(FetchDescriptor<JournalEntry>())
        var archive = try JSONDecoder().decode(JournalArchive.self, from: JournalArchive.export(plants: [fern], entries: entries))
        archive.entries[0].note = "Conflicting"
        #expect(throws: JournalArchiveError.conflictingRecord) {
            try JournalArchive.recover(JSONEncoder().encode(archive), context: context)
        }
        #expect(entries.first?.note == "Original")
        archive.entries[0].plantID = UUID()
        #expect(throws: JournalArchiveError.invalidRecord) {
            try JournalArchive.recover(JSONEncoder().encode(archive), context: context)
        }
        #expect(try context.fetch(FetchDescriptor<Plant>()).count == 1)
        archive.version = 999
        #expect(throws: JournalArchiveError.unsupportedVersion) {
            try archive.validate()
        }
        archive.version = 2
        archive.entries[0].plantID = fern.id
        archive.entries[0].photoData = Data([1, 2, 3])
        #expect(throws: JournalArchiveError.invalidRecord) {
            try archive.validate()
        }
    }

    @Test func careRecordConflictsRejectWithoutChangingExistingRecords() throws {
        let container = try memory()
        let context = ModelContext(container)
        let plant = Plant(name: "Fern")
        context.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .now, plant: plant)
        context.insert(task)
        let event = CareEvent(task: task, note: "Original")
        context.insert(event)
        try context.save()

        let data = try JournalArchive.export(plants: [plant], entries: [], careTasks: [task], careEvents: [event])
        var archive = try JSONDecoder().decode(JournalArchive.self, from: data)
        archive.careTasks?[0].intervalDays = 12

        #expect(throws: JournalArchiveError.conflictingRecord) {
            try JournalArchive.recover(JSONEncoder().encode(archive), context: context)
        }
        #expect(try context.fetch(FetchDescriptor<CareTask>()).first?.intervalDays == 7)
        #expect(try context.fetch(FetchDescriptor<CareEvent>()).first?.note == "Original")
    }

    @Test func versionOneArchiveWithoutGrowingContextFieldsRemainsDecodable() throws {
        let plant = Plant(name: "Legacy fern")
        let entry = JournalArchive.EntryRecord(id: UUID(), plantID: plant.id, date: .now, note: "Legacy note", photoData: nil)
        var legacy = JournalArchive(
            plants: [JournalArchive.PlantRecord(id: plant.id, name: plant.name, species: "", notes: "", createdAt: plant.createdAt)],
            entries: [entry], careTasks: nil, careEvents: nil
        )
        legacy.version = 1
        let data = try JSONEncoder().encode(legacy)
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(decoded.plants.first?.growingEnvironmentRaw == nil)
        #expect(decoded.plants.first?.lightConditionRaw == nil)

        let context = ModelContext(try memory())
        #expect(try JournalArchive.recover(data, context: context) == 1)
        let restored = try #require(context.fetch(FetchDescriptor<Plant>()).first)
        #expect(restored.growingEnvironment == .unspecified)
        #expect(restored.lightCondition == .unspecified)
        #expect(restored.archivedAt == nil)
    }

    @Test func recoveryKeepsUnsavedCallerChanges() throws {
        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(name: "Archive fern", growingEnvironment: .outdoor, lightCondition: .direct)
        sourceContext.insert(plant)
        try sourceContext.save()
        let data = try JournalArchive.export(plants: [plant], entries: [])

        let destination = try memory()
        let callerContext = ModelContext(destination)
        let pendingPlant = Plant(name: "Unsaved local plant")
        callerContext.insert(pendingPlant)
        #expect(callerContext.hasChanges)

        #expect(throws: JournalArchiveError.unsavedChanges) {
            try JournalArchive.recover(data, context: callerContext)
        }
        #expect(callerContext.hasChanges)
        #expect(try callerContext.fetch(FetchDescriptor<Plant>()).contains { $0.id == pendingPlant.id })

        let verificationContext = ModelContext(destination)
        #expect(try verificationContext.fetch(FetchDescriptor<Plant>()).isEmpty)
    }



    @Test func archiveEnforcesOneThousandRecordsPerCollection() throws {
        let plants = (0..<JournalArchive.maxRecords).map { index in
            JournalArchive.PlantRecord(
                id: UUID(), name: "Plant \(index)", species: "", notes: "",
                createdAt: Date(timeIntervalSince1970: TimeInterval(index))
            )
        }
        let entries = (0..<JournalArchive.maxRecords).map { index in
            JournalArchive.EntryRecord(
                id: UUID(), plantID: plants[0].id, date: Date(timeIntervalSince1970: TimeInterval(index)),
                note: "Entry \(index)", photoData: nil
            )
        }
        let tasks = (0..<JournalArchive.maxRecords).map { _ in
            JournalArchive.CareTaskRecord(
                id: UUID(), plantID: plants[0].id, kindRaw: CareKind.watering.rawValue,
                customTitle: "", intervalDays: 7, dueDate: .distantFuture,
                isEnabled: true, reminderEnabled: false
            )
        }
        let events = (0..<JournalArchive.maxRecords).map { _ in
            JournalArchive.CareEventRecord(
                id: UUID(), plantID: plants[0].id, taskID: UUID(),
                taskTitle: "Watering", completedAt: .now, note: ""
            )
        }
        var archive = JournalArchive(plants: plants, entries: entries, careTasks: tasks, careEvents: events)

        archive.entries.removeLast()
        try archive.validate()
        archive.entries = entries
        try archive.validate()

        archive.entries.append(
            JournalArchive.EntryRecord(id: UUID(), plantID: plants[0].id, date: .now, note: "Entry 1001", photoData: nil)
        )
        #expect(throws: JournalArchiveError.tooLarge) { try archive.validate() }

        archive.entries = entries
        archive.plants.append(
            JournalArchive.PlantRecord(id: UUID(), name: "Plant 1001", species: "", notes: "", createdAt: .now)
        )
        #expect(throws: JournalArchiveError.tooLarge) { try archive.validate() }

        archive.plants = plants
        archive.careTasks?.append(
            JournalArchive.CareTaskRecord(id: UUID(), plantID: plants[0].id, kindRaw: CareKind.watering.rawValue, customTitle: "", intervalDays: 7, dueDate: .distantFuture, isEnabled: true, reminderEnabled: false)
        )
        #expect(throws: JournalArchiveError.tooLarge) { try archive.validate() }

        archive.careTasks = tasks
        archive.careEvents?.append(
            JournalArchive.CareEventRecord(id: UUID(), plantID: plants[0].id, taskID: UUID(), taskTitle: "Watering", completedAt: .now, note: "")
        )
        #expect(throws: JournalArchiveError.tooLarge) { try archive.validate() }
    }

    @Test func archiveAcceptsTwentyFiveMegabytesAndRejectsOneByteMore() throws {
        let context = ModelContext(try memory())
        let archive = JournalArchive(plants: [], entries: [], careTasks: [], careEvents: [])
        let encoded = try JSONEncoder().encode(archive)
        var belowLimit = encoded
        belowLimit.append(Data(repeating: 0x20, count: JournalArchive.maxBytes - encoded.count - 1))
        #expect(belowLimit.count == JournalArchive.maxBytes - 1)
        #expect(try JournalArchive.preview(belowLimit, context: context).plantsToAdd == 0)

        var exactLimit = encoded
        exactLimit.append(Data(repeating: 0x20, count: JournalArchive.maxBytes - encoded.count))
        #expect(exactLimit.count == JournalArchive.maxBytes)
        #expect(try JournalArchive.preview(exactLimit, context: context).plantsToAdd == 0)

        var overLimit = exactLimit
        overLimit.append(0x20)
        #expect(throws: JournalArchiveError.tooLarge) {
            try JournalArchive.preview(overLimit, context: context)
        }
    }

    @Test func failedRecoverySaveRollsBackEveryInsertedRecord() throws {
        enum InjectedSaveFailure: Error { case failed }

        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(name: "Recovery fern")
        sourceContext.insert(plant)
        let task = CareTask(kind: .watering, intervalDays: 7, dueDate: .distantFuture, plant: plant)
        sourceContext.insert(task)
        let event = CareEvent(task: task, note: "Checked soil")
        sourceContext.insert(event)
        try JournalStore.save(JournalDraft(note: "A new frond"), plant: plant, entry: nil, context: sourceContext)
        let archiveData = try JournalArchive.export(
            plants: [plant],
            entries: sourceContext.fetch(FetchDescriptor<JournalEntry>()),
            careTasks: [task],
            careEvents: [event]
        )

        let destination = try memory()
        let initialContext = ModelContext(destination)
        let existingPlant = Plant(name: "Existing local plant")
        initialContext.insert(existingPlant)
        try initialContext.save()

        let recoveryContext = ModelContext(destination)
        #expect(throws: InjectedSaveFailure.self) {
            try JournalArchive.recover(archiveData, context: recoveryContext) { _ in
                throw InjectedSaveFailure.failed
            }
        }

        let verificationContext = ModelContext(destination)
        let plants = try verificationContext.fetch(FetchDescriptor<Plant>())
        #expect(plants.map(\.id) == [existingPlant.id])
        #expect(try verificationContext.fetch(FetchDescriptor<JournalEntry>()).isEmpty)
        #expect(try verificationContext.fetch(FetchDescriptor<CareTask>()).isEmpty)
        #expect(try verificationContext.fetch(FetchDescriptor<CareEvent>()).isEmpty)
    }

    @Test func olderVersionTwoArchiveWithoutArchivedAtDefaultsToActive() throws {
        let plant = Plant(name: "Legacy fern", archivedAt: Date(timeIntervalSince1970: 1_700_000_000))
        var archive = JournalArchive(
            plants: [
                JournalArchive.PlantRecord(
                    id: plant.id, name: plant.name, species: "", notes: "",
                    createdAt: plant.createdAt, archivedAt: plant.archivedAt
                )
            ],
            entries: [],
            careTasks: [],
            careEvents: []
        )
        archive.version = 2
        let encoded = try JSONEncoder().encode(archive)
        var object = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        var plantRecords = try #require(object["plants"] as? [[String: Any]])
        plantRecords[0].removeValue(forKey: "archivedAt")
        object["plants"] = plantRecords
        let legacyData = try JSONSerialization.data(withJSONObject: object)

        let decoded = try JSONDecoder().decode(JournalArchive.self, from: legacyData)
        #expect(decoded.version == 2)
        #expect(decoded.plants.first?.archivedAt == nil)

        let context = ModelContext(try memory())
        #expect(try JournalArchive.recover(legacyData, context: context) == 0)
        #expect(try context.fetch(FetchDescriptor<Plant>()).first?.archivedAt == nil)
    }

    @Test func archiveRecoveryPreservesExistingSameIDPlantState() throws {
        let archivedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let source = Plant(name: "Archived source", archivedAt: archivedAt)
        let data = try JournalArchive.export(plants: [source], entries: [])

        let context = ModelContext(try memory())
        let existing = Plant(id: source.id, name: "Existing local plant")
        context.insert(existing)
        try context.save()

        #expect(try JournalArchive.recover(data, context: context) == 0)
        let unchanged = try #require(context.fetch(FetchDescriptor<Plant>()).first)
        #expect(unchanged.id == source.id)
        #expect(unchanged.name == "Existing local plant")
        #expect(unchanged.archivedAt == nil)
    }

    @Test func duplicatePlantAndJournalArchiveIDsAreRejected() throws {
        let plantID = UUID()
        let duplicatePlants = JournalArchive(
            plants: [
                JournalArchive.PlantRecord(id: plantID, name: "Fern", species: "", notes: "", createdAt: .now),
                JournalArchive.PlantRecord(id: plantID, name: "Aloe", species: "", notes: "", createdAt: .now)
            ],
            entries: [], careTasks: [], careEvents: []
        )
        #expect(throws: JournalArchiveError.invalidRecord) { try duplicatePlants.validate() }

        let plant = Plant(name: "Fern")
        let entryID = UUID()
        let duplicateEntries = JournalArchive(
            plants: [JournalArchive.PlantRecord(id: plant.id, name: plant.name, species: "", notes: "", createdAt: plant.createdAt)],
            entries: [
                JournalArchive.EntryRecord(id: entryID, plantID: plant.id, date: .now, note: "First", photoData: nil),
                JournalArchive.EntryRecord(id: entryID, plantID: plant.id, date: .now, note: "Second", photoData: nil)
            ],
            careTasks: [], careEvents: []
        )
        #expect(throws: JournalArchiveError.invalidRecord) { try duplicateEntries.validate() }
    }


    @Test func correctedAndDeletedCareEventsRoundTripAfterTaskRemoval() throws {
        let source = try memory()
        let sourceContext = ModelContext(source)
        let plant = Plant(name: "Fern")
        sourceContext.insert(plant)
        let dueDate = Date(timeIntervalSince1970: 1_800_000_000)
        let task = CareTask(
            kind: .watering,
            intervalDays: 9,
            dueDate: dueDate,
            isEnabled: true,
            reminderEnabled: true,
            plant: plant
        )
        sourceContext.insert(task)
        let correctedEvent = CareEvent(task: task, completedAt: dueDate.addingTimeInterval(-345_600), note: "Original")
        let deletedEvent = CareEvent(task: task, completedAt: dueDate.addingTimeInterval(-432_000), note: "Remove this")
        sourceContext.insert(correctedEvent)
        sourceContext.insert(deletedEvent)
        try sourceContext.save()

        let referenceNow = dueDate.addingTimeInterval(-172_800)
        let remindersBefore = CareReminderScheduler.reminders(for: [task], now: referenceNow)
        let todayBefore = TodayCare.items(from: [task], now: referenceNow).map(\.id)
        let correctedDate = dueDate.addingTimeInterval(-259_200)
        try CareRecorder.update(
            correctedEvent,
            completedAt: correctedDate,
            note: "Corrected history",
            in: sourceContext
        )
        let remindersAfter = CareReminderScheduler.reminders(for: [task], now: referenceNow)
        let todayAfterCorrection = TodayCare.items(from: [task], now: referenceNow).map(\.id)
        #expect(remindersAfter == remindersBefore)
        #expect(todayAfterCorrection == todayBefore)
        #expect(task.dueDate == dueDate)
        #expect(task.intervalDays == 9)

        try CareRecorder.delete(deletedEvent, in: sourceContext)
        let todayAfterDeletion = TodayCare.items(from: [task], now: referenceNow).map(\.id)
        let remindersAfterDeletion = CareReminderScheduler.reminders(for: [task], now: referenceNow)
        #expect(todayAfterDeletion == todayBefore)
        #expect(remindersAfterDeletion == remindersBefore)

        // Historical events remain independently editable after their routine is removed.
        sourceContext.delete(task)
        try sourceContext.save()
        try CareRecorder.update(
            correctedEvent,
            completedAt: correctedDate,
            note: "Final corrected history",
            in: sourceContext
        )

        let remainingEvents = try sourceContext.fetch(FetchDescriptor<CareEvent>())
        #expect(remainingEvents.map(\.id) == [correctedEvent.id])
        #expect(try sourceContext.fetch(FetchDescriptor<CareTask>()).isEmpty)

        let data = try JournalArchive.export(
            plants: [plant],
            entries: [],
            careTasks: sourceContext.fetch(FetchDescriptor<CareTask>()),
            careEvents: remainingEvents
        )
        let decoded = try JSONDecoder().decode(JournalArchive.self, from: data)
        #expect(decoded.careTasks?.isEmpty == true)
        #expect(decoded.careEvents?.count == 1)
        #expect(decoded.careEvents?.first?.id == correctedEvent.id)
        #expect(decoded.careEvents?.first?.completedAt == correctedDate)
        #expect(decoded.careEvents?.first?.note == "Final corrected history")
        #expect(decoded.careEvents?.first?.taskID == task.id)
        #expect(decoded.careEvents?.first?.taskTitle == "Watering")
        #expect(decoded.careEvents?.first?.plantID == plant.id)

        let destination = try memory()
        let recoveryContext = ModelContext(destination)
        #expect(try JournalArchive.recover(data, context: recoveryContext) == 0)
        let restoredEvent = try #require(recoveryContext.fetch(FetchDescriptor<CareEvent>()).first)
        #expect(restoredEvent.id == correctedEvent.id)
        #expect(restoredEvent.completedAt == correctedDate)
        #expect(restoredEvent.note == "Final corrected history")
        #expect(restoredEvent.taskID == task.id)
        #expect(restoredEvent.taskTitle == "Watering")
        #expect(restoredEvent.plant?.id == plant.id)
        #expect(try recoveryContext.fetch(FetchDescriptor<CareTask>()).isEmpty)
    }

}
