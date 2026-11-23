# PRD-022 — Care Activity Lifecycle and Occurrence Management

**Status:** Design review — ordinary care scheduling remains task/date plus CareEvent; Quiet Period product rules and calendar contract approved; minimal persistence/snapshot contract specified for review; migration/archive and remaining occurrence interactions not yet approved; no implementation issue created  
**Stage:** 1 — Care lifecycle foundation  
**Priority:** Proposed P1 foundation  
**Release:** Post-MVP, sequenced after review of the existing care and reminder contracts  
**Primary surfaces:** Today, Plant Care, Plant Profile, local notifications

## 1. One-line goal

Make each plant-care activity understandable across its lifecycle—from being scheduled and due, through completion or an intentional deferral—without confusing a recurring task definition with a particular care occasion or rewriting historical records.

## 2. Users and use cases

- A user wants to understand what care needs attention today and what can wait.
- A user completes a scheduled activity and expects the next occurrence to be calculated predictably.
- A user cannot perform an activity now and wants a deliberate, understandable way to defer or skip it.
- A user edits or pauses a routine and expects existing history to remain trustworthy.
- A user receives a notification and expects it to open the correct plant and care context.
- A user wants the app to distinguish a missed reminder from evidence that the plant was harmed or neglected.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Lifecycle clarity | Users can distinguish upcoming, due, overdue, completed, skipped and deferred states where supported | [measure] | [target: terminology and state-transition review passes] | [owner] / [date] |
| Occurrence identity | A care action is associated with the correct task, plant and scheduled occurrence | [measure] | [target: identity and relationship tests pass] | [owner] / [date] |
| Schedule integrity | Routine edits do not rewrite historical activity | [measure] | [target: mutation-boundary tests pass] | [owner] / [date] |
| Reminder integrity | Notification schedule and routing match the current task state | [measure] | [target: lifecycle reconciliation matrix passes] | [owner] / [date] |
| Date correctness | Due-state and recurrence behavior is deterministic across calendar/time-zone changes | [measure] | [target: agreed date/DST/time-zone matrix passes] | [owner] / [date] |

## 4. Behavior changes

- Establish a clear conceptual distinction between:
  - **Care task definition:** the user's reusable instruction/routine for a plant (for example, check soil every three days).
  - **Scheduled occurrence:** one particular opportunity to perform that activity.
  - **Care outcome/event:** the historical record of what the user actually did or observed.
- Keep the existing task definition as the source of truth for the routine. Do not create a second schedule or task-definition model.
- Define the lifecycle vocabulary and transition table before choosing persistence:
  - Upcoming, due and overdue are derived scheduling states, not proof of biological need.
  - Completed represents an actual user-recorded action and remains a historical event.
  - Skipped and snoozed/deferred are distinct user intentions; their exact schedule and history effects must be approved before implementation.
  - Disabled/paused describes the recurring task definition, not a completed or skipped occurrence.
- Define what happens when a task is edited, disabled, removed, archived with its plant, or restored. Preserve existing history and stable plant/task references wherever the data contract permits.
- Define how completion advances the next due date, including late completion, backdated completion, repeated taps and failed persistence. The current completion behavior (completion time plus interval) remains authoritative for ordinary, unpaused tasks. During an active Quiet Period, PRD-020 defines the approved exception: completion is recorded normally, the included task's frozen remaining interval resets to its full current recurrence interval, and countdown resumes only when the quiet period ends.
- Define notification identity, replacement/cancellation, permission-denied behavior and deep-link handling for every approved transition.
- Keep all transitions explicit and reversible where appropriate. No automatic catch-up queue or guilt-oriented escalation.
- Derive Today presentation from the approved task/occurrence policy; do not maintain a second conflicting source of due state.

## 5. Out of scope

