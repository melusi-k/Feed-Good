# PRD-024 — Care Analytics, Streaks & Plant Health Insights

**Status:** Product contract approved 2026-11-26; implementation and release-hardening gates remain open  
**Stage:** 3 — Care understanding, consistency and plant-health evidence  
**Priority:** Proposed P2 capability  
**Release:** Incremental delivery after the source-record contracts in PRD-022, PRD-023 and relevant plant-history foundations are stable  
**Primary surfaces:** Garden Profile (Garden Care Streak), Plant Profile (Plant Care Streaks), Plant Story, Growth Review and Today  
**Data posture:** Local-first, derived from authoritative user records; no duplicate care ledger

## 1. One-line goal

Help people understand how they care for their plants and what has been happening to each plant by turning existing care records, observations and visual history into transparent analytics, fair consistency streaks and carefully qualified plant-health insights—without rewarding unnecessary care, shaming users, diagnosing disease or claiming unsupported causality.

## 2. Problem and intended outcomes

Care information is currently distributed across schedules, care outcomes, check-ins, journal entries, plant changes and photos. Users need to answer three different questions:

1. **Care activity:** What care has been planned and recorded, and how has that pattern changed over time?
2. **Care consistency:** Have eligible care commitments been kept over time, without counting periods when care was not due or was intentionally paused?
3. **Plant story and health evidence:** What has the user observed about this plant, what has visibly changed, and what can reasonably be said from the available evidence?

The product must keep these questions distinct. A care metric is not a plant-health measurement. A streak is not a judgement of a user's commitment or a reason to perform unnecessary interventions. An observation is not a diagnosis.
- Plant Care Streaks are private, descriptive histories for one care task. The Garden Care Streak is a separate, private, descriptive garden-wide summary of qualifying scheduled-care days. Neither is an engagement, retention or plant-health metric.

Success means users can understand their own records, spot meaningful changes, and navigate from every displayed result to the records that support it.

## 3. Users and use cases

- Understand the care history and activity pattern for one plant or a selected collection.
- See whether scheduled care is being completed, deferred, skipped or left unresolved, with each outcome represented honestly.
- Recognise periods of consistent completion without being penalised for disabled tasks, valid pauses, quiet periods or times when no care was due.
- Review the current and longest eligible streak for each individual care task.
- Compare a plant's observations and photos across time.
- Understand what evidence supports an insight and what remains unknown.
- Use the experience with sparse records, irregular care schedules, archived plants and offline data.

## 4. Product principles and non-goals

### 4.1 Principles

- Source records remain authoritative; analytics, streaks and insights are derived projections.
- Every metric and insight must expose its period, scope, definition and source evidence.
- A missing record is unknown, not proof that care did not happen.
- No activity is better than inappropriate activity. Do not incentivise watering, feeding, pruning or other interventions when they are not due.
- A plant's health cannot be reduced to a care-completion percentage or a single score.
- Neutral language, user control and transparent uncertainty take precedence over engagement mechanics.
- Results must be deterministic, reproducible after edits/import/restore and usable offline.

### 4.2 Explicit non-goals

- Biological health scores, grades, risk scores, rankings or collection leaderboards.
- Gamification that pressures users to perform unnecessary care or compete with other users.
- Diagnosis, disease/pest identification, treatment prescriptions or guaranteed recovery claims.
- Claims that a recorded care action caused a plant outcome.
- Automated interpretation of free-text notes or photos in this release.
- Cloud analytics, account requirements, remote processing or third-party tracking.
- A new source-of-truth care ledger or replacement for schedules, care events, check-ins, journal, Plant Story or Growth Review.
- Habit formation, habit strength, automaticity or behavioural adoption scores inferred from care-task completion, streaks or app activity.

## 5. Scope and capability areas

### 5.1 Care analytics

Provide transparent summaries for an individual plant and, where the data supports it, the user's selected collection:

- Care activity history by period and care category/type.
- Scheduled opportunities and their recorded outcomes: completed, skipped, deferred/rescheduled, unresolved/overdue, disabled and paused/not-applicable.
- Completion rate for eligible scheduled opportunities, only when the denominator is known and meaningful.
- Care consistency over time, shown as a trend or period breakdown rather than a quality grade.
- Distribution of recorded care actions by category.
- Historical period comparisons using equivalent definitions and clearly stated date ranges.
- A traceable activity timeline that links every row to the originating task occurrence or care event.

Do not combine completed manual care events with scheduled opportunities in a single completion-rate denominator. Unscheduled/manual care can contribute to activity history and distribution, but not to scheduled completion rate unless a source contract explicitly identifies the corresponding scheduled occurrence.

**Metric catalogue and calculation contracts**

