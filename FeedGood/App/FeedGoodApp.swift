import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    @UIApplicationDelegateAdaptor(FeedGoodAppDelegate.self) private var appDelegate
    @StateObject private var reminderScheduler = CareReminderScheduler(boundary: LocalCareNotifications())
    @StateObject private var notificationRouter = CareNotificationRouter.shared
    private let modelContainer: ModelContainer

    init() {
        FeedGoodNavigationAppearance.apply()
        let schema = Schema(versionedSchema: FeedGoodSchemaV5.self)
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: ProcessInfo.processInfo.arguments.contains("FEEDGOOD_UI_TESTING")
        )
        do {
            modelContainer = try ModelContainer(
                for: schema,
                migrationPlan: FeedGoodMigrationPlan.self,
                configurations: [configuration]
            )
        } catch {
            fatalError("Feed Good could not open its garden data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppTabView()
                .modifier(CareRemindersLifecycle())
                .environmentObject(reminderScheduler)
                .environmentObject(notificationRouter)
        }
        .modelContainer(modelContainer)
    }
}
