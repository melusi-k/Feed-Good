import Foundation
import UserNotifications
import SwiftUI
import SwiftData

struct CareReminder: Equatable {
    let id: String
    let title: String
    let body: String
    let date: Date
    let taskID: UUID?
    let plantID: UUID?

    init(id: String, title: String, body: String, date: Date, taskID: UUID? = nil, plantID: UUID? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.date = date
        self.taskID = taskID
        self.plantID = plantID
    }
}

enum CareNotificationPayload {
    static let taskIDKey = "feedgood.care.task-id"
    static let plantIDKey = "feedgood.care.plant-id"

    static func make(taskID: UUID, plantID: UUID) -> [AnyHashable: Any] {
        [taskIDKey: taskID.uuidString, plantIDKey: plantID.uuidString]
    }

    static func destination(from userInfo: [AnyHashable: Any]) -> (taskID: UUID, plantID: UUID)? {
        guard let taskValue = userInfo[taskIDKey] as? String,
              let plantValue = userInfo[plantIDKey] as? String,
              let taskID = UUID(uuidString: taskValue),
              let plantID = UUID(uuidString: plantValue) else { return nil }
        return (taskID, plantID)
    }
}

enum ReminderPermission { case notDetermined, allowed, denied }

enum CareNotificationTrigger {
    static func dateComponents(for date: Date, timeZone: TimeZone) -> DateComponents {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        components.timeZone = timeZone
        return components
    }
}

@MainActor
protocol CareNotificationBoundary {
    func permission() async -> ReminderPermission
    func requestPermission() async throws -> Bool
    func pendingIDs() async -> [String]
    func remove(_ ids: [String])
    func add(_ reminder: CareReminder) async throws
}

@MainActor
final class LocalCareNotifications: CareNotificationBoundary {
    private let center = UNUserNotificationCenter.current()
    func permission() async -> ReminderPermission {
        switch await center.notificationSettings().authorizationStatus {
        case .authorized, .provisional, .ephemeral: return .allowed
        case .denied: return .denied
        default: return .notDetermined
        }
    }
    func requestPermission() async throws -> Bool {
        try await center.requestAuthorization(options: [.alert, .sound])
    }
    func pendingIDs() async -> [String] { await center.pendingNotificationRequests().map(\.identifier) }
    func remove(_ ids: [String]) { center.removePendingNotificationRequests(withIdentifiers: ids) }
    func add(_ reminder: CareReminder) async throws {
        let content = UNMutableNotificationContent()
        content.title = reminder.title
        content.body = reminder.body
        content.sound = .default
        if let taskID = reminder.taskID, let plantID = reminder.plantID {
            content.userInfo = CareNotificationPayload.make(taskID: taskID, plantID: plantID)
        }
        let components = CareNotificationTrigger.dateComponents(for: reminder.date, timeZone: .current)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: reminder.id, content: content, trigger: trigger))
    }
}

/// Serialized reconciliations prevent an older asynchronous add from undoing a newer cancellation.
@MainActor
final class CareReminderScheduler: ObservableObject {
    static let prefix = "feedgood.care."
    @Published var message = "Reminders are optional. Care tracking always works without them."
    private let boundary: CareNotificationBoundary
    private var previous: Task<Void, Never>?

    init(boundary: CareNotificationBoundary) { self.boundary = boundary }

    func requestPermission() async {
        do { _ = try await boundary.requestPermission() }
        catch { message = "Couldn't ask for notification permission. Care tracking still works. Try enabling a reminder again." }
    }

    static func reminders(for tasks: [CareTask], now: Date = .now) -> [CareReminder] {
        tasks.filter { task in
            task.isEnabled &&
            task.reminderEnabled &&
            task.plant != nil &&
            task.plant?.archivedAt == nil &&
            task.dueDate > now &&
            !((task.plant?.quietPeriods ?? []).contains { period in
                period.statusRaw == QuietPeriodStatus.active.rawValue &&
                (period.taskSnapshots ?? []).contains { snapshot in
                    snapshot.taskID == task.id &&
                    snapshot.membershipStatusRaw == QuietPeriodMembershipStatus.active.rawValue
                }
            })
        }
            .sorted { $0.dueDate == $1.dueDate ? $0.id.uuidString < $1.id.uuidString : $0.dueDate < $1.dueDate }
            .map {
                CareReminder(id: prefix + $0.id.uuidString, title: "A moment with \($0.plant!.name)", body: "\($0.title): check what your plant needs before following your own routine.", date: $0.dueDate, taskID: $0.id, plantID: $0.plant!.id)
            }
    }

