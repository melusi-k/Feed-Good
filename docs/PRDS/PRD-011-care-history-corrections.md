# PRD-011 — Care History Corrections

**Status:** Proposed for post-MVP product review  
**Priority:** P1 trust improvement  
**Release:** First follow-up after the MVP foundation  
**Primary surfaces:** Plant Care history, Today, local reminder reconciliation

## 1. One-line goal

Let people correct an accidental care record without losing trust in the plant's history or silently changing unrelated care and journal data.

## 2. Users and use cases

A user records care against the wrong plant or task and needs to remove the mistake. A user entered the wrong date or note and wants to correct it. A user reviews an older care event and wants to preserve the rest of the history. A user edits a recent event and needs to understand whether the active routine will change.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Event correction | Change one event's date or note | [measure] | [target: transactional lifecycle tests pass] | [owner] / [date] |
| Safe deletion | Delete one event without unrelated loss | [measure] | [target: confirmation and relationship tests pass] | [owner] / [date] |
| Schedule clarity | Explain whether the active due date changes | [measure] | [target: no implicit schedule mutation] | [owner] / [date] |
| Reconciliation | Keep Today and local reminders consistent | [measure] | [target: accepted correction policy passes] | [owner] / [date] |
| Archive integrity | Export/recover corrected history | [measure] | [target: round-trip and conflict tests pass] | [owner] / [date] |

## 4. Behavior changes

- Add Edit and Delete actions to each recorded care event.
- Editing a care event changes only its completion date and optional note. The task-title snapshot remains the title recorded at the time.
- Deleting an event requires explicit confirmation and explains that the deletion is permanent for the on-device history; an exported archive is unchanged.
- **Recommended MVP schedule policy:** event correction is history-only by default. Editing or deleting an event never silently changes the task's active `dueDate` or interval. If the user wants a different next-care date, they use the existing routine editor as a separate, explicit action.
- If the edited event is the latest completion for its task, show the user that the active routine remains unchanged and offer a clear route to edit the routine. Do not guess whether the event date was biologically correct.
- After a successful change, derived Today content and local reminders continue to reflect the active task state. A correction must not create or leave a stale notification route.
- Failed saves roll back the event and preserve the original record.
- Keep the feature available offline and preserve current plant-story ordering.

## 5. Out of scope

- Automatically inferring a true care date.
- Recomputing schedules from historical events without an explicit product decision and user action.
- Bulk editing, undo history, care analytics, streaks or health conclusions.
- Editing care events belonging to another plant or changing a task's interval from a history row.

## 6. Surfaces

- Care history rows in Plant Care.
- Edit Care Event sheet with date and note fields.
- Delete confirmation and save-failure state.
- Plant story care entries after correction or deletion.
- Optional route from the latest-event explanation into the existing Care Task editor.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Make the distinction between recorded history and an active reminder routine explicit.
- Never silently rewrite unrelated historical events or the user's chosen schedule.
- Preserve user-authored notes and show failure without pretending a correction succeeded.
- Do not expose private care notes in notifications.
- Keep deletion confirmation understandable and ensure archive behavior is stated.
- Support Dynamic Type, VoiceOver, light/dark appearance and comfortable touch targets.

## 9. Launch plan

1. Confirm the history-only schedule policy with product review.
2. Add transactional domain methods for edit and delete, including rollback behavior.
3. Verify latest versus non-latest events, removed tasks, time zones and DST boundaries.
4. Verify Today, plant story, archive export/recovery and reminder reconciliation.
5. Add focused UI journeys for edit, delete confirmation, cancellation and failure.
6. Record simulator, accessibility and physical-device verification separately from CI.

## 10. Replaces

Replaces a read-only history that forces users to keep mistakes or delete an entire plant. It does not replace the active routine editor or create a new care-management system.

## 11. Decisions and open questions

The proposed default is history-only correction with no implicit due-date change. Product review must decide whether a later version should offer an explicit “use this as the latest completion” action. If that action is approved, it must preview the resulting next due date, be opt-in, and be covered by a separate schedule policy and migration-safe tests.

The existing append-oriented `CareEvent` model, archive records and plant-story projection should remain the source of truth. No new entity is expected for the MVP slice.

## 12. Delivery tracking

- GitHub implementation issue: [#63 — Correct or remove recorded care events without corrupting schedule](https://github.com/melusi-k/Feed-Good/issues/63).
- Parent feature: [PRD-002 — Care Routine](PRD-002-care-routine.md).
