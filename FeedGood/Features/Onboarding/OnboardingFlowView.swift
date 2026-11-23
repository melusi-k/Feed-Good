import SwiftUI

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case welcome
    case howItWorks
    case getStarted

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .welcome: "Welcome to Feed Good"
        case .howItWorks: "How it works"
        case .getStarted: "Let's grow."
        }
    }

    var subtitle: String {
        switch self {
        case .welcome: "Care for your plants, one day at a time."
        case .howItWorks: "Three tabs, one garden."
        case .getStarted: "Start with one plant, or look around first."
        }
    }

    var highlights: [OnboardingHighlight] {
        switch self {
        case .welcome:
            [
                OnboardingHighlight(symbol: "sun.max", title: "Know what to do today", detail: "A clear, calm daily check-in."),
                OnboardingHighlight(symbol: "book.closed", title: "Every plant has a story", detail: "Care, observations and milestones belong to each plant."),
                OnboardingHighlight(symbol: "lock.fill", title: "Private and local-first", detail: "Your garden stays on this device. No account is required.")
            ]
        case .howItWorks:
            [
                OnboardingHighlight(symbol: "sun.max", title: "Today", detail: "A daily view of care that needs attention, recent moments and useful guidance."),
                OnboardingHighlight(symbol: "leaf", title: "My Plants", detail: "Your plant collection, profiles and plant-specific care."),
                OnboardingHighlight(symbol: "book.closed", title: "Journal", detail: "Notes, photos and milestones that build each plant's story.")
            ]
        case .getStarted:
            []
        }
    }
}

struct OnboardingHighlight: Equatable, Identifiable {
    let symbol: String
    let title: String
    let detail: String

    var id: String { title }
}

/// Three-page first-run presentation. The parent launch coordinator owns
/// persistence and dismissal so this view cannot accidentally complete
/// onboarding merely because it appeared or was interrupted.
struct OnboardingFlowView: View {
    let onSkip: () -> Void
    let onAddFirstPlant: () -> Void
    let onExploreFirst: () -> Void

    @State private var selectedPage = OnboardingPage.welcome

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TabView(selection: $selectedPage) {
                    ForEach(OnboardingPage.allCases) { page in
                        OnboardingPageView(page: page)
                            .tag(page)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .accessibilityIdentifier("onboarding.pages")

                pageActions
                    .padding(.horizontal, FeedGoodTheme.contentPadding)
                    .padding(.bottom, FeedGoodTheme.contentPadding)
            }
            .background(FeedGoodTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip", action: onSkip)
                        .foregroundStyle(FeedGoodTheme.leaf)
                        .accessibilityIdentifier("onboarding.skip")
                }
            }
        }
        .tint(FeedGoodTheme.leaf)
    }

    @ViewBuilder
    private var pageActions: some View {
        if selectedPage == .getStarted {
            VStack(spacing: 12) {
                Button(action: onAddFirstPlant) {
                    Text("Add your first plant")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(FeedGoodPressStyle(surface: .prominent))
                .accessibilityIdentifier("onboarding.addFirstPlant")

                Button(action: onExploreFirst) {
                    Text("Explore first")
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 50)
                }
                .buttonStyle(FeedGoodPressStyle(surface: .bordered))
                .accessibilityIdentifier("onboarding.exploreFirst")
            }
        } else {
            Button {
                withAnimation(.easeInOut) {
                    selectedPage = .allCases[selectedPage.rawValue + 1]
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity, minHeight: 50)
            }
            .buttonStyle(FeedGoodPressStyle(surface: .prominent))
            .accessibilityIdentifier("onboarding.continue")
        }
    }
}

private struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                Spacer(minLength: 12)
                if page == .welcome || page == .getStarted {
                    Image(systemName: "leaf.fill")
                        .font(.system(size: 42))
                        .foregroundStyle(FeedGoodTheme.leaf)
                        .frame(width: 104, height: 104)
                        .background(FeedGoodTheme.mist, in: Circle())
                        .accessibilityHidden(true)
                }

                VStack(spacing: 10) {
                    Text(page.title)
                        .font(.largeTitle.weight(.semibold).design(.serif))
                        .foregroundStyle(FeedGoodTheme.soil)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityIdentifier("onboarding.title.\(page.rawValue)")

                    Text(page.subtitle)
                        .font(.body)
                        .foregroundStyle(FeedGoodTheme.muted)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if page.highlights.isEmpty == false {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(page.highlights) { highlight in
                            OnboardingHighlightRow(highlight: highlight)
                        }
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
                }
                Spacer(minLength: 12)
            }
            .padding(.horizontal, FeedGoodTheme.contentPadding)
            .padding(.vertical, 16)
            .frame(maxWidth: 560)
            .frame(maxWidth: .infinity)
        }
    }
}

private struct OnboardingHighlightRow: View {
    let highlight: OnboardingHighlight

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: highlight.symbol)
                .font(.title3)
                .foregroundStyle(FeedGoodTheme.leaf)
                .frame(width: 44, height: 44)
                .background(FeedGoodTheme.mist, in: Circle())
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(highlight.title)
                    .font(.headline)
                    .foregroundStyle(FeedGoodTheme.soil)
                Text(highlight.detail)
                    .font(.subheadline)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
