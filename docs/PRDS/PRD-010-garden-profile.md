# PRD-010 — Garden Profile

**Status:** Draft for product review; implementation in PR #41  
**Release:** Initial release / MVP  
**Primary surfaces:** Shared Profile sheet, Growing context, existing Settings tab

## 1. One-line goal

Give people a calm, trustworthy overview of their garden and a consistent route to app settings, using only information already stored in their local garden.

## 2. Users and use cases

- A plant owner wants a quick overview of how many plants they look after and the care and journal activity recorded for those plants.
- A user wants to revisit the species and notes they have already saved without opening each plant profile individually.
- A user wants to reach appearance and journal archive settings from a predictable place.
- A user opens Profile from whichever top-level tab they are using and expects the same experience.
- A user dismisses Profile and expects to return to the same tab and navigation context.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Shared entry point | Open Profile from Today, My Plants, Journal and Settings | [measure] | [target: all four root journeys pass UI automation] | [owner] / [date] |
| Garden summary | Counts match existing linked SwiftData records | [measure] | [target: empty, populated and unrelated/orphan record cases pass] | [owner] / [date] |
| Growing context | Review saved plant names, species and notes | [measure] | [target: empty and populated states pass without modifying records] | [owner] / [date] |
| Settings route | Reach the existing Settings tab from Profile | [measure] | [target: route selects Settings and uses its existing controls] | [owner] / [date] |
| Accessibility | Use Profile at larger text sizes and with VoiceOver | [measure] | [target: no blocking layout, focus or labeling defects] | [owner] / [date] |

## 4. Behavior changes

- Provide one Profile action at each top-level tab root: Today, My Plants, Journal and Settings.
- Keep one sheet presentation owner at the root tab container. All entry points invoke the same Profile view.
- Dismissing the sheet using Done or the native swipe gesture returns to the previously selected tab.
- Show three live, read-only counts:
  - **Plants:** distinct plant records in the current garden query.
  - **Care records:** care events linked to plants in that garden.
  - **Journal entries:** journal entries linked to plants in that garden.
- Exclude orphaned records and records linked to plants outside the queried garden from care and journal counts.
- Show a Growing context destination that lists each saved plant's name, species when present, and notes. Empty notes receive a neutral placeholder; an empty garden receives an explanatory empty state.
- Provide a route to the existing Settings tab. Appearance and journal archive tools remain in Settings; care reminders remain managed in each plant's care routine.
- Keep the Profile action on tab roots only. Do not add it to pushed plant/detail screens.
- Keep the experience local-first and read-only. Profile must not create an account, invent a personal identity, or write duplicate garden data.

## 5. Out of scope

- Account creation, sign-in, cloud sync, shared gardens or remote profiles.
- Personal name, avatar/photo, birthday, account creation date or other identity fields.
- Streaks, badges, scores, completion percentages or other progress claims without an approved definition and reliable source data.
- Structured global growing preferences or a new garden-setup editor. Existing plant species and notes are presented as-is.
- Global reminder preferences; reminder controls remain with plant care routines until a separate product decision.
- Duplicating appearance or journal archive settings inside Profile.
- Analytics or remote transmission of garden records.

## 6. Surfaces

- Profile toolbar action on the Today, My Plants, Journal and Settings tab roots.
- Shared Profile sheet with native navigation title, Done action and native swipe dismissal.
- Garden summary statistics.
- Growing context list and its empty state.
- Navigation from Profile to the existing Settings tab.
- Light and dark appearances, supported iPhone widths, Dynamic Type and VoiceOver.

## 7. Pricing

No feature-level charge. Garden Profile is part of the free, local-first initial release. No subscription, account or network service is required.

## 8. Safety bar

- Display only values derived from existing records; do not infer care quality, plant health, user identity or progress.
- Clearly label the three counts and ensure they describe records, not recommendations or achievements.
- Do not silently modify, delete, duplicate or migrate plant, care or journal records.
- Keep garden content on-device. Do not transmit profile details, notes or photos.
- Keep the Settings route and existing care-reminder management discoverable and avoid misleading users into believing reminders are globally controlled here.
- Ensure labels, reading order, contrast, touch targets and text scaling support accessibility.
- Empty and missing values must be described neutrally, without guilt or shame.

## 9. Launch plan

1. Confirm the Profile entry point is present on all four tab roots and absent from pushed detail pages.
2. Verify live counts against linked plant, care-event and journal records, including empty and unrelated/orphan record cases.
3. Verify Growing context shows saved plant data without changing it.
4. Verify Done and swipe dismissal preserve the selected tab and Settings routing selects the existing Settings tab.
5. Run the repository's build-and-test workflow on the exact final PR head SHA; confirm both Swift Testing unit tests and XCTest UI tests are discovered and executed.
6. Inspect retained simulator screenshots in light and dark appearance, including empty and populated states, narrow widths and larger Dynamic Type.
7. Record VoiceOver and physical-device verification separately from automated CI.
8. Release with the core app only after the acceptance criteria and repository merge requirements are satisfied.

## 10. Replaces

Replaces the absence of a consistent, garden-wide overview and a shared Profile entry point. It does not replace individual plant profiles, the Plant Journal, care routines or Settings; those remain the authoritative places for their respective tasks.

## 11. Decisions and open questions

Reconciled against PR #41 head `8e801afbba1ff784e7fae659e2294117b4dba1ee` on 2026-11-22. This records the proposed first-release behavior; automated CI and simulator verification remain outstanding until recorded against the final PR head.

### Settled for this slice

- **Profile is a shared sheet.** `AppTabView` owns presentation; tab roots invoke one environment action.
- **The four entry points are Today, My Plants, Journal and Settings.** My Plants adds Profile after its existing Sort and Add controls.
- **The summary is derived, not persisted.** It reads existing `Plant`, `CareEvent` and `JournalEntry` records and filters care/journal records to plants in the current garden query.
- **Growing context is read-only.** It surfaces each plant's existing name, species and notes; it does not introduce a new growing-context model.
- **Settings remains authoritative.** Appearance and journal archive stay in Settings; care reminders remain part of each plant's care routine.
- **No identity or progress is invented.** No account date, personal name/photo, streak or reminder status is displayed.
- **No schema or archive changes are part of this feature.**

### Still to verify before release

- Exact-head CI must build and execute the Swift Testing and XCTest suites successfully.
- Retained simulator screenshots must be inspected for all four roots, empty/populated Profile, and light/dark appearance.
- Larger Dynamic Type, VoiceOver order/labels, narrow widths and longer notes need explicit simulator/device verification.
- UI automation currently verifies the shared entry points, Done/swipe dismissal, Settings route, dark appearance, a populated plant count, Growing context and pushed-page scope. Care-event and journal-entry counts are directly asserted in the summary unit test; UI-level count presentation can be added if simulator evidence reveals a need.

## 12. Delivery tracking

- GitHub implementation issue: [#42 — Profile: shared garden overview and settings entry point](https://github.com/melusi-k/Feed-Good/issues/42).
- Implementation PR: [#41 — Add shared Profile sheet on every tab root](https://github.com/melusi-k/Feed-Good/pull/41).
- Test framework and exact-head CI policy: [Issue #30](https://github.com/melusi-k/Feed-Good/issues/30).
