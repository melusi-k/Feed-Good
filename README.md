# Feed Good

**A gardening companion with the practical reliability of an assistant and the personality of a journal.**

Feed Good helps people grow happier, healthier plants by making plant care more personal, understandable and rewarding. It combines reliable care guidance with a personal journal, helping people build meaningful relationships with the plants in their lives.

Its purpose is not simply to tell people when to water their plants. It is to help people understand their plants, notice how they change, learn what they need, and build a relationship with them over time.

## Our central product principle

> **Help people build a relationship with their plants, rather than simply reminding them to water.**

This is the test for every product and design decision. A feature should help someone understand, notice, learn about, or connect with a plant—not merely generate another task to complete.

### What this means in practice

- **Reminders explain, they don't just demand.** When a plant might need attention, guidance should explain why and help the person understand what to look for.
- **Plant profiles are living records.** Each profile should grow into a record of that plant's identity, care, changes and journey.
- **The journal builds observation.** Encourage people to notice growth, new leaves, seasonal changes, small wins and challenges.
- **Care guidance educates without guilt.** Help people learn what their plants need without making them feel bad when they miss a task.
- **Progress matters more than perfection.** Celebrate consistency, curiosity and progress—not perfect streaks or flawless routines.

## Product vision

Feed Good helps people grow happier, healthier plants by making plant care more personal, understandable and rewarding. It combines reliable care guidance with a personal journal, helping people build meaningful relationships with the plants in their lives.

## Product experience

- **Today:** a thoughtful daily check-in with relevant care guidance, gentle prompts and a reason to spend a moment with your plants.
- **My Plants:** a personal collection where each plant has an identity and, over time, a living record of its journey.
- **Care Routine:** clear, plant-aware care guidance and reminders that explain why attention may be useful.
- **Plant Journal:** photos, observations, notes and milestones that help people notice and remember change.
- **Feed Good moments:** encouraging thoughts and practical learning that make plant care feel approachable and rewarding.

## Product principles

1. Relationship before reminders.
2. Explain the why, not only the what.
3. Encourage observation and curiosity.
4. Teach without judgement or guilt.
5. Celebrate progress, not perfection.
6. Be dependable, honest and clear about what the app knows.
7. Keep the experience personal and useful, not noisy.

## Technology

- SwiftUI
- SwiftData
- UserNotifications (for local care reminders)
- XcodeGen
- XCTest and XCUITest
- GitHub Actions

Minimum deployment target: iOS 18.

The first release is intentionally local-first. Core plant records, observations and care history should work without an account or network connection.

## Build

Install Xcode and XcodeGen, then run:

```sh
brew install xcodegen
xcodegen generate
xcodebuild build -project FeedGood.xcodeproj -scheme FeedGood -destination 'generic/platform=iOS Simulator' CODE_SIGNING_ALLOWED=NO
```

Run tests:

```sh
xcodebuild test -project FeedGood.xcodeproj -scheme FeedGood -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

## Product and engineering docs

- [Product brief](docs/PRODUCT_BRIEF.md)
- [Architecture](docs/ARCHITECTURE.md)
- [Roadmap](docs/ROADMAP.md)

## Delivery principles

Plan → Build → Verify → Observe. A successful build is not the same as feature acceptance; record automated, simulator and physical-device evidence separately. Every screen and interaction should respect the relationship-first product principle and support both light and dark appearance.

Feed Good is inspired by the engineering discipline developed in [Ate](https://github.com/melusi-k/ate-ios), while maintaining its own product identity and appropriately smaller architecture.
