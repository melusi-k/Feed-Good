# PRD-022 — Care Activity Lifecycle and Occurrence Management

**Status:** Design review — core lifecycle principles approved; transition matrix, edge-case contract and persistence decision in progress; no implementation issue created  
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
5. **Task edits:** During a quiet period, edits to an included task persist but do not remove it from the selected snapshot or automatically enable it. Explicit enabled-state changes are preserved, while the quiet-period overlay continues to suppress the included task until resume. New tasks remain outside the snapshot. Validate how interval/next-date edits recalculate the frozen remaining time.
6. **Removed tasks:** How are any unresolved occurrences represented after a task is removed while historical CareEvents remain?
7. **Time semantics:** Use the same calendar/time-zone context as `CareSchedule` for due-day calculations, scheduled starts and end date/time. Validate DST gaps/folds and device time-zone changes. Do not introduce a separate plant time-zone authority or use elapsed seconds for pause-clock calculations.
8. **Notification actions:** Which actions can be performed directly from a notification, and which require opening the app for confirmation?

Existing decisions remain authoritative until explicitly changed: interval-based recurrence, ordinary unpaused completion advances from the completion timestamp, and care-history corrections are history-only. The approved Quiet Period exception is documented in PRD-020. This PRD does not supersede PRD-002, PRD-003, PRD-011 or PRD-017.

## 12. Proposed persistence direction (design review; not yet implementation approval)

The current application has one reusable `CareTask` definition with a `dueDate`, and immutable-in-practice `CareEvent` history. Today derives due state from `CareTask.dueDate`; reminders are projected from enabled tasks and their due dates. Keep this as the single source of truth for ordinary care. Do not add a general `CareOccurrence` model unless a validated lifecycle requirement cannot be met with the current task/event contract.

Quiet Periods need persisted state that cannot be reconstructed safely from `CareTask.dueDate` after a pause has begun. The smallest candidate is:

| Candidate record | Purpose | Candidate fields |
| --- | --- | --- |
| `QuietPeriod` | One scheduled, active, ended or cancelled period for a plant | stable ID, plant ID, created/start timestamps, optional end timestamp, status, label/reason, ended/cancelled timestamp |
| `QuietPeriodTaskSnapshot` | One task's membership and frozen schedule state in that period | stable ID, quiet-period ID, task ID, task-title snapshot, membership state, signed remaining calendar-day count, captured/updated timestamp |

Use stable UUID references rather than making the quiet-period records depend on cascading SwiftData relationships to `CareTask`. This allows a deleted task's membership snapshot to remain auditable while marking it removed from the active affected set. A quiet period auto-ends when no snapshots remain active. The plant association must still be validated against the owning plant when reading/writing.

The signed remaining-day value represents calendar-day distance at activation: zero means due on the activation day; a negative value preserves pre-existing overdue days; a positive value preserves days remaining. On resume, reconstruct the due day from the resume date and this signed offset using the same injected `Calendar` used by `CareSchedule`. Preserve the existing due-time component only if the implementation can do so deterministically under the agreed local-time/DST contract; otherwise settle an explicit due-time rule before coding. Do not store elapsed seconds as the pause clock.

A completion during a pause writes the ordinary `CareEvent` and updates only that task snapshot's frozen remaining interval to the task's full current interval. It does not create a separate occurrence, unpause the task or cause a reminder to fire. On resume, the task's next due day is reconstructed from the resume date plus that frozen interval. Ordinary completion outside a pause continues to use completion timestamp plus interval.

**Schema/migration constraints:** current production persistence is `FeedGoodSchemaV2`, with a lightweight V1→V2 migration for `Plant.archivedAt`. Any new persisted models require an explicit schema-version/migration review (likely V3); do not edit V1/V2 historical schema definitions. Extend the archive format additively with optional quiet-period records, validate all IDs/plant/task references and status/date combinations before import, and preserve idempotent recovery/conflict checks. Do not silently import an active pause whose task or plant references cannot be reconciled.

**Still to validate before approving this model:** whether snapshots need the original local due-time components in addition to signed day count; the precise interval/next-date edit recalculation while paused; how an explicitly disabled task behaves at resume; timezone changes between scheduling, activation and resume; DST nonexistent/ambiguous local end times; and how a removed task snapshot is displayed in quiet-period history. This is a model candidate, not permission to start schema implementation.

## 13. Lifecycle transition matrix (design baseline)

| Trigger | Task / schedule effect | History effect | Today / reminder effect |
| --- | --- | --- | --- |
| Create scheduled quiet period | Store future period and task membership; pause clock has not started | Store period intent | Existing care remains active until scheduled start |
| Scheduled start arrives | Capture each included task's signed remaining calendar-day offset; period becomes active | Retain start transition | Suppress included tasks and their reminders; exclude non-members |
| Edit included task while active | Persist explicit task edits; do not remove membership or auto-enable; quiet-period overlay remains | No care event is created by editing | Continue suppressing included task until resume |
| Complete included task while active | Keep paused; reset its frozen remaining interval to its full current interval | Insert normal `CareEvent` | No active Today item/reminder until resume |
| Delete included task | Mark its membership removed; do not erase its snapshot/history | Existing CareEvents remain under the task-deletion contract | Remove only that task; end period if no active members remain |
| End at selected local date-time | Reconstruct due dates from frozen offsets; respect each task's explicit enabled setting | Mark period ended, retain record | Reconcile reminders only after successful persistence |
| Archive plant | End active period or cancel scheduled period | Retain period history; archive plant | No active care/reminders |
| Restore plant | Do not reactivate old period | Preserve prior period unchanged | User must explicitly create another period |

This matrix is a product baseline. Rows marked by unresolved timing/edit details remain subject to the validation gates above.

## 14. Delivery tracking


- **Implementation issue:** Not created. Create only after this PRD and its design gates are reviewed and approved.
- **Existing foundations:** [PRD-002 — Care Routine](PRD-002-care-routine.md), [PRD-003 — Care Reminders](PRD-003-care-reminders.md), [PRD-011 — Care History Corrections](PRD-011-care-history-corrections.md), [PRD-017 — Care Routine Review](PRD-017-care-routine-review.md).
- **Related proposals:** [#63 — Care History Corrections](https://github.com/melusi-k/Feed-Good/issues/63), [#71 — Care Routine Review](https://github.com/melusi-k/Feed-Good/issues/71), [#74 — Seasonal and Quiet Periods](https://github.com/melusi-k/Feed-Good/issues/74).
- **Dependency direction:** PRD-022 is the proposed foundation for PRD-023 and PRD-025. It must coordinate with #71 and must not pre-empt the AND dependency of #70 and #71 for #74.
- **Implementation status:** Not started. This document records product intent only.