- Species-specific or universal horticultural advice.
- Automatic watering, fertilising or other physical actions.
- Sensor-driven soil, light, weather or location inference.
- Seasonal/quiet-period behavior, which remains in PRD-020 and depends on #70 and #71.
- Care outcome measurements and observations, which are covered by PRD-023.
- Gamification, streaks, penalties, health scores or productivity grading.
- Replacing the existing CareTaskEditor or introducing a general-purpose workflow engine.

## 6. Surfaces

- Today task rows and grouped daily care summary.
- Plant Care task list, task detail and existing task editor.
- Completion confirmation and any approved skip/defer interaction.
- Notification content, action handling and destination routing.
- Plant Story / care history representation of actual recorded events.
- Empty, paused, overdue, permission-denied and persistence-failure states.

## 7. Pricing

Included in the local-first app. Lifecycle behavior must work without an account, network connection, subscription or third-party dependency.

## 8. Safety bar

- A due or overdue state is a scheduling signal, not a diagnosis or proof that care is required.
- Never imply that a plant is unhealthy because a user skipped or missed a reminder.
- Never encourage watering or treatment solely to clear an overdue state.
- Keep user-authored schedules distinct from curated horticultural guidance.
- Notifications must not expose private notes or unnecessary plant-health details.
- A failed save must not be presented as a completed action or leave a contradictory notification state.
- Preserve user-authored history across routine changes, archive/restore and supported export/recovery.
- Maintain offline usability, VoiceOver, Dynamic Type, accessible contrast and 44-point interaction targets.

## 9. Launch plan

1. Audit current CareTask, CareEvent, CareSchedule, CareRecorder, Today projection and CareReminderScheduler behavior against this PRD.
2. Produce and approve a lifecycle transition table covering task definition, scheduled occurrence, user action, persistence, due-date effect, history effect, Today visibility and notification effect.
3. **Approved direction:** keep the current task due date plus immutable `CareEvent` history as the source of truth for ordinary care scheduling; do not add a general persisted occurrence model merely to mirror a conceptual diagram. Quiet Periods may require their own persisted parent record and per-task pause snapshot because pause state/history cannot be safely derived from `CareTask.dueDate` alone. Validate the smallest migration-safe shape before implementation.
4. Decide exact skip and snooze semantics, including recurrence advancement, repeated deferrals, expiration and cancellation.
5. Implement domain transitions outside SwiftUI views, with transactional save/rollback and deterministic clock/calendar injection. Inject the same calendar/time-zone context used by `CareSchedule`; do not create a competing plant time-zone source.
6. Verify plant/task isolation, duplicate completion, late/backdated completion, task edit/delete/disable, archive/restore compatibility and notification reconciliation. For completion edge cases, explicitly cover completion before/at/after due date, backdated completion during a pause, repeated completion attempts, interval edits during a pause and save failure.
7. Add unit and UI tests for every approved transition and failure path; record manual device/accessibility evidence separately from CI.
8. Produce a transition matrix that records task/occurrence state, action, due-date baseline, history mutation, Today visibility and reminder effect for normal completion, paused completion, task edits, deletion, disable/enable, scheduled activation, end and archive.

## 10. Replaces

Replaces ambiguous reminder-only behavior with a coherent, explicit care-activity lifecycle. It does not replace plant observation, the care guide or the user's judgment about whether a plant needs care.

## 11. Decisions and open questions

These are mandatory design gates, not implementation assumptions:

