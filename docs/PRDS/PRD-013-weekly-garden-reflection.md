# PRD-013 — Weekly Garden Reflection

**Status:** Proposed for post-MVP product review  
**Priority:** P2 relationship feature  
**Release:** Post-MVP, after a baseline review of Today engagement and tone  
**Primary surface:** Today

## 1. One-line goal

Make a week of care and observation legible so people can recognise small moments of progress without being graded by a streak, score or completion percentage.

## 2. Users and use cases

A returning user wants to remember what happened in the garden this week. A beginner wants encouragement that is grounded in real observations rather than generic praise. A user who recorded a new leaf, recovery or care event wants a gentle route back to that plant's story. A user with a quiet week needs a calm, useful state rather than a failure message.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Source accuracy | Counts and moments match local records | [measure] | [target: derived-data tests pass] | [owner] / [date] |
| Determinism | Same week produces stable selection for fixed inputs | [measure] | [target: calendar/time-zone matrix passes] | [owner] / [date] |
| Reflection value | Show a small, understandable look-back | [measure] | [target: usability review confirms comprehension] | [owner] / [date] |
| Navigation | Open source plant/story from each moment | [measure] | [target: all routes pass UI coverage] | [owner] / [date] |
| Tone | Encourage without pressure or scorekeeping | [measure] | [target: product/content review passes] | [owner] / [date] |

## 4. Behavior changes

- Add an optional weekly Garden reflection card reachable from Today.
- Use the user's local civil-calendar week as the boundary, not a fixed 7 × 24-hour interval.
- Derive a small summary from existing `CareEvent`, `JournalEntry` and `Plant` records: recorded care count, journal observation count, up to three real moments/photos and the plants involved.
- Offer one gentle observation prompt and routes to the source plant or story.
- Handle empty weeks, no-photo weeks, deleted records and offline use without inventing progress.
- A small local preference may remember a dismissed or seen week so the card does not repeatedly interrupt the user. This is transient UI state, not garden history, and is excluded from the garden archive.
- The reflection must be quiet and opt-in through the Today surface; it is not a scheduled push notification.

## 5. Out of scope

- Health assessment, completion percentage, streaks, badges, rankings or comparisons with other people.
- Remote analytics, social sharing, scheduled push notifications or a persistent analytics/history store.
- Replacing Today, Daily Moments or the full Journal.
- Inferring that more activity means better plant health.

## 6. Surfaces

- Weekly reflection card on Today.
- Popover or detail sheet with the selected moments and source routes.
- Empty-week and no-photo states.
- Dismiss/seen behavior with a clear way to revisit the reflection during the same week.

## 7. Pricing

Included in the local-first app. No account, network service or subscription is required.

## 8. Safety bar

- Every count, plant and moment must come from a current local record.
- Avoid “you failed,” “perfect week,” “streak” and similar pressure language.
- Do not expose private journal note text or photos outside the intentional in-app surface.
- Do not imply that recorded care proves a plant is healthy.
- Keep the reflection usable with no plants, no activity, no photos, deleted records and notification permission denied.
- Support accessibility, Dynamic Type, light/dark appearance and clear source navigation.

## 9. Launch plan

1. Measure current Today usage and conduct a short tone/usability review before committing to a weekly cadence.
2. Define the deterministic selection and local-week rules.
3. Implement the derived summary without adding an analytics store.
4. Add unit tests for week boundaries, DST, empty/no-photo states and source accuracy.
5. Add UI coverage for populated, empty and dismissed states and source navigation.
6. Review copy, accessibility, privacy and physical-device behavior separately from CI.

## 10. Replaces

Replaces the absence of a calm look-back over real garden moments. It does not replace daily care guidance, reminders or the Journal.

## 11. Decisions and open questions

The product decision is whether the reflection should appear after any activity or only once a minimum amount of real activity exists. A quiet default is preferred over a notification-driven recap. Product and content review should confirm that the feature feels like a journal reflection, not a productivity scorecard.

The reflection should derive from current records on every render so edits and deletions are respected. A future version may support a user-saved recap, but that would require explicit archive and privacy decisions.

## 12. Delivery tracking

- GitHub implementation issue: [#65 — Add a weekly garden reflection without streaks or scores](https://github.com/melusi-k/Feed-Good/issues/65).
- Existing Today: [PRD-005 — Today](PRD-005-today.md).
- Existing Feed Good Moments: [PRD-006 — Feed Good Moments](PRD-006-feed-good-moments.md).
