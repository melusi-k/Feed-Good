import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    var body: some Scene {
        WindowGroup {
            AppTabView()
                .preferredColorScheme(FeedGoodAppearance.system.preferredColorScheme)
        }
        .modelContainer(for: Plant.self)
    }
}
