# PRD-017 — Care Routine Review

**Status:** Proposed for post-MVP product review  
**Priority:** P1/P2 reliability feature  
**Release:** After care-history correction policy is settled  
**Primary surfaces:** Plant Profile, Plant Care, Today, reminders

## 1. One-line goal

Help users decide whether a plant's care routine still fits its context, while keeping every schedule change explicit and user-controlled.

## 2. Users and use cases

A user moved a plant, changed its light, repotted it, or noticed that the routine no longer fits. They want to review the current setup without being told that the app knows the correct schedule.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Review clarity | Inspect without accidental edits | [measure] | [target: review journey passes] | [owner] / [date] |
| Explicit change | Preview and save selected changes | [measure] | [target: task and reminder tests pass] | [owner] / [date] |
| Failure safety | Cancel/failure preserves old routine | [measure] | [target: rollback tests pass] | [owner] / [date] |
| User control | No inferred schedule mutation | [measure] | [target: product safety review passes] | [owner] / [date] |

## 4. Behavior changes

- Add a routine-review entry point from Plant Profile and Plant Care.
- Let users inspect task frequency, reminder time and relevant growing context through the existing editor.
- Offer neutral prompts about moved rooms, repotting, seasonal shifts or changed patterns.
- Preview what will change, including the next due behavior and notifications, before saving.
- Reconcile Today and local notifications only after an explicit save.
- Keep routine review separate from care-history correction, check-ins and plant changes.
- Continue to support incomplete growing context and denied notification permission.

## 5. Out of scope

- Automatic schedule recommendations or health-based schedule mutation.
- Universal watering intervals, weather or sensor inputs.
- Care analytics, streaks or replacing the existing task editor.

## 6. Surfaces

- Plant Profile routine-review entry point.
- Read-only routine summary.
- Edit/preview sheet.
- Save, cancel and failure states.
- Today and reminder reconciliation after a confirmed change.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Never suggest that the app has determined the biologically correct schedule.
- Make every affected task and reminder visible before saving.
- Never mutate a routine because care was missed or a symptom was recorded.
- Preserve the previous routine on cancellation and failure.
- Support accessibility, offline use and notification-denied behavior.

## 9. Launch plan

1. Confirm whether routine changes should appear in Plant Story or remain settings history.
2. Reuse the current task and notification lifecycle rather than creating a second schedule model.
3. Add date, time-zone, DST and notification-rescheduling tests.
4. Add UI tests for review-only, preview, save, cancel and failure.
5. Verify accessibility and physical-device behavior.

## 10. Replaces

Replaces the need to hunt through settings to understand whether a routine still fits. It does not replace care-history correction or create automatic horticultural advice.

## 11. Decisions and open questions

Decide whether a routine change should create a visible Plant Story event, a private settings-history record or no history at all. The safest initial version may show the new routine immediately without claiming that the change explains future plant outcomes.

## 12. Delivery tracking

- GitHub implementation issue: [#71 — Let users review and adjust plant care routines safely](https://github.com/melusi-k/Feed-Good/issues/71).
- Existing PRDs: [PRD-002 — Care Routine](PRD-002-care-routine.md) and [PRD-003 — Care Reminders](PRD-003-care-reminders.md).
