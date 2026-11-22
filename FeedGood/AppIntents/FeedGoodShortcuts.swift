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

/// Exposes the app's primary, useful entry point to Siri and the Shortcuts app.
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