1. **Occurrence persistence:** Is the current CareTask due date plus immutable CareEvent history sufficient, or is a first-class occurrence record required to support skip/defer and reliable notification routing?
2. **Skip policy:** Does skipping leave the due date unchanged, advance to the next interval, or record a skipped occurrence and calculate the next one? What is the user-facing explanation?
3. **Snooze policy:** Which durations are supported? Does snoozing alter only a notification, the scheduled occurrence, or both? Can it be repeated, cancelled or expire?
4. **Late and backdated completion:** Ordinary unpaused completion continues to schedule from actual completion time. Quiet-period completion follows PRD-020's frozen-interval reset rule. Test completion before due, on due day, after due, backdated completion, repeated taps and persistence failure; no second occurrence model is implied.
5. **Task edits:** During a quiet period, edits to an included task persist but do not remove it from the selected snapshot or automatically enable it. Explicit enabled-state changes are preserved, while the quiet-period overlay continues to suppress the included task until resume. New tasks remain outside the snapshot. **Approved:** an explicit user edit to Next care overrides the frozen due-date snapshot and is preserved as an exact date-time through resume; if it is past at resume, the task is overdue. **Approved:** changing an included task's interval during a pause updates that task's frozen remaining interval to the newly selected value. The countdown does not advance during the pause; it starts/resumes from the latest interval only when the Quiet Period ends. The Quiet Period's own dates and other tasks are unaffected. If Next care is also explicitly edited, that exact selected date-time remains authoritative and takes precedence over the interval-derived date. **Approved:** disabled tasks are excluded from the affected-task set because they have no active schedule/countdown to freeze. If an included task is disabled during the period, remove it from the active affected set while retaining an auditable membership snapshot; do not freeze or reconstruct a due time, and do not re-add it if enabled again during that same period. 
6. **Removed tasks:** How are any unresolved occurrences represented after a task is removed while historical CareEvents remain?
7. **Time semantics — approved 2026-11-23:** use the same calendar/time-zone context as `CareSchedule`; preserve an unedited task's signed calendar-day offset and original local hour, minute and second; reconstruct using the same injected calendar. Resolve a reconstructed DST gap to the next valid local time and an ambiguous DST fold to the first occurrence. Persist scheduled Quiet Period start and finite end as absolute instants. At activation and resume, calculate offsets and reconstruct local due times using the device's current calendar/time zone; do not persist a plant-specific time zone. An explicit Next care edit remains an exact absolute-instant override. Keep calendar-day semantics and do not use elapsed seconds. This approval does not approve a SwiftData schema, migration, archive format or general CareOccurrence model.
8. **Notification actions:** Which actions can be performed directly from a notification, and which require opening the app for confirmation?

Existing decisions remain authoritative until explicitly changed: interval-based recurrence, ordinary unpaused completion advances from the completion timestamp, and care-history corrections are history-only. The approved Quiet Period exception is documented in PRD-020. This PRD does not supersede PRD-002, PRD-003, PRD-011 or PRD-017.

## 12. Proposed Quiet Period persistence and snapshot contract

The current application has one reusable `CareTask` definition with a `dueDate`, and `CareEvent` history. Today derives ordinary due state from `CareTask.dueDate`; reminders are projected from enabled tasks and their due dates. Keep that as the single source of truth for ordinary care. Do not add a general persisted `CareOccurrence` model merely to mirror a conceptual lifecycle.

Quiet Periods need their own persisted state because an active pause and its frozen schedule cannot be reconstructed safely from `CareTask.dueDate` after activation. The recommended minimum is two records:

| Record | Responsibility | Required data |
| --- | --- | --- |
| `QuietPeriod` | One scheduled, active, ended or cancelled period owned by a plant | Stable UUID; plant UUID; created-at instant; selected start instant; optional finite end instant; status; optional reason/label; activated-at instant; optional ended/cancelled-at instant |
| `QuietPeriodTaskSnapshot` | Captured membership and that task's frozen scheduling state | Stable UUID; QuietPeriod UUID; task UUID; task-title snapshot; membership state; signed remaining calendar-day offset; original local due hour, minute and second; frozen remaining interval in days when reset/edited; optional exact Next care override instant; captured-at and updated-at instants |

Use UUID identifiers in the snapshot rather than a cascading `CareTask` relationship. Task deletion must not erase the membership/audit record or historical `CareEvent` records. A deleted task's snapshot is marked removed and excluded from the active affected set. A task explicitly disabled during the pause is marked removed-from-active-membership while retaining its audit record; re-enabling it during that same period does not re-add it. A Quiet Period ends automatically when no active task snapshots remain.

