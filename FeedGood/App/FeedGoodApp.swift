import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    @UIApplicationDelegateAdaptor(FeedGoodAppDelegate.self) private var appDelegate
    @StateObject private var reminderScheduler = CareReminderScheduler(boundary: LocalCareNotifications())
    @StateObject private var notificationRouter = CareNotificationRouter.shared
    /// UI tests run against an in-memory store so journeys are deterministic
    /// and never touch the on-device garden.
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("FEEDGOOD_UI_TESTING")
    }

    init() { FeedGoodNavigationAppearance.apply() }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .modifier(CareRemindersLifecycle())
                .environmentObject(reminderScheduler)
                .environmentObject(notificationRouter)
        }
        .modelContainer(for: [Plant.self, CareTask.self, CareEvent.self, JournalEntry.self], inMemory: isUITesting)
    }
}