| Metric | Definition | Required data | Guardrails |
| --- | --- | --- | --- |
| Eligible opportunities | Scheduled occurrences that were active and due in the selected period | Stable occurrence identity, due time, lifecycle state | Exclude disabled, paused and valid quiet-period occurrences; do not count not-yet-due occurrences |
| Completed opportunities | Eligible occurrences with an authoritative completed outcome | Occurrence-to-care-event relationship and completion timestamp | Corrections must follow PRD-022 history rules; never infer completion from a note/photo |
| Completion rate | Completed eligible opportunities ÷ all resolved eligible opportunities | Completed, skipped and other final outcomes with denominator contract | Show only when denominator is non-zero and outcome semantics are stable; label period and denominator |
| Unresolved/overdue count | Eligible occurrences past their due boundary with no final outcome | Due boundary, current occurrence state, local time-zone rules | Show as an operational schedule state, not a plant-health signal or user failure |
| Care activity | Count/list of recorded care events in period | Care event timestamp/type/plant identity | Distinguish scheduled from unscheduled care; never infer quality or need |
| Care distribution | Share/count of recorded events by care category | Normalised care category mapping | Use counts when categories are not comparable; do not imply an ideal distribution |
| Period comparison | Same metric for two explicitly identified periods | Identical metric definition and compatible source coverage | Mark incomparable periods when source coverage, schedule rules or data completeness differ |

The denominator and treatment of skipped/deferred outcomes must be consistent with PRD-022's final lifecycle contract. A skipped occurrence is not completed, but must remain separately visible rather than silently being treated as a missed or failed action. A deferred occurrence moves according to the approved rescheduling contract; it must not be counted twice. Disabled and paused occurrences are excluded from eligible opportunities for the relevant interval.

No metric may claim that a user is a good/bad plant owner or that a plant is healthy/unhealthy.

### 5.2 Plant Care Streaks (per-task consistency)

Provide a private, informational **Plant Care Streak** for each individual care task, calculated from that task's eligible scheduled opportunities—not raw event volume. A watering routine and a feeding routine therefore have separate Plant Care Streaks, even when they belong to the same plant. The Garden Care Streak in §5.2.1 is a distinct garden-level measure and must never be presented as a combined Plant Care Streak.

Initial product contract:

- Every streak is scoped to one stable care-task identity and that task's own schedule. It is not scoped to the plant as a whole.
- Separate care tasks never contribute to one another's streak. Do not combine watering, feeding, pruning or other routines into a plant-wide or garden-wide streak.
- A streak is a sequence of consecutive eligible opportunities for that task that received an authoritative completed outcome within the permitted completion window defined by the approved lifecycle contract.
- The streak advances only when an eligible opportunity for that same task is completed.
- A final skipped outcome breaks that task's current streak but remains visible as a skip; it does not erase historical streak records.
- An unresolved eligible opportunity breaks the current streak only after its due/completion window has definitively elapsed under the agreed local-time contract.
- A deferred/rescheduled occurrence follows its new authoritative due boundary and is counted once.
- Disabled tasks, explicit task pauses, valid quiet periods and periods in which that task has no care due are neutral: they neither advance nor break its streak.
- Task rename, schedule edits, disablement, deletion and recreation must follow PRD-022's stable-identity and history rules. A newly created task must not inherit another task's streak; histories must never be merged because task names or care types match.
- A correction to a care event updates the derived streak according to the source correction history; preserve an auditable history of the corrected source record, not a fabricated streak event.
- A streak must never encourage users to perform care earlier or more often than the plant's schedule requires.
- Streaks are descriptive history only. They must not trigger reminders, streak-loss messages, rewards, badges, targets, competition, social comparison or retention/engagement nudges.

**Per-task streak outputs**

- Current streak for that task, if one exists, with its start date and count of eligible opportunities.
- Longest historical streak for that task, with its date range and eligible-opportunity count.
- Recent history for that task, including interruptions and neutral periods.

**Explicitly excluded from Plant Care Streaks**

- Plant-wide Plant Care Streaks that combine multiple care tasks.
- Combining Plant Care Streak counts into a garden-level score or total.
- Streak milestones, badges, rewards, targets, leaderboards, social sharing or streak-loss notifications.
- Inclusion of streaks in PRD-013 Weekly Garden Reflection.

The Plant Profile may display separate Plant Care Streak summaries together, but must label each task clearly. It must not calculate or imply a combined Plant Care Streak. The Garden Care Streak is displayed separately on the Garden Profile under §5.2.1.



### 5.2.1 Garden Care Streak (garden-wide scheduled-care days)

Provide a separate, private, descriptive **Garden Care Streak** representing consecutive qualifying local calendar days across the user's active garden. It is not a sum, average, maximum or relabelling of Plant Care Streaks. It is calculated directly from all eligible scheduled-care opportunities across the garden.

**Approved qualification contract (2026-11-26):**

