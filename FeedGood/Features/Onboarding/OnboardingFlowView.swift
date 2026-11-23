import SwiftUI
import OnboardingKit

/// The first-run onboarding: three skippable pages (Welcome, How it works,
/// Get started) built on OnboardingKit's paged flow. No setup questions and
/// no permission asks.
struct OnboardingFlowView: View {
    /// The user chose "Add your first plant" on the final page.
    let onAddFirstPlant: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pageIndex = 0

    private let pages = [0, 1, 2]

    var body: some View {
        NavigationStack {
            OnboardingFlowContainer(
                pages: pages,
                pageIndex: $pageIndex,
                addDoneButton: false,
                content: {
                    OnboardingPageView(
                        pages: pages,
                        pageIndex: $pageIndex
                    ) { info in
                    page(info.page)
                    }
                },
                buttons: { params in
                    VStack(spacing: 14) {
                        if params.isLastPage {
                            Button {
                                onAddFirstPlant()
                                dismiss()
                            } label: {
                                Text("Add your first plant")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .buttonStyle(FeedGoodPressStyle(surface: .prominent))
                            .accessibilityIdentifier("onboarding.addFirstPlant")

                            Button {
                                dismiss()
                            } label: {
                                Text("Explore first")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity, minHeight: 50)
                            }
                            .buttonStyle(FeedGoodPressStyle(surface: .bordered))
                            .accessibilityIdentifier("onboarding.exploreFirst")

                            Text("No account needed.")
                                .font(.caption)
                                .foregroundStyle(FeedGoodTheme.muted)
                        } else {
                            Button {
                                withAnimation { params.nextPageOrDismiss() }
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
            )
            .onboardingPageViewStyle(OnboardingPageViewStyle(
                pageIndicatorTintColor: FeedGoodTheme.sage.opacity(0.5),
                currentPageIndicatorTintColor: FeedGoodTheme.leaf
            ))
            .background(FeedGoodTheme.background.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Skip") { dismiss() }
                        .foregroundStyle(FeedGoodTheme.leaf)
                        .accessibilityIdentifier("onboarding.skip")
                }
            }
        }
    }

    @ViewBuilder
    private func page(_ index: Int) -> some View {
        switch index {
        case 0: welcome
        case 1: howItWorks
        default: getStarted
        }
    }

    private var welcome: some View {
        VStack(spacing: 26) {
            Spacer(minLength: 0)
            leafBadge
            VStack(spacing: 10) {
                Text("Welcome to Feed Good")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(FeedGoodTheme.soil)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("onboarding.welcome.title")
                    .accessibilityAddTraits(.isHeader)
                Text("Care for your plants, one day at a time.")
                    .font(.body)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .multilineTextAlignment(.center)
            }
            VStack(alignment: .leading, spacing: 18) {
                uspRow(symbol: "sun.max", title: "Know what to do today", subtitle: "Due care, a moment and a tip.")
                uspRow(symbol: "book.closed", title: "Every plant has a story", subtitle: "Entries and milestones, kept per plant.")
                uspRow(symbol: "lock.fill", title: "Private by default", subtitle: "Local-first. No account, no cloud.")
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FeedGoodTheme.contentPadding)
    }

    private var howItWorks: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            VStack(spacing: 10) {
                Text("How it works")
                    .font(.system(size: 30, weight: .semibold, design: .serif))
                    .foregroundStyle(FeedGoodTheme.soil)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("onboarding.howItWorks.title")
                    .accessibilityAddTraits(.isHeader)
                Text("Three tabs, one garden.")
                    .font(.body)
                    .foregroundStyle(FeedGoodTheme.muted)
            }
            VStack(spacing: 14) {
                tabCard(symbol: "sun.max", title: "Today", subtitle: "Your daily check-in: due care, recent moments and a fresh tip.")
                tabCard(symbol: "leaf", title: "My Plants", subtitle: "Profiles, photos and care routines for every plant.")
                tabCard(symbol: "book.closed", title: "Journal", subtitle: "Milestones and notes that grow into each plant's story.")
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FeedGoodTheme.contentPadding)
    }

    private var getStarted: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 0)
            leafBadge
            VStack(spacing: 10) {
                Text("Let's grow.")
                    .font(.system(size: 34, weight: .semibold, design: .serif))
                    .foregroundStyle(FeedGoodTheme.soil)
                    .multilineTextAlignment(.center)
                    .accessibilityIdentifier("onboarding.getStarted.title")
                    .accessibilityAddTraits(.isHeader)
                Text("Start with one plant, or look around first.")
                    .font(.body)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .multilineTextAlignment(.center)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, FeedGoodTheme.contentPadding)
    }

    private var leafBadge: some View {
        Image(systemName: "leaf.fill")
            .font(.system(size: 44))
            .foregroundStyle(FeedGoodTheme.leaf)
            .frame(width: 110, height: 110)
            .background(FeedGoodTheme.mist, in: Circle())
            .accessibilityHidden(true)
    }

    private func uspRow(symbol: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(FeedGoodTheme.leaf)
                .frame(width: 44, height: 44)
                .background(FeedGoodTheme.mist, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(FeedGoodTheme.soil)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func tabCard(symbol: String, title: String, subtitle: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: symbol)
                .font(.title3)
                .foregroundStyle(FeedGoodTheme.leaf)
                .frame(width: 44, height: 44)
                .background(FeedGoodTheme.mist, in: Circle())
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(FeedGoodTheme.soil)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(FeedGoodTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FeedGoodTheme.surface, in: RoundedRectangle(cornerRadius: FeedGoodTheme.cardRadius))
    }

}
