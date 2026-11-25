import Foundation

/// A value snapshot of one recorded care event. It deliberately contains no
/// schedule/opportunity inference and no editable source-model reference.
struct PlantCareActivityRecord: Identifiable, Equatable {
    let id: UUID
    let taskID: UUID
    let taskTitle: String
    let completedAt: Date

    @MainActor
    init(event: CareEvent) {
        id = event.id
        taskID = event.taskID
        taskTitle = event.taskTitle
        completedAt = event.completedAt
    }
}