- **Qualification rule: all.** For a local calendar day to qualify, every eligible scheduled-care opportunity whose authoritative `effectiveDueAt` falls within that local day must have an authoritative linked CareEvent completed on time.
- **Period: local calendar day.** Use the user's configured calendar/time zone, injected into a deterministic calculator. Local day boundaries are half-open: [local midnight, next local midnight). Calendar days may therefore be 23, 24 or 25 elapsed hours across daylight-saving transitions.
- **On-time definition:** use the shared inclusive 24-hour opportunity grace window [effectiveDueAt, effectiveDueAt + 24 hours]. Do not substitute a calendar-day deadline for this opportunity-specific deadline.
- **Pending day:** a day with one or more eligible opportunities still open within their grace windows remains provisional. Do not count it as a success or a failure until all its eligible opportunities have resolved or their individual grace deadlines have expired.
- **Failed day:** if any eligible opportunity is completed outside its grace window, or remains open after its deadline, that day does not qualify. A later completion cannot repair the day or restore a broken run.
- **Neutral day:** a local day with no eligible opportunities does not advance or break the Garden Care Streak. The streak is a run of consecutive qualifying scheduled-care days, with no-opportunity days skipped; it does not assert that the user should perform care every calendar day.
- **Eligibility:** cancelled opportunities are excluded. Disabled tasks and active Quiet Period intervals remain neutral under the owning lifecycle contract. Archived plants generate no new eligible obligations; open opportunities made neutral by archive must not fail the day. Historical completed opportunities remain part of the historical garden record for the day on which they were due.
- **Scope:** include eligible opportunities for all non-deleted plants in the user's local garden, regardless of care type or plant schedule. A plant/task added later contributes only from its first persisted eligible opportunity; do not backfill missing historical opportunities or infer past care.
- **Corrections:** recompute affected historical days from authoritative opportunity and CareEvent state after completion correction/deletion, schedule edits, Quiet Period changes, archive/restore and import. Preserve the source lifecycle's identity and audit rules.
- **No incentives:** do not encourage early, additional or unnecessary care to protect the Garden Care Streak. Plant need and the authoritative schedule always take precedence. No rewards, badges, targets, leaderboards, social comparison, streak-loss notifications or retention nudges.
- **No habit inference:** the Garden Care Streak is not a habit score or a measure of motivation, commitment, automaticity or plant health.

**Garden Care Streak outputs and presentation:**

- Current run of qualifying scheduled-care days and its local start date.
- Longest historical run and its local date range.
- A clear pending state while any opportunity in the current candidate day remains within its grace window.
- An explanation that all due scheduled care must be completed on time, days with no scheduled care are neutral, and a streak is not a daily-care target.
- Display on Garden Profile with the exact local time-zone basis and coverage start. Do not place it in Plant Profile as a plant-level streak.

The Garden Care Streak and Plant Care Streaks must have separate names, definitions, calculators, outputs and UI labels. Never call both simply “streak” without context, and never derive one by aggregating the displayed counts of the other.

### 5.3 Plant-health insights and conclusions

The feature may surface evidence-led observations, but must not present a diagnosis or a definitive biological health conclusion.

Allowed insight classes:

- **Recorded observation:** A direct statement of what the user recorded, attributed and linked to its source.
- **Change over time:** A comparison between user-recorded observations or photos with dates and source links.
- **Pattern in records:** A cautious statement that a pattern appears in the records, only where there are enough comparable observations.
- **Evidence gap:** A neutral statement that there is not enough recent or comparable information to assess a change.
- **Consider checking:** A non-diagnostic prompt to inspect a relevant condition, only when grounded in a user-recorded observation and reviewed product copy.

Not allowed:

- Disease/pest diagnosis, severity labels or risk predictions.
- “Healthy”, “unhealthy”, “recovering”, “dying” or equivalent conclusions unless presented as the user's own explicitly attributed wording.
- Causal claims such as “watering improved the plant”.
- Inferences from care frequency, missed tasks, inactivity, photo count or lack of journal entries.
- AI-generated symptom extraction or image analysis in this release.

**Evidence requirements**

- Each insight identifies the plant, period, source records and whether it is a direct fact, user observation or app-generated interpretation.
- Trend comparisons require comparable observations of the same attribute, or explicitly comparable photos, with dates and provenance shown.
- Do not infer a trend from one observation. If the minimum evidence threshold is not met, show an evidence-gap state.
- Avoid combining unrelated signals into a single conclusion.
- Conflicting observations must be shown as conflicting or inconclusive, not resolved by guessing.
- The app may describe temporal proximity (“recorded after”) but must not imply causation.
- Insights must be recomputed when their supporting records are edited, deleted, archived, restored or imported.

### 5.4 Plant story and timeline

Plant Story is the canonical presentation surface for the combined chronology. It may group care events, check-ins, journal moments, plant changes, photos and derived insight markers, while retaining source-specific identity and navigation.

Plant Profile may show a compact summary and entry point. Avoid creating a competing standalone destination. Growth Review remains responsible for photo comparison; PRD-024 may link into it and display only supported summaries.

## 6. Source records and ownership

PRD-024 consumes, but does not own or mutate:

- PRD-022 care task, the scheduled-opportunity identity/lifecycle contract once approved, and pause/quiet-period state.
- PRD-023 structured care outcomes attached to care events.
- PRD-014 plant check-ins and their observations.
- PRD-018 plant changes timeline.
- PRD-012 Growth Review and its photo comparison capabilities.
- Journal entries, photos and milestones already owned by their respective domains.
- Plant identity, archive/restore and import/export contracts.

PRD-024 owns the read models/calculators for analytics, streaks and insights, plus presentation preferences only where required. It must not duplicate source data or create a second editable representation of a care event.

Unknown future source types must be preserved in the underlying data and either omitted from a specific derived metric with an explicit unsupported-source count or shown as a neutral, safely labelled timeline item. Never silently relabel an unknown record as a known care type.

## 7. Calculation, time and historical integrity contracts

