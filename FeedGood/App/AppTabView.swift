import SwiftUI

enum AppTab: Hashable {
    case today
    case plants
    case journal
    case settings
}

struct AppTabView: View {
    @AppStorage("feedGood.appearance") private var appearanceRawValue = FeedGoodAppearance.system.rawValue
    @State private var selectedTab: AppTab = .today

    private var appearance: FeedGoodAppearance {
        FeedGoodAppearance(rawValue: appearanceRawValue) ?? .system
    }

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

            NavigationStack { JournalView() }
                .tabItem {
                    Label("Journal", systemImage: selectedTab == .journal ? "book.closed.fill" : "book.closed")
                }
                .tag(AppTab.journal)

            SettingsView(appearanceRawValue: $appearanceRawValue)
                .tabItem {
                    Label("Settings", systemImage: selectedTab == .settings ? "slider.horizontal.3" : "slider.horizontal.3")
                }
                .tag(AppTab.settings)
        }
        .tint(FeedGoodTheme.leaf)
        .preferredColorScheme(appearance.preferredColorScheme)
    }
}

private struct SettingsView: View {
    @Binding var appearanceRawValue: String

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

                JournalArchiveSection()

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
            }
            .scrollContentBackground(.hidden)
            .background(FeedGoodTheme.background)
            .navigationTitle("Settings")
        }
        .tint(FeedGoodTheme.leaf)
    }
}
