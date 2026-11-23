# PRD-020 — Seasonal and Quiet Periods

**Status:** Phase 2, Stage 2 — pause-clock, task-scope, deletion, completion, scheduling and archive-transition policies approved; remaining routine-edit and persistence/date-zone decisions open  
**Priority:** P2  
**Release:** Post-MVP, after lifecycle and routine-review decisions  
**Primary surfaces:** Plant Profile, Care Routine, Today, local reminders, Plant Story

## 1. One-line goal
Let users intentionally adjust care expectations for a plant during a seasonal or temporary quiet period without relying on weather, location or missed-care assumptions.

## 2. Users and use cases
A user wants to pause selected care tasks while a plant is resting or while they are away. All currently enabled care tasks are preselected by default; the user may deselect any task before confirming. The selected task set is captured for that quiet period rather than dynamically expanding when routines change. The user needs to understand the effect on due dates, Today and reminders and know how care resumes.

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

## 5. Approved task-scope policy

**Approved by product owner on 2026-11-23:** quiet periods apply to a user-selected subset of care tasks. At setup, all tasks currently enabled for the plant are preselected by default; the user can deselect tasks before confirmation. This keeps the normal flow low-friction while allowing users to leave particular routines unaffected.

The selected task set is a snapshot for that quiet period. It does not silently grow when a task is created or enabled later. Task creation and routine changes during an active period remain separate design decisions and must be specified before implementation. The existing per-task enabled setting must not be repurposed to represent quiet-period membership.

## 6. Approved transition policies

**Task deletion during an active quiet period — approved 2026-11-23:** deleting one included care task removes only that task from the quiet period's affected-task set. The quiet period continues for its remaining selected tasks. If no affected tasks remain, the quiet period ends automatically. Task deletion follows the app's established task-deletion and history-retention contract; quiet-period handling must not independently erase historical care events.

**Care completion during a quiet period — approved 2026-11-23:** users may record a care completion while a quiet period is active. Recording a completion does not end, suspend or otherwise unpause the quiet period. The completion is persisted as normal care history. The precise due-date baseline for that task when care resumes must remain aligned with PRD-022's approved completion/occurrence semantics; do not silently advance or rewrite an occurrence as part of quiet-period handling.

**Start and end scheduling — approved 2026-11-23:** support both immediate activation and a scheduled future start date. A scheduled period becomes active at the start of the selected date in the same local calendar/time-zone context used by `CareSchedule`. For a period with an end, the user must specify both an end date and an end time; that local date-time is the actual inclusive end instant, and care resumes at that specified time. Do not interpret an end date as automatically lasting until midnight or the following day when an explicit end time has been selected. An omitted end date/time means explicitly open-ended until the user ends it. The time-zone/calendar anchor and DST edge-case policy must be finalized against the existing `CareSchedule` contract before implementation; do not use location inference or silently change the anchor when the device travels.

**Archive during a quiet period — approved 2026-11-23:** archiving terminates any active quiet period and removes its active pause before/with the archive transition; the plant's `archivedAt` is set by the archive action. Preserve the quiet-period record as ended history rather than deleting it. Restoring the plant does not reactivate the previous quiet period; the user must explicitly start another one if desired. Archived plants cannot have scheduled or active quiet periods.

## 7. Behavior changes
- Provide an explicit optional quiet-period action for an active plant.
- Capture immediate start or scheduled future start date, optional end date plus required end time (or explicitly open-ended period), user-selected reason/label and affected care tasks.
- Preview effects on each affected task, Today item and local reminder before confirmation.
- Allow edit, early end and cancellation.
- Preserve quiet-period history in Plant Story and export/restore.
- Keep ordinary journal observations available during a quiet period.

## 8. Out of scope
Automatic seasonal schedules, weather-aware automation, location inference, dormancy diagnosis, universal winter rules and replacement of routine review.

## 9. Surfaces
Quiet-period setup/editor; task-selection and impact preview; confirmation; active-period indicator; end/cancel flow; Plant Story history.

## 10. Pricing
Included in the local-first app. No account, network or location permission is required.

## 11. Safety and data integrity
- Never silently infer, start or end a quiet period.
- Open-ended periods remain open until the user ends them; they do not silently expire or generate overdue guilt states.
- Journal observations remain available and do not automatically end the period.
- Quiet periods do not delete or rewrite care history, journal content or photos.
- Ending/cancelling follows the approved policy and current reminder permission/settings.
- Archived plants cannot start or actively run care quiet periods.
- Lifecycle state, archive state and quiet period are separate concepts.

## 12. Launch plan
1. **Approved:** use a user-selected subset, with all currently enabled tasks preselected by default; capture the selected set for that period. Routine changes during an active period remain to be specified.
2. Define remaining routine-edit behavior while paused: task creation, interval/next-date edits and changes to the existing per-task `isEnabled` switch. Task deletion behavior is approved in section 6.
3. Coordinate the due-date baseline after care completion during a pause with PRD-022; completion is allowed and does not unpause the quiet period.
4. Finalize the `CareSchedule` calendar/time-zone anchor and DST edge cases for scheduled starts and the explicitly selected local end date/time, in coordination with PRD-022.
5. Implement and test the approved archive transition: end the quiet period, preserve its history, set `archivedAt`, and do not reactivate the period on restore.
6. Choose persistence only after the task/occurrence behavior is settled; coordinate with PRD-022 without pre-empting its occurrence-lifecycle decisions.
7. Implement preview, explicit confirmation, edit/end/cancel and reminder reconciliation only after the design gates are approved.
8. Test date boundaries, DST/time zones, pause/resume, cancellation, routine edits, archive compatibility, export/restore and permission-denied behavior.
9. Complete accessibility and physical-device review.

## 13. Replaces
Replaces informal or ambiguous handling of a temporary care pause. It does not replace archive, lifecycle state or routine editing.

## 14. Remaining design decisions and dependencies
- Hard AND prerequisites: PRD-016 / issue #70 lifecycle vocabulary and transition behavior **and** PRD-017 / issue #71 routine editing/reminder reconciliation policy. Issue #71 remains open pending failed-save, reminder-reconciliation-boundary and shared-ModelContext rollback-safety evidence.
- Scoped PRD-022 coordination gate: agree the overlapping occurrence/schedule contracts (completion during a pause, removed-task history and date/time semantics) before Quiet Period implementation. This does not require all PRD-022 scope to be implemented first; it prevents competing sources of truth.
- Builds on Care Routine #4 and Care Reminders #5.
- Related to PRD-015 archive; archived plants cannot have active quiet periods.
- Approved policy: pause the remaining time on included tasks and resume with that same remaining time; do not accumulate overdue time during the quiet period.
- Remaining design decisions: task creation and routine edits during a pause; due-date baseline after completion during a pause in coordination with PRD-022; calendar/time-zone anchor and DST edge cases for scheduled starts and selected end date/time; persistence and occurrence coordination with PRD-022.
- No implementation should begin by silently choosing any remaining policy or persistence behavior.

## 15. Delivery tracking
- GitHub issue: [#74 — Add explicit seasonal and quiet-period support](https://github.com/melusi-k/Feed-Good/issues/74).
- Status: pause-clock, task-scope, deletion, completion, immediate/scheduled start, selected end date/time and archive-transition policies approved 2026-11-23; remaining routine-edit/date-zone/persistence decisions and implementation outstanding.