    func reconcile(_ reminders: [CareReminder]) async {
        let preceding = previous
        let work = Task { @MainActor [weak self] in
            await preceding?.value
            guard let self else { return }
            let pending = await boundary.pendingIDs()
            let ours = pending.filter { $0.hasPrefix(Self.prefix) }
            boundary.remove(ours)
            switch await boundary.permission() {
            case .notDetermined:
                message = "Enable a reminder on a task to choose notification permission. Care tracking works without it."
            case .denied:
                message = "Notifications are off in iPhone Settings. Your routines and care history still work."
            case .allowed:
                if reminders.isEmpty {
                    message = "Notifications are allowed. Enable a reminder on a care task if you'd like an alert."
                    return
                }
                // iOS permits 64 pending notifications per app. Preserve any non-care requests.
                let capacity = max(0, 64 - (pending.count - ours.count))
                var failed = false
                for reminder in reminders.prefix(capacity) {
                    do { try await boundary.add(reminder) }
                    catch { failed = true }
                }
                if failed { message = "Some reminders couldn't be scheduled. Care tracking is saved. Reopen the app to try again." }
                else if reminders.count > capacity { message = "Only the next \(capacity) reminders fit on this iPhone. Reopen the app after they arrive to schedule the rest." }
                else { message = "Future reminders are scheduled. Overdue tasks stay in Care routine, without repeated alerts." }
            }
        }
        previous = work
        await work.value
    }
}

struct CareRemindersLifecycle: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var context
    @EnvironmentObject private var scheduler: CareReminderScheduler
    @Query private var tasks: [CareTask]
    @Query private var plants: [Plant]

    private var nextQuietPeriodTransition: Date? {
        plants.flatMap { $0.quietPeriods ?? [] }.compactMap { period -> Date? in
            switch period.statusRaw {
            case QuietPeriodStatus.scheduled.rawValue:
                return period.startAt > .now ? period.startAt : nil
            case QuietPeriodStatus.active.rawValue:
                guard let endAt = period.endAt, endAt > .now else { return nil }
                return endAt
            default:
                return nil
            }
        }.min()
    }

    private var revision: String {
        let taskState = tasks.sorted { $0.id.uuidString < $1.id.uuidString }.map {
            "\($0.id)|\($0.dueDate.timeIntervalSince1970)|\($0.isEnabled)|\($0.reminderEnabled)|\($0.title)"
        }.joined(separator: ";")
        let plantState = plants.sorted { $0.id.uuidString < $1.id.uuidString }.map {
            let quietState = ($0.quietPeriods ?? []).sorted { $0.id.uuidString < $1.id.uuidString }.map { period in
                let members = (period.taskSnapshots ?? []).sorted { $0.taskID.uuidString < $1.taskID.uuidString }.map {
                    "\($0.taskID)|\($0.membershipStatusRaw)"
                }.joined(separator: ",")
                return "\(period.id)|\(period.statusRaw)|\(period.startAt.timeIntervalSince1970)|\(period.endAt?.timeIntervalSince1970 ?? 0)|\(members)"
            }.joined(separator: ";")
            return "\($0.id)|\($0.name)|\($0.archivedAt?.timeIntervalSince1970 ?? 0)|\(quietState)"
        }.joined(separator: ";")
        return taskState + "#" + plantState
    }

    func body(content: Content) -> some View {
        content
            .task(id: revision) {
                do { try QuietPeriodLifecycle.advanceAll(in: context) }
                catch { /* Keep care reminders available; the next foreground pass retries lifecycle catch-up. */ }
                await scheduler.reconcile(CareReminderScheduler.reminders(for: tasks))
            }
            .task(id: nextQuietPeriodTransition) {
                guard let transition = nextQuietPeriodTransition else { return }
                let delay = max(0, transition.timeIntervalSinceNow)
                do { try await Task.sleep(for: .seconds(delay)) }
                catch { return }
                guard !Task.isCancelled else { return }
                do { try QuietPeriodLifecycle.advanceAll(in: context) }
                catch { /* Foreground and next-transition passes retry lifecycle catch-up. */ }
                await scheduler.reconcile(CareReminderScheduler.reminders(for: tasks))
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    Task {
                        do { try QuietPeriodLifecycle.advanceAll(in: context) }
                        catch { /* The next foreground pass retries lifecycle catch-up. */ }
                        await scheduler.reconcile(CareReminderScheduler.reminders(for: tasks))
                    }
                }
            }
    }
}
