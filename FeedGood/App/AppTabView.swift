import SwiftUI
import UIKit

enum AppTab: Int, Hashable, CaseIterable {
    case today
    case plants
    case journal
    case settings

    var order: Int { rawValue }
    var title: String {
        switch self {
        case .today: "Today"
        case .plants: "My Plants"
        case .journal: "Journal"
        case .settings: "Settings"
        }
    }
    var symbol: String {
        switch self {
        case .today: "sun.max"
        case .plants: "leaf"
        case .journal: "book.closed"
        case .settings: "slider.horizontal.3"
        }
    }
    var selectedSymbol: String {
        switch self {
        case .today: "sun.max.fill"
        case .plants: "leaf.fill"
        case .journal: "book.closed.fill"
        case .settings: symbol
        }
    }
}

struct AppTabView: View {
    @AppStorage("feedGood.appearance") private var appearanceRawValue = FeedGoodAppearance.system.rawValue
    @State private var selectedTab: AppTab = .today
    @State private var showingProfile = false
    @State private var whatsNewEntry: ReleaseNotesEntry?
    @State private var whatsNewChecked = false

    private var appearance: FeedGoodAppearance {
        FeedGoodAppearance(rawValue: appearanceRawValue) ?? .system
    }

    var body: some View {
        FeedGoodTabs(selection: $selectedTab, appearanceRawValue: $appearanceRawValue)
        .buttonStyle(FeedGoodPressStyle())
        .modifier(FeedGoodMotionAccessibility())
        .tint(FeedGoodTheme.leaf)
        .preferredColorScheme(appearance.preferredColorScheme)
        .environment(\.showFeedGoodProfile, { showingProfile = true })
        .onAppear {
            guard whatsNewChecked == false else { return }
            whatsNewChecked = true
            whatsNewEntry = AppTabView.makeWhatsNewStore().entryToPresent()
        }
        .sheet(item: $whatsNewEntry, onDismiss: {
            AppTabView.makeWhatsNewStore().markCurrentVersionSeen()
        }) { entry in
            WhatsNewView(entry: entry) {
                AppTabView.makeWhatsNewStore().markCurrentVersionSeen()
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView {
                showingProfile = false
                selectedTab = .settings
            }
        }
    }
    /// Builds the What's New gate, honoring UI-test launch arguments that seed
    /// the last-seen version (`FEEDGOOD_WHATS_NEW_LAST_SEEN <identity>`) or
    /// simulate a fresh install (`FEEDGOOD_WHATS_NEW_FRESH_INSTALL`).
    static func makeWhatsNewStore() -> WhatsNewStore {
        let arguments = ProcessInfo.processInfo.arguments
        if let index = arguments.firstIndex(of: "FEEDGOOD_WHATS_NEW_LAST_SEEN"), index + 1 < arguments.count {
            return WhatsNewStore(lastSeen: arguments[index + 1])
        }
        if arguments.contains("FEEDGOOD_WHATS_NEW_FRESH_INSTALL") {
            return WhatsNewStore(lastSeen: nil)
        }
        return WhatsNewStore()
    }
}

struct SettingsView: View {
    @Binding var appearanceRawValue: String
    @EnvironmentObject private var reminderScheduler: CareReminderScheduler
    @Environment(\.openURL) private var openURL

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Not available"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Not available"
    }

    private var appearance: FeedGoodAppearance {
        FeedGoodAppearance(rawValue: appearanceRawValue) ?? .system
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Appearance", selection: $appearanceRawValue) {
                        ForEach(FeedGoodAppearance.allCases) { option in
                            Text(option.title).tag(option.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityIdentifier("settings.appearance")
                } header: {
                    Text("Appearance")
                } footer: {
                    Text("Choose the look that feels right. System follows your iPhone setting.")
                }

                Section {
                    HStack(spacing: 12) {
                        Image(systemName: appearance == .dark ? "moon.stars.fill" : "sun.max.fill")
                            .foregroundStyle(FeedGoodTheme.leaf)
                            .frame(width: 32)
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(appearance.title) appearance")
                                .font(.body.weight(.medium))
                            Text("Your preference is saved on this device.")
                                .font(.caption)
                                .foregroundStyle(FeedGoodTheme.muted)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section("Privacy & data") {
                    Text("Your plants, care routines and journal are stored on this device. Feed Good does not require an account or upload your garden to a service. If you export an archive, the file contains private plant details and photos; choose a secure place to keep it.")
                        .font(.callout)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .accessibilityIdentifier("settings.privacy")
                }

                JournalArchiveSection()

                Section("Notifications") {
                    Text(reminderScheduler.message)
                        .font(.callout)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .accessibilityIdentifier("settings.notificationStatus")
                    Button("Manage Feed Good notifications") {
                        if let url = URL(string: UIApplication.openSettingsURLString) {
                            openURL(url)
                        }
                    }
                    .accessibilityIdentifier("settings.notificationSettings")
                }

                Section("About") {
                    LabeledContent("Version", value: appVersion)
                    LabeledContent("Build", value: buildNumber)
                }

            }
            .scrollContentBackground(.hidden)
            .background(FeedGoodTheme.background)
            .feedGoodHeader("Settings", tab: .settings)
        }
        .tint(FeedGoodTheme.leaf)
    }
}