The period must be validated against its owning plant on every read/write. Archived plants cannot have scheduled or active periods. Archiving ends an active period or cancels a scheduled one, retaining its history; restoring the plant never reactivates it.

### Snapshot calculation and resume

At scheduled activation (not when a future period is created), capture each still-enabled selected task's signed calendar-day offset from the activation date using the same injected `Calendar` as `CareSchedule`:
- zero means due on the activation calendar day;
- a positive value preserves days remaining;
- a negative value preserves pre-existing overdue days.

Also capture the due date's local hour, minute and second. On resume, reconstruct the due date from the resume calendar day plus the signed offset, preserving those local time components. Use the same calendar/time-zone context as `CareSchedule`. If the reconstructed local time is in a DST gap, choose the next valid local time; if it is ambiguous in a DST fold, choose the first occurrence. Do not use elapsed seconds or persist a separate plant time zone.

Persist scheduled Quiet Period start and finite end as absolute instants. A device time-zone change does not rewrite those instants. At activation and resume, use the device's current calendar/time zone for calendar-day calculations and local due-time reconstruction.

### Edits and completion while paused

- An explicit **Next care** edit is stored as an exact absolute-instant override in the task snapshot. It takes precedence over the reconstructed frozen due date and remains authoritative through resume; if already past at resume, existing overdue rules apply.
- An interval edit updates the snapshot's frozen remaining interval to the newly selected interval. The countdown remains frozen and does not advance until resume.
- A completion during the pause writes the normal `CareEvent` and resets the snapshot's frozen remaining interval to the full recurrence interval in effect at completion. It does not end the pause or create another occurrence.
- If an interval edit follows a completion during the same pause, the later interval edit replaces the frozen interval value. Neither value counts down until resume.
- If both Next care and interval are edited, the exact Next care instant remains authoritative for the next scheduled date; the interval continues to govern subsequent recurrence.
- Outside a Quiet Period, ordinary completion remains completion-timestamp-plus-interval.

### Relationships, deletion and migration — still requiring explicit approval

The recommended ownership boundary is Plant → QuietPeriod → QuietPeriodTaskSnapshot, with cascade cleanup when a plant is hard-deleted. Snapshots should retain task UUIDs as scalar identifiers rather than a cascading task relationship. This keeps plant-owned history together while allowing a deleted task's snapshot to remain auditable until its parent period is removed. The implementation must use a transactional plant-deletion path or verified SwiftData cascade behavior; do not leave orphaned records.

Current persistence is `FeedGoodSchemaV2`, with V1→V2 migration for `Plant.archivedAt`. Keep V1 and V2 schema definitions immutable. If the proposed records are accepted, add them in a new schema version (expected V3) with explicit migration tests. No schema change is approved by this PRD alone.

The archive recommendation is an additive archive-format v3 containing optional QuietPeriod and snapshot arrays, while continuing to import supported v1 and v2 archives. Validate UUID uniqueness, plant ownership, snapshot-to-period references, membership/status values, start/end ordering, and active-period/task consistency before any writes. Reject an unreconcilable active period atomically rather than silently dropping or partially importing it. Confirm the exact archive versioning and recovery behavior in the archive contract before implementation.

### Remaining design gates

1. Confirm the Plant → QuietPeriod → snapshot ownership/cascade approach against the repository's actual hard-delete implementation.
2. Decide how removed-task snapshots are presented in Plant Story/export, without implying that a deleted task remains active.
3. Confirm archive v3 and v1/v2 import compatibility, including validation and atomic failure behavior.
4. Resolve the narrow PRD-022 occurrence interactions required by #74: removed-task history and paused completion edge cases (before/on/after due, late/backdated, repeated completion and save failure). Skip and snooze semantics remain separate PRD-022 work and do not block #74 unless implementation introduces a dependency.
5. Keep the general persisted `CareOccurrence` model out of scope unless a validated requirement demonstrates that `CareTask.dueDate`, `CareEvent` and the QuietPeriod snapshots cannot satisfy it.

