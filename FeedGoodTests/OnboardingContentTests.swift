import Testing
@testable import FeedGood

struct OnboardingContentTests {
    @Test func onboardingHasExactlyThreePagesInApprovedOrder() {
        #expect(OnboardingPage.allCases == [.welcome, .howItWorks, .getStarted])
    }

    @Test func welcomeCommunicatesTheThreeApprovedBenefits() {
        let highlights = OnboardingPage.welcome.highlights
        #expect(highlights.map(\\.title) == [
            "Know what to do today",
            "Every plant has a story",
            "Private and local-first"
        ])
    }

    @Test func howItWorksExplainsTheThreePrimaryDestinations() {
        let highlights = OnboardingPage.howItWorks.highlights
        #expect(highlights.map(\\.title) == ["Today", "My Plants", "Journal"])
    }

    @Test func finalPageDoesNotIntroduceSetupQuestionsOrRequiredContext() {
        #expect(OnboardingPage.getStarted.highlights.isEmpty)
        #expect(OnboardingPage.getStarted.subtitle == "Start with one plant, or look around first.")
    }
}
