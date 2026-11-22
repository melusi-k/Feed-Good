# PRD-020 — Seasonal and Quiet Periods

**Status:** Proposed for post-MVP product review  
**Priority:** P2 care-control feature  
**Release:** After care-routine review and lifecycle policy are settled  
**Primary surfaces:** Plant Profile, Plant Care, Today, reminders, Plant Story

## 1. One-line goal

Let users intentionally record a seasonal or quiet period and adjust care expectations without automatic weather, location or health assumptions.

## 2. Users and use cases

A plant is dormant, outdoors for winter, away with another caregiver or temporarily receiving less attention. The user wants reminders and Today to reflect an explicit pause while keeping ordinary observations and history available.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Explicit pause | Start and end a quiet period | [measure] | [target: lifecycle tests pass] | [owner] / [date] |
| Impact clarity | Preview affected tasks and reminders | [measure] | [target: transition review passes] | [owner] / [date] |
| Recovery | End/edit/cancel without record loss | [measure] | [target: rollback tests pass] | [owner] / [date] |
| Time safety | Handle DST, time zones and open-ended periods | [measure] | [target: date matrix passes] | [owner] / [date] |

## 4. Behavior changes

- Add an explicit optional quiet-period action for a plant.
- Capture start date, optional end date, a user-selected label/reason and affected tasks.
- Preview which reminders and Today items pause, soften or remain active.
- Allow early ending, editing and cancellation.
- Preserve the period in Plant Story and export/restore.
- Keep ordinary journal observations and photos available during the period.
- Open-ended periods do not silently expire or create overdue guilt states.

## 5. Out of scope

- Automatic seasonal schedules or weather-aware automation.
- Dormancy diagnosis, plant-health inference or universal winter rules.
- Replacing routine review or lifecycle states.

## 6. Surfaces

- Quiet-period editor.
- Task-impact preview.
- Today/reminder paused state.
- End, edit and cancel controls.
- Plant Story period entry and archive/recovery behavior.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Never infer or label a plant as dormant without user choice.
- Make each affected task and notification behavior explicit before confirmation.
- Preserve care history and journal content.
- Do not imply that reduced activity is failure or proof of plant health.
- Support accessibility, offline use and notification-denied behavior.

## 9. Launch plan

1. Define the pause policy for due dates, intervals and notification rescheduling.
2. Align transitions with PRD-016 lifecycle states and PRD-017 routine review.
3. Add date, DST, time-zone, archive and notification tests.
4. Add UI journeys for start, preview, cancel, edit and end.
5. Review copy and physical-device behavior before release.

## 10. Replaces

Replaces ad hoc disabling of reminders or deleting tasks during a quiet season. It does not replace active routine editing or automatic seasonal intelligence.

## 11. Decisions and open questions

The key decision is whether pausing preserves the prior due date, freezes interval progress or establishes a new explicit next-care date. The implementation must not choose implicitly. Product review should also decide whether a quiet period is a lifecycle state, a routine overlay or both.

## 12. Delivery tracking

- GitHub implementation issue: [#74 — Add explicit seasonal and quiet-period support](https://github.com/melusi-k/Feed-Good/issues/74).
- Existing PRDs: [PRD-002 — Care Routine](PRD-002-care-routine.md) and [PRD-003 — Care Reminders](PRD-003-care-reminders.md).
