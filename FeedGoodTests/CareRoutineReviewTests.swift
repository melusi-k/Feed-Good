import Foundation
import SwiftData
import Testing
@testable import FeedGood

@MainActor
struct CareRoutineReviewTests {
    private func memory() throws -> ModelContainer {
        try ModelContainer(
            for: Schema(versionedSchema: FeedGoodSchemaV6.self),
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    @Test func reviewProjectionIsPlantScopedAndOrderedWithoutMutatingTasks() throws {
        let context = ModelContext(try memory())
        let fern = Plant(name: "Fern")
        let aloe = Plant(name: "Aloe")
        context.insert(fern)
        context.insert(aloe)
        let later = CareTask(kind: .feeding, intervalDays: 14, dueDate: Date(timeIntervalSince1970: 300), plant: fern)
        let earlier = CareTask(kind: .watering, intervalDays: 7, dueDate: Date(timeIntervalSince1970: 100), plant: fern)
        let unrelated = CareTask(kind: .pruning, intervalDays: 30, dueDate: Date(timeIntervalSince1970: 50), plant: aloe)
        context.insert(later)
        context.insert(earlier)
        context.insert(unrelated)
        try context.save()

        let dueDate = earlier.dueDate
        let interval = earlier.intervalDays
        let reviewed = CareRoutineReviewProjection.tasks(for: fern.id, from: [later, unrelated, earlier])

        #expect(reviewed.map(\.id) == [earlier.id, later.id])
        #expect(earlier.dueDate == dueDate)
        #expect(earlier.intervalDays == interval)
        #expect(earlier.isEnabled)
        #expect(earlier.reminderEnabled == false)
    }
}
