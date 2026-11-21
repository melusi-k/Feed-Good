import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    var body: some Scene {
        WindowGroup {
            AppTabView()
        }
        .modelContainer(for: Plant.self)
    }
}
