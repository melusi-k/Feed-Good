# Feed Good — Architecture

## Guiding approach

Use Ate's proven engineering principles without importing its accumulated complexity. Start with a single iOS app target and introduce additional targets or infrastructure only when a demonstrated product need exists.

## Initial stack

- SwiftUI for presentation.
- SwiftData for on-device persistence.
- UserNotifications for opt-in local reminders when the care workflow is implemented.
- XCTest for deterministic domain and persistence tests.
- XcodeGen as the project-file source of truth.

## Target structure

```
FeedGood/
  App/          App entry point and composition
  Design/       Theme tokens and reusable presentation primitives
  Models/       SwiftData entities and domain types
  Features/     User-facing feature slices
    Plants/
    Care/
    Journal/
    DailyFeed/
  Services/     Platform adapters (notifications, photos, etc.)
  Store/        Persistence and application state boundaries
FeedGoodTests/  Unit and integration tests
docs/           Product, architecture and delivery decisions
```

This is a target structure, not a requirement to create empty folders or abstractions before they are needed.

## Data ownership

- Plant is the authoritative record for a plant.
- Deleting a plant removes its photo and notes, and cascades to its care activity and journal entries once those exist; the app always confirms before destructive deletion.
- Care activity records belong to one plant and are append-oriented history.
- Journal entries belong to one plant; user-authored text and photos must not be silently discarded.
- Reminder configuration is distinct from notification delivery state.
- SwiftUI views render state and express user intent; they do not own business rules.

## Persistence and privacy

- Begin on-device with SwiftData.
- Do not require sign-in or send plant, journal or photo data to a server.
- Treat deletion, migrations, backups and export as explicit product decisions before shipping destructive data operations.
- Never log private journal text or photo contents.
- Keep notification permission optional; the app remains useful when permission is denied.

## Dependency direction

Views may depend on domain models and feature services. Domain rules should not depend on SwiftUI. Platform APIs should be wrapped behind small services when doing so makes behavior testable or isolates permissions and side effects.

Avoid generic repositories, global service locators and dependency-injection frameworks until actual complexity justifies them.

## Quality requirements

- Unit tests for scheduling calculations and domain rules.
- Persistence tests for create/edit/delete and relationship integrity.
- UI tests for the primary plant and care journeys once those flows exist.
- Accessibility labels, Dynamic Type, sufficient contrast and comfortable hit targets.
- Build, unit-test, UI-test, simulator and physical-device evidence reported separately.

## Future architecture gates

Introduce sync, authentication, remote content, analytics, widgets or watchOS only after a product requirement, privacy model, failure behavior and acceptance criteria have been agreed.
