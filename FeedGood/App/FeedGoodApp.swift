import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    @UIApplicationDelegateAdaptor(FeedGoodAppDelegate.self) private var appDelegate
    @StateObject private var reminderScheduler: CareReminderScheduler
    @StateObject private var notificationRouter = CareNotificationRouter.shared
    private let modelContainer: ModelContainer
    private let launchStateStore: AppLaunchStateStore

    init() {
        FeedGoodNavigationAppearance.apply()
        let schema = Schema(versionedSchema: FeedGoodSchemaV7.self)
        let isUITesting = ProcessInfo.processInfo.arguments.contains("FEEDGOOD_UI_TESTING")
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isUITesting
        )
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "0"
        let versionIdentity = "\(version) (\(build))"
        let defaults = UserDefaults.standard
        let launchStateStore = AppLaunchStateStore(
            defaults: defaults,
            hasExistingPersistentStore: isUITesting ? false : FileManager.default.fileExists(atPath: configuration.url.path)
        )
        let notificationBoundary: CareNotificationBoundary = isUITesting ? UITestCareNotifications() : LocalCareNotifications()
        _reminderScheduler = StateObject(wrappedValue: CareReminderScheduler(boundary: notificationBoundary))
        if isUITesting {
            defaults.removeObject(forKey: AppLaunchStateStore.onboardingCompletedKey)
            defaults.removeObject(forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey)
            let arguments = ProcessInfo.processInfo.arguments
            defaults.set(arguments.contains("FEEDGOOD_ONBOARDING_RESET") == false, forKey: AppLaunchStateStore.onboardingCompletedKey)
            if let index = arguments.firstIndex(of: "FEEDGOOD_WHATS_NEW_LAST_SEEN"), index + 1 < arguments.count {
                defaults.set(arguments[index + 1], forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey)
            } else {
                defaults.set(versionIdentity, forKey: AppLaunchStateStore.whatsNewLastSeenVersionKey)
            }
        } else {
            launchStateStore.bootstrap(versionIdentity: versionIdentity)
        }
        self.launchStateStore = launchStateStore
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
            AppTabView(launchStateStore: launchStateStore)
                .modifier(CareRemindersLifecycle())
                .environmentObject(reminderScheduler)
                .environmentObject(notificationRouter)
        }
        .modelContainer(modelContainer)
    }
}
