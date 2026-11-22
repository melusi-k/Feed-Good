# Feed Good — Feature PRDs

This directory contains the product requirements for individual Feed Good capabilities. Each PRD uses the agreed 11-part product template, followed by delivery tracking, so product intent, measurable outcomes, behavior, safety and launch criteria remain reviewable independently.

## Product standard

Feed Good is a gardening companion with the practical reliability of an assistant and the personality of a journal. Its central principle is:

> Help people build a relationship with their plants, rather than simply reminding them to water.

Every feature should help someone understand, notice, learn about or connect with a plant. Reminders and care tasks are supporting mechanisms, not the product's purpose.

## PRD register

| ID | Feature | Document | Primary outcome |
| --- | --- | --- | --- |
| PRD-001 | My Plants | [PRD-001-my-plants.md](PRD-001-my-plants.md) · [Issue #3](https://github.com/melusi-k/Feed-Good/issues/3) | A trusted, personal, searchable collection and profile for every plant |
| PRD-002 | Care Routine | [PRD-002-care-routine.md](PRD-002-care-routine.md) · [Issue #4](https://github.com/melusi-k/Feed-Good/issues/4) | Understandable, plant-specific care and durable activity history |
| PRD-003 | Care Reminders | [PRD-003-care-reminders.md](PRD-003-care-reminders.md) · [Issue #5](https://github.com/melusi-k/Feed-Good/issues/5) | Optional, dependable local reminders that respect user control |
| PRD-004 | Plant Journal | [PRD-004-plant-journal.md](PRD-004-plant-journal.md) · [Issues #12](https://github.com/melusi-k/Feed-Good/issues/12), [#14](https://github.com/melusi-k/Feed-Good/issues/14) | A meaningful record of observations, photos and milestones |
| PRD-005 | Today | [PRD-005-today.md](PRD-005-today.md) · [Issue #13](https://github.com/melusi-k/Feed-Good/issues/13) | A calm, useful daily check-in for the user's garden |
| PRD-006 | Feed Good Moments | [PRD-006-feed-good-moments.md](PRD-006-feed-good-moments.md) · [Issue #16](https://github.com/melusi-k/Feed-Good/issues/16) | Encouraging, useful daily reflections and care learning |
| PRD-007 | Garden Setup & Growing Context | [PRD-007-garden-setup.md](PRD-007-garden-setup.md) · [Issue #22](https://github.com/melusi-k/Feed-Good/issues/22) | Optional context that makes plant records and guidance more relevant |
| PRD-008 | Plant Care Guide | [PRD-008-care-guide.md](PRD-008-care-guide.md) · [Issue #23](https://github.com/melusi-k/Feed-Good/issues/23) | Curated, source-backed plant-care learning available offline |
| PRD-009 | Settings & Data Portability | [PRD-009-settings-data-portability.md](PRD-009-settings-data-portability.md) · [Issue #15](https://github.com/melusi-k/Feed-Good/issues/15) | Transparent settings and safe export/recovery of personal garden data |
| PRD-010 | Garden Profile | [PRD-010-garden-profile.md](PRD-010-garden-profile.md) · [Issue #42](https://github.com/melusi-k/Feed-Good/issues/42) | A trustworthy, shared overview of the user's existing garden records |
| PRD-011 | Care History Corrections | [PRD-011-care-history-corrections.md](PRD-011-care-history-corrections.md) · [Issue #63](https://github.com/melusi-k/Feed-Good/issues/63) | Correct mistakes without silently corrupting the active routine |
| PRD-012 | Growth Review | [PRD-012-growth-review.md](PRD-012-growth-review.md) · [Issue #64](https://github.com/melusi-k/Feed-Good/issues/64) | Make visual change and meaningful plant moments easier to notice |
| PRD-013 | Weekly Garden Reflection | [PRD-013-weekly-garden-reflection.md](PRD-013-weekly-garden-reflection.md) · [Issue #65](https://github.com/melusi-k/Feed-Good/issues/65) | Turn real local activity into a gentle, non-gamified look-back |
| PRD-014 | Plant Check-ins & Cautious Troubleshooting | [PRD-014-plant-check-ins.md](PRD-014-plant-check-ins.md) · [Issue #66](https://github.com/melusi-k/Feed-Good/issues/66) | Record observations and learn what to check next without diagnosis |
| PRD-015 | Plant Archive and Restore | [PRD-015-plant-archive.md](PRD-015-plant-archive.md) · [Issue #69](https://github.com/melusi-k/Feed-Good/issues/69) | Remove a plant from active care without deleting its story |
| PRD-016 | Plant Lifecycle States | [PRD-016-plant-lifecycle-states.md](PRD-016-plant-lifecycle-states.md) · [Issue #70](https://github.com/melusi-k/Feed-Good/issues/70) | Make a plant's current place in the garden understandable |
| PRD-017 | Care Routine Review | [PRD-017-care-routine-review.md](PRD-017-care-routine-review.md) · [Issue #71](https://github.com/melusi-k/Feed-Good/issues/71) | Adjust routines explicitly without inferred schedule changes |
| PRD-018 | Plant Changes Timeline | [PRD-018-plant-changes-timeline.md](PRD-018-plant-changes-timeline.md) · [Issue #72](https://github.com/melusi-k/Feed-Good/issues/72) | Preserve environmental context alongside plant observations |
| PRD-019 | Plant-Specific Journal Prompts | [PRD-019-plant-journal-prompts.md](PRD-019-plant-journal-prompts.md) · [Issue #73](https://github.com/melusi-k/Feed-Good/issues/73) | Make meaningful journaling easier without obligation |
| PRD-020 | Seasonal and Quiet Periods | [PRD-020-seasonal-quiet-periods.md](PRD-020-seasonal-quiet-periods.md) · [Issue #74](https://github.com/melusi-k/Feed-Good/issues/74) | Let users intentionally adjust care expectations for quiet periods |
| PRD-021 | Optional Plant Tags | [PRD-021-optional-plant-tags.md](PRD-021-optional-plant-tags.md) · [Issue #75](https://github.com/melusi-k/Feed-Good/issues/75) | Organize a collection lightly without requiring tags or multiple gardens |

## Release scope

### Initial release / MVP
- Core plant collection and profiles, including basic search and useful sorting.
- Optional, skippable growing context; it must not block adding a plant.
- Plant-specific care routines and optional local reminders.
- Plant journal, milestones and combined plant story.
- Today dashboard and bundled Feed Good Moments.
- A modest, reviewed, bundled Care Guide available offline.
- Settings, privacy transparency and tested data export/restore.

### Later opportunities — not MVP commitments
- Side-by-side photo comparisons and richer growth visualisations.
- Plant health troubleshooting and symptom exploration.
- Plant identification.
- Multiple independently managed gardens or shared spaces.
- Weather-aware care, sensors and other external data integrations.
- Shared garden access, social/community features, widgets and Live Activities.

### Next development tranche

The proposed post-MVP sequence is ordered by product trust and relationship value:

1. **PRD-011 — Care History Corrections:** a narrow trust fix for mistakes in recorded care, with an explicit history-only schedule policy.
2. **PRD-012 — Growth Review:** a derived visual review over existing journal photos and milestones.
3. **PRD-013 — Weekly Garden Reflection:** a quiet, local recap of real care and observation moments without streaks or scores.
4. **PRD-014 — Plant Check-ins & Cautious Troubleshooting:** a safety-gated observation flow that extends the reviewed offline learning model.
5. **PRD-015 — Plant Archive and Restore:** remove inactive plants from active care without deleting their stories.
6. **PRD-017 — Care Routine Review:** let users inspect and adjust routines explicitly.
7. **PRD-018 — Plant Changes Timeline:** preserve environmental context in the plant story.
8. **PRD-019 — Plant-Specific Journal Prompts:** invite reflection without obligation.
9. **PRD-020 — Seasonal and Quiet Periods:** support intentional pauses without weather-based assumptions.
10. **PRD-021 — Optional Plant Tags:** improve findability without requiring tags or multiple gardens.
11. **PRD-016 — Plant Lifecycle States:** evaluate a minimal state vocabulary after archive/restore; this is deliberately sequenced after PRD-015.

These proposals are tracked by GitHub issues #63–#75. They are not implementation authorization; each still needs product review, linked implementation work and exact-head verification.

A later opportunity needs its own product decision, PRD and issue before implementation. It must not be treated as implied MVP scope.

## How to read targets

- **[measure]** means a baseline must be collected before a numeric target is agreed.
- **[target]** means product and engineering must agree a threshold before the feature is considered release-ready.
- **[owner]** and **[date]** are deliberately unassigned until planning.
- A target is not achieved merely because the app builds. Record automated tests, simulator checks and physical-device evidence separately.

## Shared product and technical constraints

- Initial release: iOS 18+, SwiftUI and SwiftData.
- Local-first: core plant records, care history, journal and guide must work without an account or network connection.
- No mandatory sign-in, cloud sync, subscription, remote diagnosis or precise location collection in the initial release.
- Notification permission is optional. The app remains useful when it is denied.
- User-authored content must not be silently discarded.
- Care guidance must be qualified, explainable and plant-specific where the available information permits.
- Support light and dark appearance, Dynamic Type, VoiceOver, accessible contrast and comfortable touch targets.
- Avoid guilt, shame, unsupported diagnosis and universal watering assumptions.

## Change control

A PRD describes intended product behavior, not a commitment to implement every item immediately. Scope changes should update the relevant PRD, issue and roadmap together. Unresolved questions remain visible in section 11 rather than being silently converted into assumptions.
