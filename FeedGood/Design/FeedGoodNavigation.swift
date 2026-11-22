import SwiftUI
import UIKit

/// Match ate-ios: native large root titles with a leading logo; native inline
/// titles and Back on pushed pages/sheets. Never transform a NavigationStack.
private struct FeedGoodHeader: ViewModifier {
    let title: String
    let tab: AppTab?

    func body(content: Content) -> some View {
        content
            .modifier(FeedGoodTabContentMotion(tab: tab))
            .background {
                // Keep the page canvas opaque while only its contents fade.
                // Otherwise a tab change exposes NavigationStack's white host.
                if tab != nil { FeedGoodTheme.background.ignoresSafeArea() }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(tab == nil ? .inline : .large)
            .toolbar {
                if tab != nil {
                    ToolbarItem(placement: .topBarLeading) {
                        Image(systemName: "leaf.fill")
                            .font(.system(size: 25, weight: .semibold))
                            .foregroundStyle(FeedGoodTheme.leaf)
                            .frame(width: 28, height: 28)
                            .accessibilityLabel("Feed Good")
                            .accessibilityIdentifier("app.header.logo")
                    }
                }
            }
    }
}

/// Shared UIKit appearance, as in ate-ios. Native bars own large-title collapse,
/// pinned inline titles, toolbar layout and selected/unselected tab treatment.
enum FeedGoodNavigationAppearance {
    static func apply() {
        let nav = UINavigationBarAppearance()
        nav.configureWithDefaultBackground()
        let serif = { (size: CGFloat) -> UIFont in
            let base = UIFont.systemFont(ofSize: size, weight: .bold)
            return base.fontDescriptor.withDesign(.serif).map { UIFont(descriptor: $0, size: size) } ?? base
        }
        nav.largeTitleTextAttributes = [.font: UIFontMetrics(forTextStyle: .largeTitle).scaledFont(for: serif(32))]
        nav.titleTextAttributes = [.font: UIFontMetrics(forTextStyle: .headline).scaledFont(for: serif(18))]
        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().compactAppearance = nav
        UINavigationBar.appearance().tintColor = UIColor(FeedGoodTheme.leaf)
        let bar = UITabBarAppearance()
        bar.configureWithDefaultBackground()
        for layout in [bar.stackedLayoutAppearance, bar.inlineLayoutAppearance, bar.compactInlineLayoutAppearance] {
            layout.selected.iconColor = UIColor(FeedGoodTheme.leaf)
            layout.selected.titleTextAttributes = [.foregroundColor: UIColor(FeedGoodTheme.leaf), .font: UIFont.systemFont(ofSize: 10, weight: .semibold)]
            layout.normal.iconColor = UIColor.secondaryLabel
            layout.normal.titleTextAttributes = [.foregroundColor: UIColor.secondaryLabel, .font: UIFont.systemFont(ofSize: 10, weight: .medium)]
        }
        UITabBar.appearance().standardAppearance = bar
        UITabBar.appearance().scrollEdgeAppearance = bar
        UITabBar.appearance().unselectedItemTintColor = .secondaryLabel
    }
}

/// Restrained motion for collection inserts/removals/reordering, not a blanket
/// animation on the whole view tree. Search, typing and scroll remain native.
struct FeedGoodMotionPolicy: Equatable {
    let reduceMotion: Bool
    var duration: Double { reduceMotion ? 0 : 0.2 }
    var animation: Animation? { reduceMotion ? nil : .easeInOut(duration: duration) }
}

private struct FeedGoodCollectionMotion<Value: Equatable>: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let value: Value

    func body(content: Content) -> some View {
        content.animation(FeedGoodMotionPolicy(reduceMotion: reduceMotion).animation, value: value)
    }
}

/// Covers app-driven transactions, including native route/sheet state changes.
/// The OS remains responsible for its own accessibility-aware transitions.
struct FeedGoodMotionAccessibility: ViewModifier {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func body(content: Content) -> some View {
        content.transaction { transaction in
            if reduceMotion {
                transaction.animation = nil
                transaction.disablesAnimations = true
            }
        }
    }
}

extension View {
    func feedGoodHeader(_ title: String, tab: AppTab? = nil) -> some View { modifier(FeedGoodHeader(title: title, tab: tab)) }
    func feedGoodCollectionMotion<Value: Equatable>(value: Value) -> some View {
        modifier(FeedGoodCollectionMotion(value: value))
    }
}

/// Tap feedback is local to the pressed control, never the surrounding page.
struct FeedGoodPressStyle: ButtonStyle {
    enum Surface { case plain, bordered, prominent }
    var surface: Surface = .plain
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    func makeBody(configuration: Configuration) -> some View {
        let color: Color = configuration.role == .destructive ? .red : FeedGoodTheme.leaf
        return configuration.label
            .padding(.horizontal, surface == .plain ? 0 : 12)
            .padding(.vertical, surface == .plain ? 0 : 8)
            .foregroundStyle(surface == .prominent ? FeedGoodTheme.primaryForeground : color)
            .background {
                if surface != .plain {
                    RoundedRectangle(cornerRadius: 10).fill(color.opacity(surface == .prominent ? 1 : 0.08))
                }
            }
            .overlay {
                if surface == .bordered { RoundedRectangle(cornerRadius: 10).stroke(color.opacity(0.35)) }
            }
            .contentShape(Rectangle())
            .opacity(configuration.isPressed ? 0.75 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
