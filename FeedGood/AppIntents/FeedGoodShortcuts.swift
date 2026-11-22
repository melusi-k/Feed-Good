import AppIntents

/// Opens Feed Good directly to its Today screen, where the user's next care moments live.
struct OpenTodayIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today's Care"
    static let description = IntentDescription("Open Feed Good to see the plants and care tasks that need your attention.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        .result()
    }
}

/// Publishes the app's primary Today entry point as a concise Siri and Shortcuts action.
struct FeedGoodShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodayIntent(),
            phrases: [
                "Show today's plant care in \(.applicationName)",
                "Open today's care in \(.applicationName)"
            ],
            shortTitle: "Today's care",
            systemImageName: "leaf"
        )
    }
}
