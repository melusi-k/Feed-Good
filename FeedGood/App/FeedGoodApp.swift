import SwiftUI
import SwiftData

@main
struct FeedGoodApp: App {
    var body: some Scene {
        WindowGroup {
            PlantListView()
        }
        .modelContainer(for: Plant.self)
    }
}
