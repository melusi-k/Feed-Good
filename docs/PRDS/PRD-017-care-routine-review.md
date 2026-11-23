# PRD-017 — Care Routine Review

**Status:** Implemented in PR #82; archive-aware integration and final CI verification included in PR #84  
**Priority:** P1  
**Release:** Post-MVP  
**Primary surfaces:** Plant Profile, Care Routine, existing CareTaskEditor

## 1. One-line goal
Help users review whether a plant's care routine still fits its context while keeping schedule changes explicit, understandable and reversible.

## 2. Users and use cases
A user wants to understand current care settings before changing them. They need to know how an edit affects the next due date and reminders, without the app silently prescribing a schedule.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| Read-only review | UI and state tests | Reviewing does not mutate tasks |
| Correct editing path | Domain/UI tests | Existing CareTaskEditor remains source of truth |
| Change comprehension | Product review | Due-date and reminder impact is clear before save |
| Safe persistence | Failure/cancel tests | Failed or cancelled edits preserve prior state |
| Reminder integrity | Notification tests | Reconciliation follows successful save only |

## 4. Behavior changes
- Add a routine-review entry point from the plant profile and care surface.
- Let users inspect task settings without changing them.
- Allow explicit edits to task type/title, interval, next-care date, enabled state and reminder setting through the existing CareTaskEditor/domain path.
- Show growing environment/light from the Plant record as read-only context, with a route to the Plant profile editor to change it.
- Explain the practical effect of a proposed routine change, including next due date and reminder behavior.
- Reconcile Today and local notifications only after an explicit successful save.

## 5. Out of scope
Automatic schedule recommendations, universal watering frequencies, weather/sensors, health-based schedule mutation, schedule analytics and replacement of existing editors.

## 6. Surfaces
Routine review summary; existing care-task editor; read-only growing-context summary and Plant Profile edit route; pre-save impact summary.

## 7. Pricing
Included in the local-first app. No account or network service is required.

## 8. Safety and data integrity
- Routine review must not mutate data or trigger notification permission prompts.
- Do not introduce a duplicate schedule model.
- Growing context is read from Plant and edited through the profile flow, not CareTaskEditor.
- Saving changes only the selected plant's selected task.
- Cancel or failed save leaves the original task and pending notifications intact.
- Missed care, check-ins, photos, symptoms and journal entries never automatically change a routine.
- Notification-denied and reminder-disabled states remain usable.
- Archived plants do not expose active-care routine actions.

## 9. Launch plan
1. Confirm the review entry point and read-only state.
2. Reuse the existing CareTaskEditor and domain update path.
3. Design a clear due-date/reminder impact explanation.
4. Reconcile Today/notifications after persistence succeeds.
5. Test task edits, cancellation, failed persistence, time zones/DST and notification reconciliation.
6. Complete accessibility, Dynamic Type, appearance and physical-device review.

## 10. Replaces
Replaces the need to navigate directly into an editor to understand a routine. It does not replace the existing task or Plant Profile editors.

## 11. Decisions and dependencies
- Builds on Care Routine #4 and Care Reminders #5.
- Precedes and blocks PRD-020 / issue #74 because quiet-period pause/resume must align with routine editing and reminder reconciliation.
- Related to PRD-016 lifecycle states, but neither is a hard prerequisite for the other's initial implementation.
- Not dependent on PRD-015, but must be archive-aware.
- Current baseline: CareTaskEditor owns task type, custom title, interval, next-care date, enabled state and reminder setting. Environment/light are Plant profile properties.

## 12. Delivery tracking
- GitHub issue: [#71 — Let users review and adjust plant care routines safely](https://github.com/melusi-k/Feed-Good/issues/71).
- Implementation: PR #82 merged to `main` (`8ead8a6`). PR #84 integrates the review route with archive state, hiding it for archived plants while retaining journal/story access. Final archive-stack CI is running.
