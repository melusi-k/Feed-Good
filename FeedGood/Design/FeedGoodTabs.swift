import SwiftUI
import UIKit

/// Keep the native TabView responsible for tab visibility, selection/reselection,
/// accessibility and each tab's navigation state. Motion is inside each root.
struct FeedGoodTabs: View {
    @Binding var selection: AppTab
    @Binding var appearanceRawValue: String
    @State private var previous: AppTab = .today

    var body: some View {
        TabView(selection: $selection) {
            page(.today) { TodayView(selectedTab: $selection) }
            page(.plants) { PlantListView() }
            page(.journal) { NavigationStack { JournalView() } }
            page(.settings) { SettingsView(appearanceRawValue: $appearanceRawValue) }
        }
        .tabViewStyle(.tabBarOnly)
        .environment(\.feedGoodTabMotion, FeedGoodTabMotionContext(selection: selection, direction: selection.order < previous.order ? -1 : 1))
        .onChange(of: selection) { old, _ in previous = old }
    }

    private func page<Content: View>(_ tab: AppTab, @ViewBuilder content: () -> Content) -> some View {
        content()
            .background(FeedGoodTabSwipe(selection: $selection, tab: tab))
            .tabItem { Label(tab.title, systemImage: tab.symbol) }
            .tag(tab)
    }
}

fileprivate struct FeedGoodTabMotionContext {
    var selection: AppTab = .today
    var direction: CGFloat = 1
}
fileprivate struct FeedGoodTabMotionKey: EnvironmentKey {
    static let defaultValue = FeedGoodTabMotionContext()
}
extension EnvironmentValues {
    fileprivate var feedGoodTabMotion: FeedGoodTabMotionContext {
        get { self[FeedGoodTabMotionKey.self] }
        set { self[FeedGoodTabMotionKey.self] = newValue }
    }
}

/// Only the screen content moves, inside its NavigationStack. Native bars and
/// toolbars never inherit this transform. Native push/pop is left untouched.
struct FeedGoodTabContentMotion: ViewModifier {
    let tab: AppTab?
    @Environment(\.feedGoodTabMotion) private var context
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(tab == nil || shown ? 1 : 0)
            .offset(x: tab == nil || reduceMotion || shown ? 0 : context.direction * 14)
            .onAppear {
                withAnimation(tab == nil ? nil : FeedGoodMotionPolicy(reduceMotion: reduceMotion).animation) { shown = true }
            }
            .onChange(of: context.selection) { _, selected in
                // A push in this tab must not reset root content, otherwise the
                // native Back transition would receive a second entrance effect.
                if let tab, selected != tab { shown = false }
            }
    }
}

/// Observe a horizontal swipe without cancelling the touched view's events.
/// Edges stay reserved for navigation, horizontal scrollers and editing controls
/// keep their gestures, and sheets/VoiceOver retain system gesture ownership.
private struct FeedGoodTabSwipe: UIViewRepresentable {
    @Binding var selection: AppTab
    let tab: AppTab

    func makeCoordinator() -> Coordinator { Coordinator(selection: $selection, tab: tab) }
    func makeUIView(context: Context) -> Probe {
        let view = Probe()
        view.install = { [weak coordinator = context.coordinator] view in coordinator?.install(from: view) }
        return view
    }
    func updateUIView(_ view: Probe, context: Context) {
        context.coordinator.selection = $selection
        context.coordinator.install(from: view)
    }
    static func dismantleUIView(_ view: Probe, coordinator: Coordinator) { coordinator.remove() }

    final class Probe: UIView {
        var install: ((UIView) -> Void)?
        override func didMoveToWindow() { super.didMoveToWindow(); install?(self) }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var selection: Binding<AppTab>
        let tab: AppTab
        private weak var target: UIView?
        private var recognizers: [UISwipeGestureRecognizer] = []
        init(selection: Binding<AppTab>, tab: AppTab) { self.selection = selection; self.tab = tab }

        func install(from view: UIView) {
            guard view.window != nil else { return }
            var responder: UIResponder? = view
            while let current = responder, !(current is UIViewController) { responder = current.next }
            guard let host = (responder as? UIViewController)?.view, host !== target else { return }
            remove()
            target = host
            for direction in [UISwipeGestureRecognizer.Direction.left, .right] {
                let gesture = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
                gesture.direction = direction
                gesture.cancelsTouchesInView = false
                gesture.delegate = self
                host.addGestureRecognizer(gesture)
                recognizers.append(gesture)
            }
        }
        func remove() {
            for gesture in recognizers { target?.removeGestureRecognizer(gesture) }
            recognizers = []
            target = nil
        }
        @objc private func swiped(_ gesture: UISwipeGestureRecognizer) {
            guard selection.wrappedValue == tab else { return }
            let next = tab.order + (gesture.direction == .left ? 1 : -1)
            if let destination = AppTab(rawValue: next) { selection.wrappedValue = destination }
        }
        func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
            guard selection.wrappedValue == tab, !UIAccessibility.isVoiceOverRunning,
                  let window = target?.window else { return false }
            let x = touch.location(in: window).x
            guard x > 44, x < window.bounds.width - 44 else { return false }
            if window.rootViewController?.presentedViewController != nil { return false }
            var ancestor = touch.view
            while let view = ancestor {
                if view is UIControl || view is UITextField || view is UITextView { return false }
                if let scroll = view as? UIScrollView, scroll.contentSize.width > scroll.bounds.width + 1 { return false }
                ancestor = view.superview
            }
            return true
        }
        func gestureRecognizer(_ gesture: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith other: UIGestureRecognizer) -> Bool { true }
    }
}