This section is a concrete persistence recommendation for review, not authorization to start schema or archive implementation. Product-approved pause, completion, edit, task-scope and calendar/time-zone rules remain authoritative; the schema, relationships and archive version remain open until explicitly approved.

## 13. Lifecycle transition matrix (design baseline)

| Trigger | Task / schedule effect | History effect | Today / reminder effect |
| --- | --- | --- | --- |
| Create scheduled quiet period | Store future period and task membership; pause clock has not started | Store period intent | Existing care remains active until scheduled start |
| Cancel scheduled period before activation | Mark period cancelled; no task due-date changes | Retain cancelled period | Existing Today/reminders remain unchanged |
| Create a task during an active period | Do not add it to the captured membership | No history mutation | New task follows its own enabled/reminder settings |
| Explicitly disable an included task during pause | Preserve disabled setting; remove it from the active affected-task set while retaining an auditable membership snapshot. Do not freeze or reconstruct a due time. Re-enabling during the same period does not re-add it. | No history mutation | Remains disabled; no active Today item/reminder. |
| Explicitly enable a task that was excluded or removed because it was disabled | Preserve enabled setting; do not add it to the captured quiet-period set | No history mutation | It follows normal task scheduling and is not suppressed by this period |
| Change reminder preference during pause | Persist preference without ending pause | No history mutation | Apply the new preference only when reconciling after resume |
| Scheduled start arrives | Capture each enabled included task's signed remaining calendar-day offset; disabled tasks have no active schedule to freeze and are excluded | Retain start transition | Suppress enabled included tasks and their reminders; disabled tasks remain disabled |
| Edit included task while active | Persist explicit task edits; do not remove membership or auto-enable; quiet-period overlay remains | No care event is created by editing | Continue suppressing included task until resume |
| Complete included task while active | Keep paused; reset its frozen remaining interval to its full current interval. A later interval edit replaces this frozen value; neither countdown advances until resume. | Insert normal `CareEvent` | No active Today item/reminder until resume |
| Delete included task | Mark its membership removed; do not erase its snapshot/history | Existing CareEvents remain under the task-deletion contract | Remove only that task; end period if no active members remain |
| End at selected local date-time | Reconstruct due dates from frozen offsets; respect each task's explicit enabled setting | Mark period ended, retain record | Reconcile reminders only after successful persistence |
| Archive plant | End active period or cancel scheduled period | Retain period history; archive plant | No active care/reminders |
| Restore plant | Do not reactivate old period | Preserve prior period unchanged | User must explicitly create another period |

This matrix records the approved Quiet Period product transitions. Remaining gates concern persistence, deletion/archive compatibility and validation evidence; they do not reopen the approved timing, task-edit or pause-clock rules.

## 14. Delivery tracking


- **Implementation issue:** Not created. Create only after this PRD and its design gates are reviewed and approved.
- **Existing foundations:** [PRD-002 — Care Routine](PRD-002-care-routine.md), [PRD-003 — Care Reminders](PRD-003-care-reminders.md), [PRD-011 — Care History Corrections](PRD-011-care-history-corrections.md), [PRD-017 — Care Routine Review](PRD-017-care-routine-review.md).
- **Related proposals:** [#63 — Care History Corrections](https://github.com/melusi-k/Feed-Good/issues/63), [#71 — Care Routine Review](https://github.com/melusi-k/Feed-Good/issues/71), [#74 — Seasonal and Quiet Periods](https://github.com/melusi-k/Feed-Good/issues/74).
- **Dependency direction:** PRD-022 is the proposed foundation for PRD-023 and PRD-025. It must coordinate with #71 and must coordinate with #74's remaining persistence/migration/archive gates; #70's approved lifecycle decision and #71's implemented routine/reconciliation contract are complete (with #103 still to merge as the stacked documentation prerequisite).
- **Implementation status:** Not started. This document records product intent only.
