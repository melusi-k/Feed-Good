import SwiftUI

private struct FeedGoodProfileActionKey: EnvironmentKey {
    static let defaultValue: () -> Void = {}
}

extension EnvironmentValues {
    var showFeedGoodProfile: () -> Void {
        get { self[FeedGoodProfileActionKey.self] }
        set { self[FeedGoodProfileActionKey.self] = newValue }
    }
}

/// Every tab uses this action. AppTabView owns the single sheet presentation.
struct FeedGoodProfileButton: View {
    @Environment(\.showFeedGoodProfile) private var showProfile

    var body: some View {
        Button(action: showProfile) {
            Label("Profile", systemImage: "person.crop.circle")
        }
        .accessibilityIdentifier("profile.open")
    }
}
