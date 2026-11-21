import Foundation
import SwiftData

/// User-defined reminders to observe a plant, never horticultural advice.
enum CareKind: String, CaseIterable, Identifiable {
    case watering, feeding, pruning, custom
    var id: String { rawValue }
    var title: String { rawValue.capitalized }
}

enum CareDueState: String { case overdue, due, upcoming }

struct CareSchedule {
    static func nextDate(after date: Date, intervalDays: Int, calendar: Calendar = .current) -> Date {
        calendar.date(byAdding: .day, value: max(1, intervalDays), to: date) ?? date
    }

    static func state(for dueDate: Date, now: Date = .now, calendar: Calendar = .current) -> CareDueState {
        let due = calendar.startOfDay(for: dueDate)
        let today = calendar.startOfDay(for: now)
        if due < today { return .overdue }
        return due == today ? .due : .upcoming
    }
}

@Model
final class CareTask {
    var id: UUID = UUID()
    var kindRaw: String = "watering"
    var customTitle: String = ""
    var intervalDays: Int = 7
    var dueDate: Date = Date.now
    var isEnabled: Bool = true
    var plant: Plant?

    var kind: CareKind { CareKind(rawValue: kindRaw) ?? .custom }
    var title: String { kind == .custom ? customTitle : kind.title }

    init(kind: CareKind, customTitle: String = "", intervalDays: Int, dueDate: Date, plant: Plant) {
        self.kindRaw = kind.rawValue
        self.customTitle = customTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        self.intervalDays = max(1, intervalDays)
        self.dueDate = dueDate
        self.plant = plant
    }
}

@Model
final class CareEvent {
    var id: UUID = UUID()
    var taskID: UUID = UUID()
    var taskTitle: String = ""
    var completedAt: Date = Date.now
    var note: String = ""
    var plant: Plant?

    init(task: CareTask, completedAt: Date = .now, note: String = "") {
        self.taskID = task.id
        self.taskTitle = task.title
        self.completedAt = completedAt
        self.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        self.plant = task.plant
    }
}

@MainActor
enum CareRecorder {
    static func complete(_ task: CareTask, note: String, at date: Date = .now, in context: ModelContext, calendar: Calendar = .current) throws {
        let previousDate = task.dueDate
        let event = CareEvent(task: task, completedAt: date, note: note)
        context.insert(event)
        task.dueDate = CareSchedule.nextDate(after: date, intervalDays: task.intervalDays, calendar: calendar)
        do { try context.save() }
        catch {
            task.dueDate = previousDate
            context.delete(event)
            throw error
        }
    }
}
