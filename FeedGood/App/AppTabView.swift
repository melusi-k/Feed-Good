import SwiftUI

enum AppTab: Hashable {
    case today
    case plants
    case journal
}

struct AppTabView: View {
    @State private var selectedTab: AppTab = .today

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView(selectedTab: $selectedTab)
                .tabItem {
                    Label("Today", systemImage: selectedTab == .today ? "sun.max.fill" : "sun.max")
                }
                .tag(AppTab.today)

            PlantListView()
                .tabItem {
                    Label("My Plants", systemImage: selectedTab == .plants ? "leaf.fill" : "leaf")
                }
                .tag(AppTab.plants)

            JournalView()
                .tabItem {
                    Label("Journal", systemImage: selectedTab == .journal ? "book.closed.fill" : "book.closed")
                }
                .tag(AppTab.journal)
        }
        .tint(FeedGoodTheme.leaf)
    }
}

private struct JournalView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView {
                Label("Your garden story starts here", systemImage: "book.closed")
            } description: {
                Text("Soon, you’ll be able to keep the little moments, new leaves and milestones that make each plant yours.")
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FeedGoodTheme.background)
            .navigationTitle("Journal")
        }
        .tint(FeedGoodTheme.leaf)
    }
}