- Store and compare instants using the app's established timestamp representation; derive local calendar boundaries using the user's configured time zone.
- Every period-based view displays its exact start/end dates and time-zone basis.
- Define day/week/month boundaries explicitly; do not rely on device locale defaults that change silently.
- A travel/time-zone change must not duplicate, erase or retroactively move source events.
- Use stable source IDs and deterministic tie-break ordering: event instant, source-type precedence defined centrally, then stable source ID. The precedence must be documented and tested.
- A record edit or deletion invalidates every dependent projection; recomputation must be idempotent.
- Archive hides a plant from active collection analytics by default but must not destroy its history. Restore makes it eligible again according to its current state; do not fabricate historical scheduled opportunities.
- Import/restore must preserve source identity and avoid duplicate derived counts. Rebuild projections from restored authoritative records.
- Corrections and backdated records may legitimately change historical derived results; the UI should make the selected period and current calculation clear.
- Do not persist derived totals as authoritative facts. If projections are cached for performance, they must be rebuildable and versioned against calculation rules.

## 8. UX and content requirements

- Separate care analytics, streaks and plant-health insights into clearly labelled sections; do not blend them into one composite score.
- Provide plant-level views first. Collection-level analytics must disclose scope and selected plants.
- Every chart has an accessible text/table alternative and a clear empty state.
- Use neutral labels such as “completed opportunities”, “skipped”, “deferred”, “not scheduled” and “records available”.
- Avoid judgemental labels, red failure states, guilt language, competitive rankings and celebratory prompts that imply extra care is desirable.
- Show the definition or an explanatory detail for every metric and streak.
- Garden Profile may display the Garden Care Streak as defined in §5.2.1.
- Plant Profile may display separately labelled Plant Care Streaks for individual tasks. Never present the Garden Care Streak as a plant-level metric or combine Plant Care Streak counts into it.
- Every chart/list item must navigate to the correct source record and plant.
- Sparse-data states explain what is and is not known, without manufacturing percentages or trends.
- Archived plant history is read-only and clearly identified.
- Support VoiceOver, Dynamic Type, reduced motion, sufficient contrast and offline use.

## 9. Privacy and pricing

Included in the local-first app. No account, network service, subscription or third-party analytics is required. Private notes and photos remain private and must not be copied into notifications or external analytics. No new permissions are required beyond those already used by source features.

## 10. Performance and reliability

- Profile realistic small, medium and large histories before choosing synchronous calculation versus cached projections.
- Initial plant summary should avoid blocking the main thread; long-history calculations must be bounded and cancellable.
- Cache invalidation must cover create, update, delete, archive, restore, import and source-contract migrations.
- A cache miss or corrupt projection must fall back to a deterministic rebuild from source records.
- Analytics must not delay or alter core care scheduling, reminders or one-tap completion.
- Define measured performance budgets after profiling; do not invent targets before baseline measurements.

## 11. Acceptance criteria

### Care analytics
- [ ] Each metric has a documented formula, denominator, period and source mapping.
- [ ] Scheduled and unscheduled care are distinguished.
- [ ] Disabled, paused and valid quiet-period occurrences are excluded from eligible denominators.
- [ ] Deferred/rescheduled occurrences are counted once at the authoritative due boundary.
- [ ] Skipped, completed and unresolved outcomes remain distinguishable.
- [ ] Zero/unknown denominators never render misleading percentages.
- [ ] Plant and collection scope is explicit; cross-plant leakage is impossible.
- [ ] Each displayed result can navigate to its source records.

### Streaks
- [ ] Plant Care Streaks remain scoped to one stable care-task identity; distinct tasks never share or inherit a Plant Care Streak.
- [ ] The Garden Care Streak is a separate calculation over all eligible scheduled-care opportunities across the active garden; it is never derived by summing or combining Plant Care Streak outputs.
- [ ] Garden Care Streak qualification uses the all-opportunities rule and local calendar-day period in §5.2.1.
- [ ] Pending, failed and neutral days follow the opportunity grace, cancellation, Quiet Period and archive rules in §5.2.1.
- [ ] Local day boundaries, 23/24/25-hour days, time-zone changes and DST are deterministic and tested.
- [ ] New plants/tasks do not create fabricated historical opportunities; coverage start is disclosed.
- [ ] Current and longest runs are traceable to source opportunities and local dates.
- [ ] Neither streak incentivises unnecessary or early care, or creates reminders, retention nudges, rewards, badges, targets, competition or streak-loss messaging.
- [ ] Neither streak is included in PRD-013 Weekly Garden Reflection.
- [ ] Source corrections and historical edits recompute results without fabricating events.

### Plant-health insights
- [ ] Every insight has explicit evidence references and a labelled evidence class.
- [ ] No diagnosis, health score, causal claim or unsupported trend is produced.
- [ ] Insufficient/conflicting evidence produces a neutral evidence-gap/inconclusive state.
- [ ] Photo/observation comparisons are date-labelled and source-traceable.
- [ ] Editing/deleting/archiving/restoring/importing evidence updates dependent insights.

### Platform and experience
- [ ] Offline, accessibility, archive, export/restore and privacy journeys pass.
- [ ] Projections rebuild deterministically after cache loss or migration.
- [ ] Long-history performance is measured on representative devices.
- [ ] Product/content review approves every generated insight template and metric label.

