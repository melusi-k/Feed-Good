# PRD-022 — Care Activity Lifecycle and Occurrence Management

**Status:** Quiet Period foundation and the scheduled-opportunity identity/lifecycle contract are delivered. The narrow scheduled-opportunity ledger is implemented and merged in PRs #145 and #150 (V5/V6 opportunity persistence, lifecycle integration and JournalArchive v5 compatibility), including the effective-due boundary and completion-window correction tracked in #147 (closed); PRD-024 issue #143 is closed. Quiet Period persistence, V3→V4 migration, pause/resume lifecycle, care-workflow integration and JournalArchive v3 recovery are implemented and merged. Skip/snooze and expanded notification-action policies remain deferred.  
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
  - Skipped and snoozed/deferred would be distinct user intentions; neither is implemented or implied by an overdue state. Any future behavior requires separate product approval.
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
3. **Delivered foundation and approved extension:** the shipped Quiet Period work retains `CareTask.dueDate` plus `CareEvent` history as the ordinary scheduling source and uses its own persisted parent/snapshot records for pause state. For PRD-024 scheduled-care analytics, the product has approved a separate, minimal persisted scheduled-opportunity record; it is not a general-purpose occurrence engine and does not replace either CareTask or CareEvent. That record is implemented and merged (#145, #150; issue #143 closed), including the effective-boundary and completion-window correction tracked in #147.
4. Skip and snooze/defer are not part of the delivered lifecycle foundation. Their semantics (if product work is prioritized later) require a separate proposal and approval; do not infer them from overdue state or add placeholder occurrence persistence.
5. Quiet Period domain transitions are implemented outside SwiftUI views with transactional persistence and deterministic calendar/time-zone handling. The implementation uses the same calendar/time-zone context as `CareSchedule`; no competing plant time-zone source was added.
6. The delivered Quiet Period work verifies plant/task isolation, duplicate and late/backdated completion, task edit/delete/disable, archive/restore compatibility, pause completion, interval edits during a pause and persistence failure. Notification actions beyond existing reminder routing remain outside this delivery.
7. Unit and UI coverage for the delivered transitions and failure paths is part of the merged implementation. Any future skip/snooze or expanded notification-action feature requires its own acceptance matrix and evidence.
8. The Quiet Period transition matrix below is the accepted baseline for implemented behavior. Ordinary care continues to use task due date plus CareEvent history; do not represent a conceptual occurrence as persisted state.

## 10. Replaces

Replaces ambiguous reminder-only behavior with a coherent, explicit care-activity lifecycle. It does not replace plant observation, the care guide or the user's judgment about whether a plant needs care.

## 11. Decisions and open questions

These decisions are separated into implemented contracts and deferred product questions; deferred items are not implicit implementation permission:

1. **Occurrence persistence — revised by approved PRD-024 contract (2026-11-25):** the already-delivered Quiet Period foundation did not require ordinary occurrence persistence. PRD-024's scheduled analytics do. Implement a narrow persisted opportunity record with immutable UUID, task/plant identity, scheduled-due instant, `open`/`completed`/`cancelled` state and optional linked CareEvent. CareTask remains the routine/current schedule source; CareEvent remains actual recorded history. This is not a general workflow engine.
2. **Skip policy — deferred:** no skip action or skipped-occurrence ledger is introduced by this delivery. Define and approve a separate product policy before implementing skip.
3. **Snooze/defer policy — deferred:** no snooze action or alternate due-date source is introduced by this delivery. Define and approve a separate product policy before implementing snooze/defer.
4. **Late and backdated completion:** Ordinary unpaused completion continues to schedule from actual completion time. Quiet-period completion follows PRD-020's frozen-interval reset rule. Test completion before due, on due day, after due, backdated completion, repeated taps and persistence failure; no second occurrence model is implied.
5. **Task edits:** During a quiet period, edits to an included task persist but do not remove it from the selected snapshot or automatically enable it. Explicit enabled-state changes are preserved, while the quiet-period overlay continues to suppress the included task until resume. New tasks remain outside the snapshot. **Approved:** an explicit user edit to Next care overrides the frozen due-date snapshot and is preserved as an exact date-time through resume; if it is past at resume, the task is overdue. **Approved:** changing an included task's interval during a pause updates that task's frozen remaining interval to the newly selected value. The countdown does not advance during the pause; it starts/resumes from the latest interval only when the Quiet Period ends. The Quiet Period's own dates and other tasks are unaffected. If Next care is also explicitly edited, that exact selected date-time remains authoritative and takes precedence over the interval-derived date. **Approved:** disabled tasks are excluded from the affected-task set because they have no active schedule/countdown to freeze. If an included task is disabled during the period, remove it from the active affected set while retaining an auditable membership snapshot; do not freeze or reconstruct a due time, and do not re-add it if enabled again during that same period. 
6. **Removed tasks — implemented for Quiet Period snapshots:** deleting an included task retains its snapshot identity/title as removed membership for audit/history; historical CareEvents remain governed by the task-deletion contract. No unresolved occurrence record is fabricated.
7. **Time semantics — approved 2026-11-23:** use the same calendar/time-zone context as `CareSchedule`; preserve an unedited task's signed calendar-day offset and original local hour, minute and second; reconstruct using the same injected calendar. Resolve a reconstructed DST gap to the next valid local time and an ambiguous DST fold to the first occurrence. Persist scheduled Quiet Period start and finite end as absolute instants. At activation and resume, calculate offsets and reconstruct local due times using the device's current calendar/time zone; do not persist a plant-specific time zone. An explicit Next care edit remains an exact absolute-instant override. Keep calendar-day semantics and do not use elapsed seconds. The approved calendar contract was subsequently implemented through schema V4, the V3→V4 migration and JournalArchive v3; no general CareOccurrence model was added.
8. **Notification actions — deferred beyond existing routing:** this delivery preserves existing reminder scheduling/reconciliation and routing. It does not add completion, skip or snooze actions directly from notifications. Any future action surface must define confirmation, save-failure and permission behavior first.

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

### Relationships, deletion and migration — implemented

The repository's current `Plant` model already uses cascading relationships for care tasks, care events and journal entries, and the hard-delete UI deletes the Plant then saves its ModelContext. Implemented ownership boundary: Plant owns QuietPeriod through a cascading relationship, and QuietPeriod owns QuietPeriodTaskSnapshot through a cascading relationship. Each snapshot's task UUID is a scalar identifier, not a cascading CareTask relationship. Hard-deleting a plant removes its Quiet Period history with the rest of the plant-owned record, while deleting one task leaves its snapshot auditable. Persistence tests cover both cascade boundaries and save-failure behavior.

Persistence now uses `FeedGoodSchemaV4`. V2 added `Plant.archivedAt`; V3 added `PlantTag` plus the optional `Plant.tags` relationship; V4 added `QuietPeriod` and `QuietPeriodTaskSnapshot`. Historical V1, V2 and V3 schema definitions remain immutable. The V3→V4 migration and full V1→V4 migration chain are covered by explicit migration tests, including real on-disk V1, build-52-era V2 and V3-with-tags fixtures.

JournalArchive v3 contains additive QuietPeriod and snapshot data while continuing to import supported v1 and v2 archives. Validate UUID uniqueness, plant ownership, snapshot-to-period references, membership/status values, start/end ordering, and active-period/task consistency before any writes. Reject an unreconcilable active period atomically rather than silently dropping or partially importing it. JournalArchive v3 export/recovery and v1/v2 import compatibility have been implemented and merged.

### Approved implementation constraints (2026-11-23)

The following decisions are approved for implementation:

1. Plant hard deletion cascades through QuietPeriod and its task snapshots, matching the existing Plant-owned record lifecycle. Deleting an individual CareTask does **not** cascade to its snapshot: retain the task UUID and title snapshot for audit/history, mark it removed from active membership, and display the retained history in Plant Story with a clear removed-task label.
2. Snapshot task UUIDs remain scalar identifiers, not CareTask relationships. Test task deletion retention, plant hard-delete cascade and save-failure behaviour.
3. JournalArchive advances from v2 to additive v3, preserving v1 and v2 import compatibility. Validate period/snapshot UUID uniqueness, ownership, references, enum/status values, start/end ordering and active-period/task consistency before any writes. Recovery remains additive/idempotent and rejects invalid or conflicting data atomically.
4. Pause completion tests cover before/on/after due, late/backdated completion, repeated completion and save failure. These cases must prove one normal CareEvent per accepted completion and correct frozen interval state without ending the pause.
5. Keep a general-purpose occurrence/workflow engine out of scope. The separately approved minimal scheduled-opportunity ledger for PRD-024 was tracked by issue #143 (closed) and is delivered in merged PRs #145 and #150.
6. Freeze V3 before any live-model mutation, then implement V4 and a V3→V4 migration. Historical V1/V2/V3 schema definitions remain immutable; prove migration from real on-disk V1, build-52-era V2 and V3-with-tags fixtures. Fresh-install tests alone are insufficient.

All #74 product and persistence design gates were approved and the four implementation slices have been delivered in merged PRs: #121–122 (V4 schema and migration proof), #123 (Quiet Period persistence and pause/resume lifecycle), #124 (care workflow integration), and #125 (JournalArchive v3 recovery and compatibility).

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

This matrix records the approved and implemented Quiet Period product transitions. Skip/snooze and expanded notification actions remain separate deferred product decisions; they do not reopen the approved timing, task-edit or pause-clock rules.

## 14. Delivery tracking


- **Implementation delivery:** Complete for the Quiet Period/lifecycle foundation in PRs #121–125. There is no remaining implementation issue for that approved scope.
- **Existing foundations:** [PRD-002 — Care Routine](PRD-002-care-routine.md), [PRD-003 — Care Reminders](PRD-003-care-reminders.md), [PRD-011 — Care History Corrections](PRD-011-care-history-corrections.md), [PRD-017 — Care Routine Review](PRD-017-care-routine-review.md).
- **Related proposals:** [#63 — Care History Corrections](https://github.com/melusi-k/Feed-Good/issues/63), [#71 — Care Routine Review](https://github.com/melusi-k/Feed-Good/issues/71), [#74 — Seasonal and Quiet Periods](https://github.com/melusi-k/Feed-Good/issues/74).
- **Dependency direction:** #70, #71 and the #74 Quiet Period persistence/migration/archive gates are complete. PR #103 and PRs #121–125 are merged. The scheduled-opportunity identity/lifecycle contract was approved on 2026-11-25 and its implementation is tracked in PRD-024 issue #143. Optional skip/snooze and expanded notification actions remain deferred.
- **Implementation status:** Quiet Period/lifecycle foundation delivered and merged (#121–125). Ordinary care remains task/date plus CareEvent. Skip/snooze and additional notification actions are explicitly deferred. This document records the delivered contract and those bounded future decisions.


## 15. Approved scheduled-opportunity contract for PRD-024 (2026-11-25)

The following narrow extension is approved for implementation in issue #143:

- Persist one opportunity per active task schedule instance, with immutable UUID, stable CareTask UUID, plant ownership, immutable original `scheduledDueAt`, mutable authoritative `effectiveDueAt` (initially equal to `scheduledDueAt`), lifecycle state (`open`, `completed`, `cancelled`) and optional linked CareEvent UUID. The original instant preserves what was scheduled; the effective instant governs current eligibility after approved pause/resume adjustments.
- `CareTask` remains the reusable routine/current schedule source. `CareEvent` remains the actual recorded-care history. An opportunity is not a duplicate event or task.
- A completed opportunity links to exactly one accepted CareEvent. An open opportunity is unresolved after its effective due instant; it becomes definitively overdue only after the applicable completion window expires. The completion-window duration must be sourced from the approved PRD-024 rule/configuration and must not be invented by the implementation.
- Explicit due-date reschedule cancels the superseded open opportunity and creates a replacement. Disable/delete cancels an open opportunity; cancellation is excluded from eligible denominators.
- Completion, event linkage and task schedule advancement must be atomic. Repeated completion cannot award duplicate credit.
- Preserve opportunity identity and exclude eligibility while the approved Quiet Period overlay suppresses the task. On resume, update `effectiveDueAt` to the resumed `CareTask.dueDate` under the existing PRD-020 calendar contract; retain immutable `scheduledDueAt` for audit. An explicit Next care/due-date override cancels the affected open opportunity and creates a replacement.
- On V5 migration, seed at most one open opportunity for each currently enabled, non-archived task with a valid current `CareTask.dueDate`, using that current due instant as both `scheduledDueAt` and `effectiveDueAt`. This is a forward-looking seed of the single current schedule pointer, not reconstruction of prior intervals or historical opportunities. Disabled tasks and tasks without a valid due date are not seeded. Historical CareEvents remain unlinked; no retroactive adherence/streak credit.
- Skip, snooze and defer are excluded from the first scheduled-care analytics/streak release. No corresponding UI, state, reminder action or placeholder outcome is implied.
- The ledger must be included in versioned JournalArchive export/recovery with backward-compatible import and strict ownership/reference validation.
- This approval supersedes only the earlier current-scope decision against ordinary persisted opportunities. It does not reopen or alter the already-delivered Quiet Period schema, pause-clock, migration or archive behavior.

Implementation: [issue #143](https://github.com/melusi-k/Feed-Good/issues/143).

### Boundary clarifications approved for implementation

- **Existing-install seed:** V5 migration seeds exactly one open opportunity for each currently enabled, non-archived CareTask that has a valid current due date. No prior intervals are reconstructed and no old CareEvents are linked. This establishes the analytics boundary at migration time while retaining the in-flight schedule.
- **Due and overdue:** Passing `effectiveDueAt` makes an open opportunity unresolved/due, not definitively overdue. It becomes overdue only after the applicable PRD-024 completion window expires. The implementation must use the already-approved window definition and must not invent a duration.
- **Reschedule versus defer:** Skip/snooze/defer are out of scope. An explicit user edit to Next care is a schedule replacement: cancel the superseded open opportunity and create a new one. No same-opportunity deferral behavior is shipped.
- **Quiet Period resume:** Keep immutable `scheduledDueAt` as the original audit instant. Update mutable `effectiveDueAt` to the resumed task due instant calculated by the existing PRD-020 calendar-day/DST rules. Preserve the same opportunity identity across the pause. Paused time is excluded from eligibility.
