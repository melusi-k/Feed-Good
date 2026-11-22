import Testing
@testable import FeedGood

struct NavigationMotionTests {
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