## 12. Delivery plan

Deliver in independently reviewable phases, with one coherent PRD and explicit dependency gates:

1. **Phase 0 — Contract and inventory:** Confirm source schemas and lifecycle semantics in PRD-022/023 and PRD-014/018/012; map fields and missing data; approve metric catalogue, time rules and insight evidence classes.
2. **Phase 1 — Plant Story foundation:** Build deterministic source aggregation, ordering, navigation and sparse-data states. No analytics scores or streak UI.
3. **Phase 2 — Care analytics:** Add plant-level activity summaries and eligible-opportunity metrics; add collection aggregation only after plant-level correctness and source coverage are proven.
4. **Phase 3 — Plant Care Streaks:** Add a separate calculator and history for each stable care-task identity. This remains separate from any garden-level calculation.
5. **Phase 3b — Garden Care Streak:** Add a separate pure calculator over all eligible garden opportunities, using the all-opportunities/local-calendar-day contract in §5.2.1. This is not an aggregation of Plant Care Streak counts and requires explicit pending/failed/neutral day handling plus DST/time-zone coverage.
6. **Phase 4 — Evidence-led plant insights:** Add approved deterministic templates over check-ins, journal/plant-change records and comparable Growth Review evidence. No AI interpretation.
7. **Phase 5 — Hardening and release:** Validate edits/deletes, time-zone changes, quiet periods, pause/disable, archive/restore, import/export, offline, accessibility and performance.

Each phase requires its own implementation issue or sub-issue with testable acceptance criteria. Do not start implementation until the product decisions in §13 are approved and the required source contracts are stable.

## 13. Product and technical decisions

### 13.1 Approved product decisions

The product defaults below are approved for this PRD:

1. **Primary experience:** Plant Story is the canonical full chronology; Plant Profile hosts compact summaries and entry points.
2. **Analytics scope:** Plant-level metrics ship first. Collection analytics follow after denominator and cross-plant semantics are validated.
3. **Completion rate:** Completed eligible opportunities divided by resolved eligible opportunities. Skipped and other final non-completion outcomes remain separately visible; unresolved opportunities are reported separately.
4. **Deferred care:** A deferred occurrence moves to its authoritative rescheduled due boundary and is counted once, never at both the original and new due dates.
5. **Plant Care Streak semantics:** Consecutive eligible opportunities for one individual care task, completed within the approved completion window. A late completion or definitively overdue unresolved opportunity interrupts that task's current run.
6. **Garden Care Streak semantics (approved 2026-11-26):** All eligible opportunities due on a local calendar day must be completed within their individual inclusive 24-hour grace windows for that day to qualify. Days with no eligible opportunities are neutral and skipped. A day remains pending until all opportunities resolve or expire. The current/longest Garden Care Streak is a run of qualifying scheduled-care days across all active garden plants; it is separate from Plant Care Streaks.
7. **Neutral intervals:** Disabled tasks, explicit pauses, valid quiet periods and periods when that task has no eligible care due neither advance nor break its Plant Care Streak. Garden Care Streak neutral days follow §5.2.1.
8. **Streak granularity:** Plant Care Streaks are per stable care-task identity. The separately approved Garden Care Streak is garden-wide and day-based; it is not a combined Plant Care Streak, score or sum of task counts.
9. **Health language:** Use “plant insights” / “evidence-led observations”, not definitive health conclusions. No diagnoses, health scores or causal claims.
10. **Evidence threshold:** A trend requires at least two comparable, dated observations of the same attribute. A single observation is a recorded observation, not a trend. Photo comparisons are user-directed and do not imply automated image interpretation.
11. **Periods:** Provide a user-selectable date range and clearly labelled local-calendar presets. The default preset is still a UX decision; evaluate a recent 30-local-calendar-day window as the leading option before locking it.
12. **Archived plants:** Exclude archived plants from active collection metrics by default; retain read-only individual history.

### 13.2 Technical decisions established from the current repository

The following findings were checked against the current `main` source and existing PRDs. They are implementation constraints, not assumptions that future lifecycle work has already shipped.

