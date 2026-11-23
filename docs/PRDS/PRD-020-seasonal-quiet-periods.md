# PRD-020 — Seasonal and Quiet Periods

**Status:** Phase 2, Stage 2 — pause-clock policy approved; remaining scope and transition decisions open  
**Priority:** P2  
**Release:** Post-MVP, after lifecycle and routine-review decisions  
**Primary surfaces:** Plant Profile, Care Routine, Today, local reminders, Plant Story

## 1. One-line goal
Let users intentionally adjust care expectations for a plant during a seasonal or temporary quiet period without relying on weather, location or missed-care assumptions.

## 2. Users and use cases
A user wants to pause selected care tasks while a plant is resting or while they are away. They need to understand the effect on due dates, Today and reminders and know how care resumes.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| User control | UI tests | Explicit start/edit/end/cancel |
| Impact clarity | Product review | Affected tasks and reminders previewed |
| Date behavior | Calendar tests | Approved pause/resume policy is deterministic |
| Data integrity | Persistence/export tests | History and records preserved |
| Notification behavior | Reminder tests | Permission and settings respected |

## 4. Approved pause/resume policy

**Approved by product owner on 2026-11-23: use a pause-clock policy.** A quiet period freezes the remaining time on each included care task. It does not complete, skip, delete or rewrite a task or its care history. When the period ends, the task resumes with the same remaining time it had when the pause began.

Examples:
- A task due in 3 calendar days when the quiet period starts remains due in 3 calendar days after the period ends, regardless of how long the pause lasted.
- A task already due when the period starts is due when care resumes; the quiet period does not create additional overdue time.
- A task already overdue before the period starts retains that pre-existing overdue amount; the quiet period neither erases nor increases it.
- A task that would have become due during the quiet period does not become overdue while care is paused.

Use the app's calendar-day scheduling semantics (`CareSchedule`) rather than adding elapsed seconds. This avoids treating a daylight-saving transition as an extra or missing care day. The policy must be previewed before confirmation and applied consistently to Today and local reminders.

This is a product policy decision, not an approval of a particular persistence model. Do not implement by toggling `CareTask.isEnabled`, because that is the user's independent per-task routine setting and must be preserved. Do not mutate or synthesize `CareEvent` history.

## 5. Behavior changes
- Provide an explicit optional quiet-period action for an active plant.
- Capture start date, optional end date or explicitly open-ended period, user-selected reason/label and affected care tasks.
- Preview effects on each affected task, Today item and local reminder before confirmation.
- Allow edit, early end and cancellation.
- Preserve quiet-period history in Plant Story and export/restore.
- Keep ordinary journal observations available during a quiet period.

## 6. Out of scope
Automatic seasonal schedules, weather-aware automation, location inference, dormancy diagnosis, universal winter rules and replacement of routine review.

## 7. Surfaces
Quiet-period setup/editor; task-selection and impact preview; confirmation; active-period indicator; end/cancel flow; Plant Story history.

## 8. Pricing
Included in the local-first app. No account, network or location permission is required.

## 9. Safety and data integrity
- Never silently infer, start or end a quiet period.
- Open-ended periods remain open until the user ends them; they do not silently expire or generate overdue guilt states.
- Journal observations remain available and do not automatically end the period.
- Quiet periods do not delete or rewrite care history, journal content or photos.
- Ending/cancelling follows the approved policy and current reminder permission/settings.
- Archived plants cannot start or actively run care quiet periods.
- Lifecycle state, archive state and quiet period are separate concepts.

## 10. Launch plan
1. Resolve task scope: all enabled tasks on a plant or a user-selected subset; define whether the selection is fixed for the period.
2. Define routine-edit behavior while paused, including interval changes, explicit next-date changes, task creation/deletion and the existing per-task `isEnabled` switch.
3. Define whether users may record a care completion during a quiet period and how the remaining pause is then calculated without rewriting history.
4. Define immediate versus scheduled future starts, end-date inclusivity and local-calendar/time-zone behavior.
5. Define lifecycle constraints and the transition table, including archive during an active period and restore behavior.
6. Choose persistence only after the task/occurrence behavior is settled; coordinate with PRD-022 without pre-empting its occurrence-lifecycle decisions.
7. Implement preview, explicit confirmation, edit/end/cancel and reminder reconciliation only after the design gates are approved.
8. Test date boundaries, DST/time zones, pause/resume, cancellation, routine edits, archive compatibility, export/restore and permission-denied behavior.
9. Complete accessibility and physical-device review.

## 11. Replaces
Replaces informal or ambiguous handling of a temporary care pause. It does not replace archive, lifecycle state or routine editing.

## 12. Remaining design decisions and dependencies
- Hard AND prerequisites: PRD-016 / issue #70 lifecycle vocabulary and transition behavior **and** PRD-017 / issue #71 routine editing/reminder reconciliation policy.
- Builds on Care Routine #4 and Care Reminders #5.
- Related to PRD-015 archive; archived plants cannot have active quiet periods.
- Approved policy: pause the remaining time on included tasks and resume with that same remaining time; do not accumulate overdue time during the quiet period.
- Remaining design decisions: all-vs-selected task scope; open-ended due-task behavior (covered by pause-clock policy); routine edits and care completion during a pause; start/end date semantics; archive/restore interaction; persistence and occurrence coordination with PRD-022.
- No implementation should begin by silently choosing one of these policies.

## 12. Delivery tracking
- GitHub issue: [#74 — Add explicit seasonal and quiet-period support](https://github.com/melusi-k/Feed-Good/issues/74).
- Status: pause-clock policy approved 2026-11-23; remaining design decisions and implementation outstanding.
