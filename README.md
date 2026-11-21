# Feed Good

A native iOS gardening companion that helps people care for their plants and enjoy the journey of growing with them.

Feed Good starts with a simple promise: make plant care feel encouraging, personal and achievable.

## Product direction

- **My Plants:** a personal collection of plants.
- **Care Routine:** clear, configurable care tasks and local reminders.
- **Plant Journal:** photos, notes and milestones that capture each plant's journey.
- **Feed Good:** a daily gardening mantra and practical, confidence-building guidance.

The first release is intentionally local-first. Core plant records and care history should work without an account or network connection.

## Technology

- SwiftUI
- SwiftData
- UserNotifications (for a later care-reminder milestone)
- XcodeGen
- XCTest
- GitHub Actions

Minimum deployment target: iOS 18.

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

Plan → Build → Verify → Observe. A successful build is not the same as feature acceptance; record automated, simulator and physical-device evidence separately.

Feed Good is inspired by the engineering discipline developed in [Ate](https://github.com/melusi-k/ate-ios), while maintaining its own product identity and appropriately smaller architecture.