| Area | Current repository evidence | Decision for PRD-024 |
| --- | --- | --- |
| Care task | `CareTask` stores task ID, interval, current `dueDate`, enabled/reminder flags and plant relationship | Treat it as the recurring task definition and current schedule pointer; do not duplicate it |
| Care history | `CareEvent` stores stable event ID, task ID/title snapshot, completion instant, note and plant relationship | Treat it as immutable-in-meaning historical evidence, subject to the approved history-correction policy |
| Occurrence identity | No persisted scheduled-occurrence identity or skip/defer outcome is present in the current `CareTask`/`CareEvent` model | **Required upstream change in PRD-022:** introduce a stable occurrence identity and explicit lifecycle outcome before completion-rate or streak calculations ship |
| Recurrence | `CareRecorder.complete` advances `dueDate` from the actual completion timestamp plus interval; `CareSchedule` uses an injected/default `Calendar` | Preserve this existing recurrence contract; PRD-024 must not change schedule advancement |
| Pause | Current task pause is represented by `CareTask.isEnabled`; quiet periods are a separate PRD-020 capability and are not yet represented in the current model | Exclude disabled tasks. Quiet-period exclusion becomes active only when PRD-020 supplies persisted, auditable boundaries and affected-task scope |
| Observations | Current `JournalEntry` supports dated notes, photos, milestones and typed plant-change records | Use these as first-release evidence sources; do not pretend a separate `PlantCheckIn` model already exists |
| Check-ins | PRD-014 leaves the `JournalEntry` extension vs separate `PlantCheckIn` schema unresolved | Consume typed check-ins only after PRD-014 settles its schema and archive contract |
| Structured care outcomes | PRD-023 is the intended source for typed care observations; current `CareEvent` source does not yet expose those approved fields | Integrate only after PRD-023 schema and migration are approved; notes are not mined or reclassified as structured measurements |
| Archive | `JournalArchive` version 2 exports plants, journal entries, care tasks and care events, with stable IDs and optional extension keys | Do not export derived analytics/streak caches as authoritative data. Rebuild projections from source records after restore. Any new occurrence/outcome/quiet-period records require a versioned, backward-compatible archive extension |
| Persistence | App uses SwiftData locally, with isolated in-memory/temp stores in tests | Keep calculations local and offline; no remote service or third-party analytics |

### 13.3 Technical contracts approved for implementation planning

1. **Scheduled-opportunity identity dependency — approved 2026-11-25:** use a minimal persisted opportunity record with immutable UUID, stable CareTask/plant identity, immutable original `scheduledDueAt`, mutable authoritative `effectiveDueAt`, `open`/`completed`/`cancelled` state and optional linked CareEvent UUID. This is not a general-purpose occurrence engine. Explicit Next care edits cancel the superseded opportunity and create a replacement; disable/delete cancels an open opportunity. Quiet Period resume preserves identity and updates `effectiveDueAt` under PRD-020's calendar/DST contract. A due opportunity remains unresolved until the approved completion window expires. Skip/snooze/defer are excluded from the first release. V5 migration seeds only the current due opportunity for enabled, non-archived tasks; no earlier intervals are reconstructed and no CareEvents are backfilled. V6 migration adds `effectiveDueAt` to existing V5 opportunities using their `scheduledDueAt`, preserving opportunity IDs and original instants. The initial opportunity contract is tracked in #142; the effective-boundary and completion-window correction is tracked in #147.
2. **Backward compatibility:** Existing `CareEvent` records without an occurrence ID remain valid historical care events. They contribute to activity history but must not be retroactively assigned to a scheduled opportunity or included in completion-rate/streak denominators without reliable evidence.
3. **Eligible opportunity boundary — approved 2026-11-25:** An open opportunity becomes due/unresolved at its authoritative `effectiveDueAt`. The approved streak grace window is 24 hours: completion in the inclusive interval `[effectiveDueAt, effectiveDueAt + 24 hours]` qualifies as on-time for streak purposes. If still uncompleted after that deadline, the opportunity is definitively overdue and breaks that CareTask's current streak. The exact boundary is shared by analytics and streak calculations and must be centrally defined and tested. This window governs streak eligibility only; it does not prevent later care recording.
4. **Outcome mapping:** Completed requires an authoritative linked completion event. Care recorded after the 24-hour streak window remains linked to its opportunity and visible as a late completion, but it is not an on-time streak completion and cannot restore a broken streak. Do not report a late completed opportunity as unresolved. Skip/snooze/defer are excluded from the first release. An explicit Next care edit cancels the superseded open opportunity and creates a replacement. Disabled/cancelled and paused/quiet-period intervals are excluded according to lifecycle history. A due opportunity still within its grace window is unresolved, not definitively overdue.
5. **Quiet periods:** PRD-020 persists start/end (or open-ended) boundaries and selected-task scope. Preserve immutable original `scheduledDueAt`; on resume update mutable `effectiveDueAt` to the due instant reconstructed under PRD-020's approved calendar/DST rules. Preserve opportunity identity across the pause and exclude paused time. Do not infer a quiet period from task inactivity or a disabled flag.
6. **Calendar and time:** Persist source event/due instants as absolute `Date` values. Derive day/week/month buckets from an explicitly injected user calendar and time zone at calculation/presentation time. Do not rewrite source instants when the device time zone changes. Show the actual local date range and time-zone basis used.
7. **Week boundaries:** Use the user's configured/current calendar's week definition, injected into the calculator; never hard-code Monday/Sunday or rely on a hidden process-global calendar. Test DST transitions, travel/time-zone changes and calendar boundary changes.
8. **Calculation architecture:** Start with pure deterministic value-based calculators over fetched source snapshots. Keep SwiftData fetch/mutation at the persistence boundary and UI rendering thin. No separate analytics persistence model in the first implementation.
9. **Caching:** Add only if profiling on representative physical devices demonstrates a need. Any cache is disposable, versioned by calculation schema, invalidated by all source mutations and fully rebuildable. Cache loss must not affect correctness.
10. **Invalidation:** Recompute affected plant projections after source create/update/delete, task schedule changes, occurrence transitions, pause/quiet-period changes, archive/restore, import and schema migration. Collection summaries must also invalidate when membership changes.
11. **Historical corrections:** Backdated or corrected source records may revise derived historical results. Do not mutate the active task schedule as a side effect. Keep source correction history under PRD-011's policy.
12. **Plant scope:** Derive each plant's results only from records whose stable plant relationship matches that plant. Collection metrics aggregate already-validated plant-level inputs; no cross-plant event inference.
13. **Unknown types:** Preserve unknown raw values during archive/restore. Exclude unsupported types from typed metrics and show a neutral “other/unsupported record” timeline representation rather than guessing their meaning.
14. **Evidence model:** Represent each insight as a deterministic template/result with an explicit evidence class, source IDs, period, and explanatory copy key. Do not persist a free-form generated conclusion or run NLP/AI over notes/photos.
15. **Photo evidence:** Photos may be presented in a user-initiated, date-labelled comparison using PRD-012 capabilities. The app must not automatically infer symptoms, colour changes, disease or health from image pixels.
16. **Archive strategy:** Derived metrics and streaks are not exported. Source occurrence/outcome data required to reconstruct them must be included in a versioned archive extension and restored before projections rebuild.
17. **Performance:** Profile first. Set budgets from measured baseline for realistic history sizes and target devices. Never make the main-thread UI wait for unbounded full-history sorting or image decoding.

