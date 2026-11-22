import SwiftUI

/// One header treatment for app-owned pages and sheets. Native controls remain
/// in their own toolbar slots; inline titles do not scroll away with content.
private struct FeedGoodHeader: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(FeedGoodTheme.surface, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(alignment: .center, spacing: 7) {
                        Image(systemName: "leaf.fill")
                            .foregroundStyle(FeedGoodTheme.leaf)
                            .accessibilityHidden(true)
                        Text(title)
                            .font(.headline)
                            .lineLimit(1)
                            .truncationMode(.tail)
                            .accessibilityAddTraits(.isHeader)
                            .accessibilityIdentifier("app.header.title")
                    }
                    .foregroundStyle(FeedGoodTheme.soil)
                }
            }
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
    func feedGoodHeader(_ title: String) -> some View { modifier(FeedGoodHeader(title: title)) }
    func feedGoodCollectionMotion<Value: Equatable>(value: Value) -> some View {
        modifier(FeedGoodCollectionMotion(value: value))
    }
}
