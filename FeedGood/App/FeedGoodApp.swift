import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    @StateObject private var reminderScheduler = CareReminderScheduler(boundary: LocalCareNotifications())
    /// UI tests run against an in-memory store so journeys are deterministic
    /// and never touch the on-device garden.
    private var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("FEEDGOOD_UI_TESTING")
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .modifier(CareRemindersLifecycle())
                .environmentObject(reminderScheduler)
        }
        .modelContainer(for: [Plant.self, CareTask.self, CareEvent.self], inMemory: isUITesting)
    }
}