### 13.4 Remaining upstream decision gates

These cannot be honestly marked resolved by PRD-024 alone:

- **PRD-022:** the minimum scheduled-opportunity identity/lifecycle contract is approved on 2026-11-25 and implementation is tracked in issue #143. Skip/snooze/defer are explicitly excluded from the first release. The remaining gate is implementation plus migration/archive compatibility, not another product identity decision.
- **PRD-020:** exact quiet-period pause/resume policy, affected-task scope and persisted interval representation.
- **PRD-023:** final typed care-outcome fields, validation and archive representation.
- **PRD-014:** `JournalEntry` extension versus a dedicated `PlantCheckIn` model, plus its export/restore and evidence semantics.
- **PRD-012:** exact photo comparison contract and what provenance/metadata it exposes.
- **PRD-011:** correction/deletion audit semantics and whether prior source values remain available for audit.
- **Archive:** version bump/compatibility plan once the scheduled-opportunity identity and any required quiet-period source data are approved.
- **PRD-027:** permits private, descriptive Plant Care Streaks (per task) and the separately defined Garden Care Streak (garden-wide qualifying days). Neither is a retention mechanic; neither authorises gamification, nudges, rewards or social comparison.
- **PRD-013:** its Weekly Garden Reflection continues to exclude streaks and scores. PRD-024 must not add task streaks to that reflection.

These are dependency gates, not reasons to block the PRD document. Phase 0 must close them before implementation of the dependent capability begins. The PRD-027 cross-document conflict is resolved by the explicit per-task descriptive-history exception. The remaining implementation gates—especially PRD-022's scheduled-opportunity identity/lifecycle contract and archive compatibility—must still close before streak implementation.
 
## 14. Dependencies and delivery tracking

