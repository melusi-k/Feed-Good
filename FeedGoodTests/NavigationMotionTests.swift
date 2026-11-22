import Testing
@testable import FeedGood

struct NavigationMotionTests {
    @Test func tabIdentityOrderAndLabelsAreStable() {
        #expect(AppTab.allCases.map(\.order) == [0, 1, 2, 3])
        #expect(AppTab.allCases.map(\.title) == ["Today", "My Plants", "Journal", "Settings"])
    }

    @Test func reducedMotionHasNoCustomAnimation() {
        let policy = FeedGoodMotionPolicy(reduceMotion: true)
        #expect(policy.duration == 0)
        #expect(policy.animation == nil)
    }

    @Test func standardMotionUsesOneShortDuration() {
        let policy = FeedGoodMotionPolicy(reduceMotion: false)
        #expect(policy.duration == 0.2)
        #expect(policy.animation != nil)
    }
}
