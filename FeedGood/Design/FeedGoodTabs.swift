import SwiftUI
import UIKit

/// The native tab bar remains a single persistent control. Each navigation stack
/// stays mounted, so a tab switch does not recreate its path or scroll state.
struct FeedGoodTabs: View {
    @Binding var selection: AppTab
    @Binding var appearanceRawValue: String
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            page(.today) { TodayView(selectedTab: $selection) }
            page(.plants) { PlantListView() }
            page(.journal) { NavigationStack { JournalView() } }
            page(.settings) { SettingsView(appearanceRawValue: $appearanceRawValue) }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            FeedGoodTabBar(selection: $selection)
                .frame(height: 49)
                .background(FeedGoodTheme.surface.ignoresSafeArea(edges: .bottom))
        }
    }

    private func page<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let active = selection == tab
        return content()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .opacity(active ? 1 : 0)
            .offset(x: reduceMotion || active ? 0 : (tab.order < selection.order ? -14 : 14))
            .allowsHitTesting(active)
            .accessibilityHidden(!active)
            .zIndex(active ? 1 : 0)
            .animation(FeedGoodMotionPolicy(reduceMotion: reduceMotion).animation, value: selection)
    }
}

private struct FeedGoodTabBar: UIViewRepresentable {
    @Binding var selection: AppTab

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection) }

    func makeUIView(context: Context) -> UITabBar {
        let bar = UITabBar()
        let appearance = UITabBarAppearance()
        appearance.configureWithDefaultBackground()
        bar.standardAppearance = appearance
        bar.scrollEdgeAppearance = appearance
        bar.items = AppTab.allCases.map { tab in
            let item = UITabBarItem(title: tab.title, image: UIImage(systemName: tab.symbol), tag: tab.order)
            item.selectedImage = UIImage(systemName: tab.selectedSymbol)
            return item
        }
        bar.delegate = context.coordinator
        bar.isTranslucent = false
        return bar
    }

    func updateUIView(_ bar: UITabBar, context: Context) {
        context.coordinator.selection = $selection
        bar.tintColor = UIColor(FeedGoodTheme.leaf)
        bar.selectedItem = bar.items?.first { $0.tag == selection.order }
    }

    final class Coordinator: NSObject, UITabBarDelegate {
        var selection: Binding<AppTab>
        init(selection: Binding<AppTab>) { self.selection = selection }
        func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
            guard let tab = AppTab.allCases.first(where: { $0.order == item.tag }) else { return }
            selection.wrappedValue = tab
        }
    }
}