- **Care lifecycle:** [PRD-022 — Care Activity Lifecycle](PRD-022-care-activity-lifecycle.md). It remains the authority for task/occurrence/outcome lifecycle. PRD-024 derives analytics and streaks; it does not add gamification to the lifecycle engine.
- **Structured care outcomes:** [PRD-023 — Structured Care Outcomes](PRD-023-structured-care-outcomes.md). Supplies structured care evidence but does not itself establish plant health.
- **Plant observations/history:** [PRD-014 — Plant Check-ins](PRD-014-plant-check-ins.md), [PRD-018 — Plant Changes Timeline](PRD-018-plant-changes-timeline.md), JournalEntry and photo source contracts.
- **Visual history:** [PRD-012 — Growth Review](PRD-012-growth-review.md).
- **Reflection:** [PRD-013 — Weekly Garden Reflection](PRD-013-weekly-garden-reflection.md), which continues to exclude streaks and scores; do not add task streaks to the reflection.
- **Lifecycle strategy:** [PRD-027 — User Lifecycle & Meaningful Engagement](PRD-027-user-lifecycle-and-meaningful-engagement.md), updated to record the approved narrow exception for private, descriptive per-task streak histories. PRD-013 Weekly Garden Reflection remains streak-free.
- **Related proposals:** [#64 — Growth Review](https://github.com/melusi-k/Feed-Good/issues/64), [#65 — Weekly Garden Reflection](https://github.com/melusi-k/Feed-Good/issues/65), [#66 — Plant Check-ins](https://github.com/melusi-k/Feed-Good/issues/66), [#72 — Plant Changes Timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- **Implementation issue:** Scheduled-opportunity identity/lifecycle implementation is tracked in [issue #143](https://github.com/melusi-k/Feed-Good/issues/143). Plant Care Streaks and Garden Care Streak remain separate read-model/UI slices; Garden Care Streak requires its own implementation issue and test plan.
- **Implementation status:** Not started. This document records the expanded product and technical contract for review.


## 15. Scheduled-opportunity contract status — 2026-11-25

The PRD-022 identity/lifecycle contract is approved. The minimum persisted record has immutable opportunity UUID, CareTask UUID, plant ownership, immutable original `scheduledDueAt`, mutable `effectiveDueAt`, `open`/`completed`/`cancelled` state and optional CareEvent UUID. Passing `effectiveDueAt` makes an open opportunity due/unresolved; it becomes definitively overdue only after the approved PRD-024 completion window expires. V5 migration seeds at most one current open opportunity for each enabled, non-archived task with a valid due date; it does not reconstruct prior intervals or link historical CareEvents. Explicit Next care edits cancel/replace; disable/delete cancels; Quiet Period resume preserves opportunity identity and updates `effectiveDueAt` under PRD-020 while retaining original `scheduledDueAt`. Skip/snooze/defer are excluded. Existing CareEvents remain unlinked.

Implementation and source/archive compatibility are tracked in issue #143. PRD-024 scheduled-care analytics and private per-task streak UI remain blocked until that implementation is merged and verified. The recorded-care activity foundation in PR #140 remains complete and unchanged.

### Scheduled-opportunity boundary clarifications (approved 2026-11-25)

- **Migration start boundary:** Seed one current opportunity per enabled, non-archived task with a valid current due date during V5 migration. This preserves the in-flight schedule without reconstructing historical cycles. Existing CareEvents remain unlinked.
- **Due window:** An open opportunity is due/unresolved at `effectiveDueAt`; it is definitively overdue only after the approved completion window expires. Analytics and streak calculations must use the same boundary.
- **Explicit edits:** Since defer/snooze are excluded, an explicit Next care edit is a cancellation/replacement, not an in-place deferral.
- **Quiet Period:** `scheduledDueAt` remains immutable for audit. `effectiveDueAt` is updated to the resumed due instant under PRD-020's existing calendar/DST rules, preserving opportunity identity and excluding paused time.


## 16. Design extension — care consistency is not habit formation (2026-11-25)

### 16.1 Definitions

These concepts must remain separate in product language, data contracts and reporting:

| Concept | Product definition | What Feed Good can validly observe |
| --- | --- | --- |
| Care routine | A user-configured recurring care task for a particular plant, with its own stable identity and schedule | Task configuration, schedule and lifecycle |
| Care activity | A care action recorded by the user | Authoritative CareEvent and its source linkage |
| Consistency | How scheduled opportunities for one task are completed over a defined period | Eligible opportunities, on-time completions, completion rate and interruptions under the approved lifecycle contract |
| Plant Care Streak | A descriptive run of consecutive eligible opportunities for one task completed within the approved completion window | Current and longest per-task sequences |
| Garden Care Streak | A run of qualifying local calendar days across the active garden, where all eligible scheduled-care opportunities due that day are completed on time | Current and longest runs of qualifying scheduled-care days; not a measure of daily care or habit strength |
| Habit | A repeated behaviour that has become sufficiently automatic or integrated into a person's routine | Not directly observable from task completion, app opens or streak length alone |

A care task is a plant-care requirement, not proof of a human habit. Some healthy routines are intentionally infrequent or seasonal. The product must never imply that a longer streak, more frequent care or a higher completion count is inherently better.

### 16.2 Approved product decision

For this release, Feed Good measures **care activity and scheduled-care consistency**, not habit formation.

- Plant Care Streaks remain private, descriptive, task-scoped histories governed by §5.2.
- The Garden Care Streak is a separate private, descriptive garden-wide measure governed by §5.2.1 and the same authoritative opportunity lifecycle.
- Completion rate and other consistency measures remain descriptive operational metrics. They must disclose scope, period, numerator/denominator where applicable, eligibility rules and source coverage.
- A streak is one view of consecutive consistency; it is not a habit score, habit milestone, habit-strength proxy or success criterion.
- Do not introduce labels such as “habit formed”, “strong habit”, “habit health”, “habit score” or “habit strength” based solely on care records.
- Do not infer user motivation, effort, automaticity, commitment or intent from completed, late, cancelled or unresolved opportunities.
- Do not encourage additional or early care to preserve a streak. Plant need and the authoritative task schedule always take precedence.
- Existing CareEvents remain activity history only unless explicitly linked to a scheduled opportunity under the approved source contract. No historical habit or streak backfill is permitted.

### 16.3 Future discovery boundary

If the product later needs to understand whether a user has developed a habit, that is a separate research and product-design question—not an extension of the streak formula. It would require an explicit, voluntary user-level behaviour definition and a validated measurement approach (for example, a lightweight self-report of automaticity), with clear privacy, cadence, interpretation and opt-out decisions. It must not be inferred from plant-care completion data, and it is not authorised by this PRD.

### 16.4 Acceptance criteria for this extension

- [ ] Product copy and analytics distinguish care routine, activity, consistency, streak and habit.
- [ ] No habit-formation or habit-strength metric is calculated from streaks, opportunities, CareEvents or app engagement.
- [ ] Plant Care Streaks remain separate per-task histories and are not aggregated into a Garden Care Streak.
- [ ] The Garden Care Streak is calculated independently from eligible source opportunities using the approved all-opportunities/local-calendar-day contract.
- [ ] Consistency metrics disclose their period, scope, eligibility definition and denominator where applicable.
- [ ] No UX, notification or growth mechanic rewards unnecessary, early or excessive plant care.
- [ ] Any future habit research is separately scoped and requires explicit product approval before instrumentation or implementation.
