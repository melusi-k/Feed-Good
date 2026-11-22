# Testing

How Feed Good's automated tests are organized, which framework owns which kind of test, and what CI expects. Tracking issue for the Swift Testing migration: #30.

## Framework selection

- **Swift Testing is the default for all unit tests** (`FeedGoodTests`). Use `import Testing`, `@Test`, `#expect` and `#require`. Suites are plain structs; add `@Suite` only when a name or traits are needed.
- **XCTest is retained where its APIs are required**: UI automation in `FeedGoodUITests` (`XCUIApplication`/XCUITest) and any future XCTest performance measurements. Swift Testing does not support UI tests; do not attempt to migrate them.
- Both frameworks coexist in the same CI run. That is expected and permanent.

## Current state

The XCTest-to-Swift-Testing unit-test migration is complete:

- All 17 files in `FeedGoodTests` (82 tests) are Swift Testing. No `import XCTest` remains in the unit-test target.
- Migration landed incrementally in #29, #31, #47, #48, #49, #50 and #58, each preserving test count and assertion strength one-to-one on its exact head, with required checks green before merge.
- Targeted coverage for the P1-P4 gaps agreed in #30 landed in #54. The SwiftData schema-migration test is explicitly deferred until a previous-schema migration contract exists.
- The 12 files in `FeedGoodUITests` remain XCTest by design.

## Migration rules

Historical reference for any future framework move:

- Migrate incrementally, one small PR per slice; no mass rewrites that only change imports.
- Preserve test intent, fixtures, assertion count and behavioural coverage one-to-one.
- Assertion mapping: `XCTAssertEqual(a, b)` -> `#expect(a == b)`; `XCTUnwrap(x)` -> `try #require(x)`; `XCTFail(msg)` -> `Issue.record(msg)`; `XCTAssertThrowsError` -> `#expect(throws:)` with the specific error type, never `Error.self`.
- Use `#require` for preconditions (it throws and stops the test) and `#expect` for assertions. A test that reaches neither passes vacuously; always assert something.
- Never negate with `!` inside `#expect`/`#require` (`#expect(x == false)`, not `#expect(!x)`); negation defeats macro expansion diagnostics. This is enforced by `scripts/check-review-rules.sh`.

## Isolation rules

Swift Testing runs tests in parallel and in random order. Every test must stand alone:

- Own SwiftData container per test; no shared persistent stores.
- Own temporary directory for file-system work.
- Deterministic clocks, calendars, time zones and UUIDs; no dependence on wall-clock time.
- No shared mutable state and no order dependence between tests.
- Service boundaries are injected (for example the notification boundary used by care-reminder tests), so unit tests never depend on real notification delivery or other system services.

Known Swift Testing pitfalls:

- `.serialized` applies to parameterized tests and whole suites only; it has no effect on a plain non-parameterized `@Test`.
- `.timeLimit()` accepts `.minutes()` only; there is no `.seconds()`.
- `confirmation()` cannot wait for work the tested code fires into an untracked `Task`; make the code `async` or return the `Task` so the test can await it.
- `@available` goes on individual tests, not suites.
- Two argument collections in one parameterized test form a Cartesian product, not a zip.

## CI expectations

- `ios-ci.yml` (build-and-test) runs `xcodebuild test -scheme FeedGood`, whose test action includes both `FeedGoodTests` and `FeedGoodUITests` (see `project.yml`). A green run proves both frameworks execute together.
- `thread-sanitizer.yml` runs the unit-test target under the thread sanitizer (`-only-testing:FeedGoodTests`).
- `navigation-motion-proof.yml` runs one UI proof class (`-only-testing:FeedGoodUITests/NavigationMotionProofUITests`).
- `review-rules.yml` runs the review-rule ratchet, which includes test-code rules (no `#expect(!...)`, no `Task.sleep` in tests).
- Required checks must pass on a pull request's exact head SHA before merge.

## Running locally

```
xcodegen generate
xcodebuild test -project FeedGood.xcodeproj -scheme FeedGood \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

Never edit `FeedGood.xcodeproj` directly; test-target membership changes go in `project.yml`.

## Regression baseline

Post-migration baseline on main at 357f2b1: 82 unit tests across 17 files in `FeedGoodTests`, 12 UI test files in `FeedGoodUITests`. Compare counts and assertion strength against this baseline when touching tests; investigate any unexpected reduction before merging.
