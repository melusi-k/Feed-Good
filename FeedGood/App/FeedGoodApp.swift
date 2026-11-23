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
        let schema = Schema(versionedSchema: FeedGoodSchemaV2.self)
        let isUITesting = ProcessInfo.processInfo.arguments.contains("FEEDGOOD_UI_TESTING")
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )
        if isUITesting == false {
            let hasExistingPersistentStore = FileManager.default.fileExists(atPath: configuration.url.path)
            let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
            let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
            AppLaunchStateStore(
                defaults: .standard,
                hasExistingPersistentStore: hasExistingPersistentStore
            )
            .bootstrap(versionIdentity: "\\(version) (\\(build))")
        }
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
