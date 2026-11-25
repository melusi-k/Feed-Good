# PRD-020 — Seasonal and Quiet Periods

**Status:** Delivered — pause-clock, task-scope, deletion, completion, scheduling, routine-edit, archive-transition, calendar/time-zone, V4 persistence/migration and JournalArchive v3 recovery are implemented and merged in PRs #121–125.  
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

The selected task set is a snapshot for that quiet period. Only tasks enabled when the period is configured are eligible; explicitly disabled tasks are excluded and have no active care schedule to freeze. A task does not silently enter the period when it is created or enabled later. If an included task is explicitly disabled during an active period, it ceases to be an affected task: retain any membership record for audit, but do not preserve or reconstruct a paused due time for it. Re-enabling it during that same period does not add it back. A newly created task is outside the period. Editing an included task does not remove it from the period or automatically enable it. Explicit edits to interval, next due date, enabled state and reminder preference are saved as the user's new task settings; the quiet-period overlay remains in force for that included task until the period ends. `CareTask.isEnabled` remains the user's independent setting: an edit must preserve its current value unless the user explicitly changes it. If the user explicitly enables an included task during the period, the quiet-period overlay still suppresses its active scheduling until resume. The updated task interval is retained independently of the Quiet Period, but its countdown remains frozen for the entire active period. An interval edit updates the task's frozen remaining interval to the newly selected interval; it does not start or advance that countdown during the pause. When the Quiet Period ends, the countdown starts/resumes from the updated interval. The Quiet Period's own dates and other tasks remain unchanged. The existing per-task enabled setting must not be repurposed to represent quiet-period membership.

## 6. Approved transition policies

**Task deletion during an active quiet period — approved 2026-11-23:** deleting one included care task removes only that task from the quiet period's affected-task set. The quiet period continues for its remaining selected tasks. If no affected tasks remain, the quiet period ends automatically. Task deletion follows the app's established task-deletion and history-retention contract; quiet-period handling must not independently erase historical care events.

**Care completion during a quiet period — approved 2026-11-23:** users may record a care completion while a quiet period is active. Recording a completion does not end, suspend or otherwise unpause the quiet period. Persist the `CareEvent` normally. For that included task, reset the paused remaining interval to the task's full current recurrence interval; the countdown remains frozen until the quiet period ends, then resumes from that full interval. This is the quiet-period exception to the ordinary completion schedule calculation; outside a quiet period, PRD-022's existing completion-time-plus-interval behavior remains authoritative. Do not create a second occurrence or rewrite historical events.

**Next care edit during an active quiet period — approved 2026-11-23:** when the user explicitly edits an included task's **Next care** date and time, that selected date-time becomes the authoritative schedule override. Preserve the exact selected instant when the quiet period ends; do not replace it with the frozen schedule. The task remains suppressed for the duration of the quiet period. If the selected date-time is already in the past when care resumes, show the task as overdue using the existing due-state rules. This override is independent of the recurrence interval, which continues to govern subsequent recurrence.

**Interval edit during an active quiet period — approved 2026-11-23:** changing the recurrence interval for an included task updates that task's paused remaining interval to the newly selected interval. Persist the updated interval, but keep its countdown frozen: it must not elapse or advance while the Quiet Period is active. Only when the Quiet Period ends does the task's countdown start/resume from that updated interval, and its Next care date is calculated from the resume point using the normal calendar-based scheduling calculation. The Quiet Period's own start/end dates and the schedules of other included tasks are unchanged. If the user explicitly edits Next care as well, that exact selected date-time remains authoritative and takes precedence over the interval-derived date.

**Start and end scheduling — approved 2026-11-23:** support both immediate activation and a scheduled future start date. A scheduled period becomes active at the start of the selected date in the same local calendar and time-zone context used by `CareSchedule`; creating the scheduled period does not pause the clock early. For a period with an end, the user must specify both an end date and an end time; that local date-time is the actual inclusive end instant, and care resumes at that specified time. Do not interpret an end date as automatically lasting until midnight or the following day when an explicit end time has been selected. An omitted end date/time means explicitly open-ended until the user ends it. The approved calendar/time-zone contract is recorded below and in PRD-022: preserve local due-time components and signed calendar-day offsets; resolve DST gaps to the next valid time and folds to the first occurrence; retain scheduled start/end as absolute instants; use the device's current calendar/time zone at activation/resume. Do not use location inference or introduce a plant-specific time zone.

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
1. **Delivered:** use a user-selected subset, with all currently enabled tasks preselected by default; capture the selected set for that period. Routine changes during an active period follow the approved edit rules below.
2. **Delivered:** apply the approved routine-edit behavior while paused: new tasks remain outside the captured set; editing an included task does not remove it or automatically enable it; explicit task-setting changes persist while the quiet-period overlay remains in force. Verify that interval edits update the frozen interval without advancing it until resume, that an explicit Next care edit remains authoritative, and that enabled/disabled combinations are handled correctly.
3. **Delivered:** apply the approved pause-completion rule: persist normal care history, reset that task's frozen remaining interval to its full current recurrence interval, and resume its countdown only when the quiet period ends. Keep ordinary completion-time-plus-interval semantics outside a pause.
4. **Delivered:** use the same calendar/time-zone context as `CareSchedule` for start/end interpretation and due-day calculations, including DST gaps/folds and device time-zone changes; no second plant time-zone source is introduced.
5. **Delivered:** implement and test the approved archive transition: end the quiet period, preserve its history, set `archivedAt`, and do not reactivate the period on restore.
6. **Delivered:** use the approved QuietPeriod and QuietPeriodTaskSnapshot persistence in schema V4, with V3→V4 migration; ordinary care continues to use CareTask dueDate plus CareEvent.
7. **Delivered:** implement preview, explicit confirmation, edit/end/cancel and reminder reconciliation.
8. **Delivered:** test date boundaries, DST/time zones, pause/resume, cancellation, routine edits, archive compatibility, export/restore and permission-denied behavior.
9. Complete the accessibility and physical-device review evidence tracked by the implementation/release process.

## 13. Replaces
Replaces informal or ambiguous handling of a temporary care pause. It does not replace archive, lifecycle state or routine editing.

## 14. Delivery verification and boundaries
- Hard prerequisites complete: PRD-016 / issue #70 lifecycle vocabulary and transition behavior is approved and PR #103 is merged to main. PRD-017 / issue #71 routine editing and reminder reconciliation is implemented and closed; persistence isolation and deletion hardening are merged in PRs #106 and #110.
- PRD-022 coordination gate is complete: the persistence/snapshot contract, plant/task deletion, archive compatibility and paused-completion edge cases were implemented in PRs #121–125.
- Builds on Care Routine #4 and Care Reminders #5.
- Related to PRD-015 archive; archived plants cannot have active quiet periods.
- Approved policy: pause the remaining time on included tasks and resume with that same remaining time; do not accumulate overdue time during the quiet period.
- Delivered: V4 schema and V3→V4 migration (#121–122), Quiet Period lifecycle (#123), care workflow integration (#124), JournalArchive v3 and compatibility (#125). The approved calendar/time-zone and DST behavior is covered by the implementation.
- Future changes to the approved pause-clock contract require explicit product review; do not reopen or duplicate the delivered implementation.

## 15. Delivery tracking
- GitHub issue: [#74 — Add explicit seasonal and quiet-period support](https://github.com/melusi-k/Feed-Good/issues/74).
- Status: Delivered and merged. PRs #121–122: V4 schema/migration; #123: lifecycle and scheduling; #124: care workflow integration; #125: archive v3 recovery and compatibility. No outstanding #74 implementation gate remains.
