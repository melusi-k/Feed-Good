# PRD-024 — Care Analytics, Streaks and Plant Health Insights

**Status:** Product scope expanded; decision review required before implementation  
**Stage:** Product definition — care analytics, care-activity streaks and evidence-based plant insights  
**Priority:** Proposed P2 understanding and retention capability  
**Release:** Incremental, after the relevant source-record contracts are approved  
**Primary surfaces:** Plant Profile, User Profile streaks highlight, Care History, Plant Story and optional Insights/history

## 1. One-line goal

Help people understand what care they have recorded, recognise a sustainable rhythm of engagement, and make sense of a plant's documented history through transparent, evidence-backed insights—without grading the person, confusing activity with plant health, diagnosing a plant or inventing causality.

## 2. Product principles and boundaries

PRD-024 has three related but deliberately separate layers:

1. **Care performance analytics — what was recorded.** Summarise care events and, only where historical schedule evidence supports it, compare completions with eligible scheduled opportunities.
2. **Care-activity streaks — a gentle view of recorded rhythm.** Recognise repeated engagement without treating every calendar day as a care obligation or penalising quiet periods, disabled routines or plants that need infrequent care.
3. **Plant health insights — what the plant record supports.** Surface explicit observations, growth-review context and cautious, traceable conclusions only when there is enough relevant evidence.

These layers must not be collapsed into one score. In particular:
- Care activity is not plant health.
- A missed or overdue task is not evidence that a plant is unhealthy.
- A completion streak is not evidence that a plant is thriving.
- More photos, notes or check-ins do not automatically mean better care or better health.
- A lack of records means “not recorded” or “not enough information,” not “no progress,” “neglect” or poor health.

The app remains local-first. Derived values must be reproducible from current source records and explainable to the user.

## 3. Users and use cases

- A user wants to see which care actions they have recorded over a useful period.
- A user wants to understand whether their current care routine is being followed, but only when the app has reliable historical schedule data to make that comparison fair.
- A user wants recognition for a sustainable care rhythm without being expected to interact with the app every day, with current and longest recorded-care runs visible side by side.
- A user wants a quiet collection-wide streaks highlight on their User Profile, with clear wording that it describes recorded activity across plants rather than the health or care quality of every plant.
- A user wants to revisit a plant's observations, milestones, changes and care context in one coherent story.
- A user notices a possible issue and wants to understand which observations support it, what is still unknown and where the original records came from.
- A user has sparse history, an archived plant, a disabled routine or a Quiet Period and must receive an accurate, non-judgmental result.
- A user corrects or deletes a historical record and expects all affected summaries and insights to update.

## 4. Capability layers

### 4.1 Care performance analytics

**Purpose:** Describe recorded care activity and, where defensible, the relationship between recorded completions and scheduled care opportunities.

#### Initial metrics

| Metric | Definition | Required source | Presentation rule |
| --- | --- | --- | --- |
| Completed care actions | Count of eligible CareEvent records in the selected period | CareEvent.completedAt | Call these “recorded care actions,” not a health measure |
| Care by type | Count grouped by the event's task-title/kind snapshot where available | CareEvent; stable kind snapshot if introduced by an approved contract | Unknown or legacy kinds remain “Other/previously configured”; do not infer from title text |
| Plants receiving recorded care | Distinct plants with at least one eligible CareEvent in the period | CareEvent.plant identity | Count plants, not tasks; exclude archived plants only when the selected view explicitly filters them |
| Last recorded care | Most recent eligible CareEvent.completedAt for a plant and action | CareEvent | Label the action and exact date; never imply it is due or required |
| Recorded activity over time | Count of CareEvents grouped by user-local calendar week or month | CareEvent.completedAt | Use actual calendar boundaries, not rolling 7 × 24-hour buckets |
| Currently overdue routines | Count of enabled, active CareTasks whose due date is before today under CareSchedule calendar semantics | CareTask, Plant archive state, Quiet Period overlay | A current-state snapshot only; never present as historical overdue performance |
| Scheduled-opportunity adherence | Accepted completions divided by eligible scheduled opportunities in a defined period | Requires a trustworthy historical schedule/opportunity ledger or equivalent immutable schedule snapshots | Do not ship until the data contract can reconstruct the denominator without guessing |

#### Metric definitions and exclusions

- The default period is the current local calendar month, with explicit controls for a bounded period and “all recorded history.” The UI must always display the period and calendar context used.
- CareEvent is the source of truth for completed actions. A CareTask is a current routine definition, not a historical completion and not proof that a task was due in the past.
- Deleting a CareTask does not delete its CareEvent history. Historical event task IDs and title snapshots remain valid even if no current task matches them.
- A current CareTask.dueDate cannot be used to reconstruct every historical due date. Schedule edits, interval changes, task deletion, archive state and Quiet Period pause/resume can all change the schedule. Do not backfill historical opportunities from today's task settings.
- A completion is attributed to the calendar period containing CareEvent.completedAt, not the date the record was entered or edited. If a user corrects completedAt, recompute the affected period.
- If the event kind is not stored historically, do not infer it from mutable task state or free-form taskTitle. Use a neutral legacy/unknown grouping until an approved snapshot field exists.
- Current overdue counts are a point-in-time operational view, not a measure of past performance. Exclude archived plants, disabled tasks and tasks suppressed by an active Quiet Period; apply the same calendar semantics as CareSchedule.
- A task with a reminder disabled is still a task; reminder preference must not alter care metrics.
- Never treat an uncompleted task as a missed opportunity unless the app can prove it was enabled, due, eligible and not suppressed for that exact opportunity.
- Never compare people, plants or collections with rankings, leaderboards or normative “good/bad” thresholds.
- Do not use percentages when the denominator is absent, incomplete, inferred or not user-understandable.

#### Scheduled adherence: committed capability with a required data-contract phase

Scheduled adherence is in the approved product scope. It is not safe to calculate from the current CareTask alone, so implementation must first define and build a historical opportunity record/ledger (or an equivalently reliable immutable schedule-snapshot design). The contract must specify how the app records each eligible scheduled opportunity across:
- Task creation, enable/disable, interval and due-date edits.
- Completion, late completion, backdated completion, correction and deletion.
- Task deletion while retaining CareEvent history.
- Plant archive/restore and hard deletion.
- Quiet Period scheduling, activation, completion while paused, cancellation and resume.
- Calendar/time-zone changes and daylight-saving transitions.
- Imported archives, legacy records and missing historical schedule data.

PRD-022 explicitly avoids a general persisted CareOccurrence model unless a concrete requirement proves it necessary. This PRD now establishes scheduled adherence as a concrete product requirement, but does not prescribe the CareOccurrence name or implementation. The Phase 0 technical design must compare immutable schedule snapshots, a bounded opportunity ledger and other migration-safe approaches, then document the selected model and its interaction with PRD-022 before implementation. Adherence percentages and historical missed-opportunity counts may ship only after that model is implemented, migrated safely and validated against the edge cases above.

### 4.2 Care-activity streaks

**Purpose:** Offer a positive, optional recognition of recorded care rhythm—not a compliance system.

#### First supported concept: recorded-care weeks

- A **recorded-care week** is a user-local civil-calendar week containing at least one eligible CareEvent for the selected plant or selected collection.
- A **care-activity run** is the number of consecutive recorded-care weeks ending in the most recent recorded-care week.
- The UI must say “recorded-care weeks” or “care activity,” not “perfect weeks,” “care compliance” or “plant health streak.”
- The current week may be in progress. It counts once a qualifying event exists; it is not declared broken while the week is still underway.
- A run stops being current after one completed week with no recorded care: the run ends at its most recent recorded-care week and becomes historical. It then appears only in the longest-run reference until a new recorded-care week begins a new current run.
- A week with no CareEvent is simply a week with no recorded care. Do not show failure language, red states, loss animations or negative notifications.
- Show the current recorded-care run and the longest historical recorded-care run side by side. Give the current run visual priority; present the longest run as a quiet historical reference, never as a target or competitive achievement.
- On Plant Profile, show the per-plant current and longest runs. On User Profile, show a compact collection-wide streaks highlight, with a route to the fuller history. Label it clearly as recorded care activity across the selected plant collection; it must not imply that every plant received care.

#### Eligibility and edge cases

- Count only persisted CareEvent records associated with the selected plant. Collection totals must deduplicate plant identities and must not imply that each plant received care.
- Use the user's current local civil calendar and a documented first-weekday/locale rule. Recompute week grouping when the device time zone or calendar configuration changes; do not use fixed elapsed-second windows.
- A completion belongs to the week containing its current completedAt value. A history correction can move it between weeks and must recompute the run.
- Deleting an event can remove the only qualifying event in a week and therefore change the run. This is a truthful projection of current history, not a penalty animation.
- A Quiet Period does not create care events and does not itself count as a recorded-care week. Equally, it must never be described as a missed week or failure. Where the UI explains a gap, show the recorded Quiet Period context if available and permitted by the user's view.
- Disabled tasks, reminder settings, due dates and task intervals do not alter this event-based metric. This is intentional: the metric describes recorded activity only.
- Archived plants remain available in historical views; distinguish archived from active plants and do not include archived plants in a default active-collection summary unless the user chooses to include them.
- A newly created plant with no events has “No care activity recorded yet,” not a zero-day streak or a warning.
- Imported legacy events count only when their plant relationship and completion date validate. Unknown task IDs do not invalidate an otherwise valid CareEvent.
- If a record has an invalid or unavailable timestamp, exclude it from the streak and surface a data-integrity state where appropriate; never silently assign it to the current week.

#### Explicitly deferred streak types

- Consecutive daily streaks are out of scope. Most plants do not require daily care, and daily streaks reward app interaction rather than appropriate plant care.
- Scheduled-opportunity streaks (for example, “completed every eligible watering”) are deferred until the historical opportunity contract in §4.1 is approved and implemented.
- Streak freezes, repairs, points, badges, leaderboards, push notifications and loss-aversion mechanics are out of scope.
- Do not invent an “ideal” weekly frequency per species or care type. A recorded-care week is a descriptive unit, not a recommendation.

### 4.3 Evidence-based plant health insights

**Purpose:** Help a user understand documented plant observations and context, without diagnosis or unsupported biological conclusions.

#### Evidence hierarchy

Every insight must identify which evidence it uses and distinguish these categories:

1. **User-recorded fact:** a CareEvent, typed care outcome (only after PRD-023 is approved and implemented), JournalEntry, explicit milestone, explicit PlantChangeKind or PlantCheckIn.
2. **User-described context:** plant species, growing environment and light condition as entered by the user. These may be incomplete, stale or unknown and must be labelled as user-provided context.
3. **Derived observation:** a deterministic statement calculated from one or more records, such as “A flowering milestone was recorded on 4 November.” It must be possible to navigate to the exact source record(s).
4. **Reviewed educational guidance:** a separate, curated content source with an identified editorial owner, provenance and review date. PRD-014's safety and editorial gate applies.
5. **Interpretation:** a cautious statement that connects evidence only where the relationship is explicitly supported by an approved rule and reviewed content. It must disclose the evidence and limitations.

The first release may safely provide layers 1–3. Layer 4 requires PRD-014's editorial/safety ownership and provenance. Layer 5 requires a separately reviewed evidence rule; it is not automatically authorised by this PRD.

#### Supported insight families

| Insight family | Safe first-slice behavior | Evidence requirement |
| --- | --- | --- |
| Recorded milestones | Summarise explicitly selected milestones such as new leaf, flowering, repotting or recovery | JournalEntry milestone snapshot and source route |
| Explicit plant changes | Show moved location, repotting, pot/soil change or grow-light change as user-recorded context | JournalEntry.changeKindRaw and source route |
| Observation history | Summarise typed observations and user notes without interpreting symptoms | PRD-014 check-in contract or JournalEntry source |
| Growth review context | Let users compare dated source photos and their notes; do not measure growth or infer health from pixels | PRD-012 eligible JournalEntry photos |
| Care context | Show which care actions were recorded before/after an observation, with dates and neutral ordering | CareEvent and observation source records |
| Evidence gaps | Say “No recent observations recorded” or “Not enough information to summarise this period” | Absence of eligible records within an explicitly displayed period |

Care events and later observations may be displayed together chronologically, but proximity in time is not evidence that one caused the other. Never write “watering improved the plant,” “repotting caused yellowing” or equivalent causal language from chronology alone.

#### Conclusion policy

- An insight must be phrased as a statement about recorded evidence, not a diagnosis. Prefer “You recorded yellow leaves on 12 May” to “Your plant has a nutrient deficiency.”
- Any interpretation must state the supporting observation(s), the date(s), the relevant source and material uncertainty. The user must be able to open each source.
- If evidence is sparse, contradictory, stale or outside the supported scope, return “Not enough information” or show the source records without a conclusion.
- Absence of a symptom record is not evidence that the symptom is absent.
- A recovery milestone is the user's chosen label, not independent proof of recovery or a verified clinical outcome.
- A photo is a private user record. No visual diagnosis, automatic symptom extraction, image scoring or pixel-based growth conclusion is permitted.
- Free-form journal notes are not mined for symptoms, sentiment, intent or health conclusions in this release.
- Do not infer plant health from care frequency, completion rates, overdue counts, streaks, number of photos, number of notes, reminder use or app engagement.
- Do not prescribe treatment, fertiliser, watering frequency or schedule changes from derived insights.
- Do not use numerical health scores, red/amber/green health grades, risk labels, rankings or a single composite “plant health” result.
- Do not present confidence percentages. If an evidence-sufficiency label is needed, use plain-language states such as “Recorded evidence available,” “Limited records” and “Not enough information,” with clear definitions and no implication of biological certainty.

## 5. Shared time, period and calculation contract

- All user-facing periods use local civil-calendar boundaries, not fixed-duration seconds.
- Every chart, count and streak must show its selected period and use a consistent calendar/time-zone context for that calculation.
- Use calendar arithmetic for day/week/month grouping and the app's established CareSchedule semantics for current due state. Daylight-saving transitions must not create duplicate or missing calendar days.
- If the device time zone changes, historical event instants remain unchanged; their local display/grouping may change. Recompute derived period grouping using the current local calendar and explain the selected period.
- Store source timestamps as instants. Do not rewrite historical timestamps merely because the user changes time zone.
- Equal-timestamp timeline ordering follows the existing Plant Story contract: newest first, then namespaced stable source ID ascending. If a new source type is introduced, define its namespace before implementation.
- A derived metric must have a documented input set, inclusion/exclusion predicate, grouping calendar, formula and empty-state result. Tests must use fixed clocks/calendars rather than wall-clock assumptions.
- Never round a count or fabricate missing timestamps. Percentages, if ever approved, must expose numerator and denominator and handle a zero denominator as “Not available,” never 0%.

## 6. Source records, ownership and dependencies

PRD-024 is a read-only consumer of source records. It must not mutate care routines, care events, journal entries, plant observations or plant-change records.

| Source | Intended use | Dependency / limitation |
| --- | --- | --- |
| CareTask | Current enabled state, interval and current due state | Not a historical schedule ledger; current state cannot reconstruct past opportunities |
| CareEvent | Completed-care history and event-based activity | Current model snapshots task ID/title and completion date; kind/outcome history may be limited |
| QuietPeriod and task snapshots | Explain current/historical pause context where available | Follow PRD-020/PRD-022 approved lifecycle, archive and migration semantics; a pause is not a care completion |
| JournalEntry | Notes, photos and explicit milestones | Use existing source IDs and local media policy |
| JournalEntry.changeKindRaw | Explicit plant-change context | PRD-018's typed JournalEntry contract; never infer a change from a note |
| PlantCheckIn | Structured user observations | PRD-014 model decision and editorial/safety gate are still prerequisites; do not assume a separate model already exists |
| PRD-023 structured outcomes | Optional soil observations, quantities and other approved care context | PRD-023 remains a product/model decision dependency until implemented; missing values mean “not recorded” |
| Plant | Plant identity, user-provided species/environment/light and archive state | Context can be unspecified or stale; do not treat it as verified sensor data |
| Growth Review | Dated photo comparison and source navigation | PRD-012; no computer vision or biological inference |

The app currently has CareTask and CareEvent as distinct records. CareEvent retains a task ID/title snapshot and completion timestamp; deleting a routine does not erase the event history. JournalEntry supports explicit milestone and change-kind values. PRD-014 has not yet committed to a concrete check-in model. PRD-023 has not yet committed its structured outcome model. Implementation must re-check these source contracts against main before adding dependencies.

## 7. User experience and surfaces

- **Plant Profile:** compact per-plant care activity summary, showing current and longest recorded-care runs side by side, plus links to Plant Story / Growth Review.
- **User Profile:** a quiet collection-wide streaks highlight showing current and longest recorded-care runs across the user's selected plant collection, with explicit scope and a link to the fuller streak history. This is a descriptive activity summary, not a collection health or care-quality score.
- **Care History:** period-filtered recorded-care counts and action breakdown. Current overdue state, if shown, is visually and semantically separate from historical metrics.
- **Plant Story:** one chronological source timeline, with source-specific labels and links. Do not create a competing duplicate history.
- **Insights section:** evidence-backed summaries, each with a date range, evidence label and source navigation.
- **Optional Today reflection:** a quiet route to a weekly look-back; follow PRD-013's opt-in, non-interruptive tone. No push notification or forced card.
- **Empty and sparse states:** distinguish “no records in this period,” “not enough information,” “feature/source not available yet” and “archived plant.”
- **Archived plants:** historical care and insight views are read-only. Never show active overdue tasks or imply that an archived routine remains due.
- **Collection view:** Phase 1 remains per-plant for detailed analytics. Include the approved compact collection-wide streaks highlight on User Profile in the initial streak phase. Deeper collection-wide metric totals, trends and breakdowns remain a later phase; when introduced, present aggregate counts with explicit plant scope and period. Do not rank plants or imply that plants receiving more care are healthier.

No new top-level navigation destination is approved by this PRD. Prefer integration into existing Plant Profile, Care History and Plant Story surfaces.

## 8. Privacy, safety and accessibility

- All processing is on-device and offline-capable. No remote analytics, account, telemetry or third-party processing is introduced.
- Notes, photos and check-in details remain private. Do not place their content in notifications, logs or analytics.
- Every displayed metric or insight can be traced to source records; every source link opens the correct plant and record.
- Plant isolation is mandatory across every query, chart, calculation and navigation action.
- Respect archive, restore, hard-delete and export/import ownership contracts. A derived projection must not resurrect deleted records or retain stale references.
- Unknown future enum values must not crash the view or be relabelled as a known value. Use a neutral fallback and preserve the source record.
- Use accessible chart alternatives and VoiceOver descriptions that convey labels and values without relying on colour.
- Support Dynamic Type, light/dark appearance, reduced motion and supported iPhone widths.
- Do not use red/green colour as the sole indication of activity or evidence state. Avoid celebratory animation that implies a biological result.

## 9. Data integrity and derived calculation behavior

- Source records remain authoritative. Do not persist duplicate CareEvent, JournalEntry or PlantChange rows for analytics.
- Calculate derived values from the current source records. A bounded in-memory/cache optimization may be considered only after profiling; it must be disposable, invalidated on every relevant source mutation and never become a second source of truth.
- Recompute when a relevant source record is created, edited, corrected, deleted, imported, restored or its owning plant is archived/restored.
- A care event correction changes its period attribution and any affected activity-week grouping. It must not change CareTask due date or interval.
- A care event deletion removes only that event from derived calculations. It must not mutate a task or unrelated history.
- JournalEntry milestone/change edits or deletion update only the corresponding insights and story projection.
- Archived plants remain available in historical views but are excluded from active-collection snapshots by default.
- Import/restore must preserve source IDs, plant relationships, timestamps and supported raw enum values. Invalid ownership/reference data must follow the archive's established atomic validation behavior.
- No insight may be retained if its source records no longer exist. If a source is temporarily unavailable, show a neutral unavailable state rather than stale content.

## 10. Out of scope

- Plant diagnosis, disease/pest identification, treatment prescriptions or guaranteed recovery claims.
- Numerical health scores, health grades, risk labels, rankings, leaderboards or collection performance grades.
- AI interpretation of photos or free-form journal text; automated symptom extraction or sentiment analysis.
- Causal inference between care actions, plant changes, environmental context and later observations.
- Daily app-use streaks, consecutive daily care expectations, streak freezes/repairs, loss-aversion mechanics or punitive notifications.
- Scheduled-care adherence percentages or historical missed-opportunity counts before the approved historical opportunity contract is implemented and validated. Building that contract and the supporting data model is in scope; publishing unvalidated metrics is not.
- Automatic care schedule changes, reminder changes or treatment recommendations.
- Remote analytics, cloud processing, social comparison or network-dependent insights.
- A duplicate analytics database, a second care ledger, a second journal/photo library or a competing plant timeline.

## 11. Launch and delivery plan

### Phase 0 — Product and source contract

1. Approve the three-layer separation and the explicit non-equivalence of care activity and plant health.
2. Confirm the first-slice metrics and period defaults.
3. Confirm whether recorded-care weeks are an acceptable descriptive streak, including wording and opt-in placement.
4. Review CareTask, CareEvent, QuietPeriod, JournalEntry and archive contracts on the implementation branch.
5. Confirm the historical scheduled-opportunity data contract as a committed requirement. Compare immutable schedule snapshots, a bounded opportunity ledger and other migration-safe approaches; align the selected model with PRD-022 rather than assuming a CareOccurrence model by name.
6. Confirm the PRD-014 observation model and safety/editorial ownership; confirm the PRD-023 outcome field/model contract before consuming either.

### Phase 1 — Care activity analytics and source timeline

1. Implement completed-action counts, action breakdown where historical kind is reliable, distinct plants receiving recorded care and last-recorded-care summaries.
2. Add bounded period filters using local calendar semantics.
3. Keep current overdue task count, if included, separate from historical activity.
4. Integrate with existing Plant Story/Care History; no duplicate ledger.
5. Add deterministic projection, edit/delete, archive/restore, import and plant-isolation tests.
6. Validate sparse/empty states and accessibility on device.

### Phase 2 — Recorded-care weeks

1. Implement recorded-care week grouping and current run using the approved local calendar contract.
2. Add neutral copy, no-loss states and source navigation to the contributing CareEvents.
3. Test week boundaries, first weekday, time-zone changes, DST, backdated/corrected/deleted events, archived plants and imported history.
4. Confirm the UI does not imply daily care, schedule adherence or plant health.

### Phase 3 — Evidence-backed plant insights

1. Begin with explicit milestones, plant changes and dated observation/care context.
2. Add Plant Check-ins only after PRD-014's model, editorial owner, provenance and review process are approved.
3. Add structured care outcomes only after PRD-023's model, validation and archive behavior are approved.
4. Permit curated interpretation only after a separate content/evidence review defines allowed inputs, wording, uncertainty and source provenance.
5. Test unsupported, sparse, contradictory, stale and unknown evidence paths; verify every claim's source links.

### Phase 4 — Historical scheduled opportunities and adherence

1. Design and approve the historical scheduled-opportunity contract as part of Phase 0, then implement the selected migration-safe model after the source lifecycle is agreed.
2. Compare immutable schedule snapshots and a bounded opportunity ledger against PRD-022's current data-model constraints; record why the selected approach is the minimum reliable solution.
3. Validate Quiet Periods, schedule edits, deleted tasks, archives, imports, time zones, DST and historical corrections before exposing adherence.
4. Define numerator, denominator, late-completion/grace semantics, eligibility rules and user-facing labels from the approved contract.
5. Ship adherence only when opportunity history is complete for the displayed period. Legacy periods without sufficient history must show “Not enough historical schedule data,” not a fabricated percentage or missed-care count.

## 12. Acceptance criteria

### Care analytics

- Every displayed count matches the source records and selected plant/period.
- The period and local-calendar semantics are visible and deterministic.
- Legacy or unknown task kinds are not guessed from mutable task titles.
- Current overdue state is not presented as historical missed care.
- No adherence percentage appears without a complete, defensible opportunity denominator. Once the historical opportunity model is shipped, each displayed percentage exposes its eligible opportunity and completion counts, and excludes periods with incomplete history.
- Editing/deleting a source event updates every affected metric without changing the active routine.

### Streaks

- The first streak is explicitly a recorded-care-week run, not a daily or schedule-compliance streak.
- Plant Profile shows current and longest runs side by side; User Profile shows a clearly scoped collection-wide streaks highlight.
- The current incomplete week is not prematurely treated as broken.
- A week with no event produces neutral language only.
- Quiet Periods, disabled routines and reminder settings do not create fake events or punitive messaging.
- Corrections/deletions, calendar changes, archive/restore and imports produce deterministic results.

### Plant insights

- Each insight names or links to its supporting source record(s).
- User-recorded observations are distinguished from app-derived statements and curated guidance.
- No diagnosis, causal claim, numerical health score or treatment instruction is produced.
- Sparse, contradictory, stale or unsupported evidence returns a neutral insufficient-evidence state.
- Photos and free-form notes are not automatically interpreted.
- Care activity and streak values are never used as plant-health evidence.

### Cross-cutting

- No duplicate source ledger or analytics database is introduced.
- Plant isolation, offline behavior, privacy, archive/export compatibility and accessibility pass.
- Projection tests cover empty, sparse, dense, edited, deleted, imported, archived and restored histories.
- Product/editorial review approves all user-facing labels and insight copy before release.

## 13. Capability evaluation

| Capability | Evaluation method | Ship threshold |
| --- | --- | --- |
| Metric correctness | Fixed-clock/calendar projection tests against source fixtures | All inclusion, exclusion, boundary and correction tests pass |
| Traceability | UI navigation tests for each displayed metric/insight | Every displayed item opens the correct plant/source |
| Streak comprehension | Usability review of recorded-care-week wording | Users understand it is recorded activity, not daily care or health |
| Evidence quality | Editorial review of every shipped insight template | Every claim has an explicit evidence rule and source |
| Safety | Adversarial content tests for causal/diagnostic/score language | No unsupported diagnosis, causality or health grading |
| Data integrity | Edit/delete/archive/import/restore tests | No stale projections or cross-plant leakage |
| Offline and accessibility | Device/UI verification, VoiceOver and Dynamic Type | Core journeys work offline and accessibly |

## 14. Decisions and open questions

These are the remaining product decisions; source-record safety rules above are constraints, not open questions.

All six product decisions have been made and are locked for this scope:

| Decision | Locked direction | Product implications |
| --- | --- | --- |
| Recorded-care week presentation | **Current and longest runs side by side** | Show both on Plant Profile and in the relevant history; give the current run priority and keep the longest run as a neutral historical reference. |
| Streak placement | **Plant Profile, User Profile and optional deeper history** | Plant Profile gets a per-plant summary. User Profile gets a collection-wide streaks highlight. A fuller history remains optional; no push notifications or pressure-based prompts. |
| Collection analytics | **Phased: per-plant detail first, collection summary included for streaks** | Detailed care analytics begin per plant. The User Profile streaks highlight is included; deeper collection-wide totals, trends and breakdowns follow later. |
| Default analytics period | **Current local calendar month** | The initial analytics view uses the current local calendar month, with the period clearly displayed. |
| Health insight scope | **Descriptive first; curated interpretations later** | First release reports source-linked observations and milestones. Curated educational interpretations require a separate evidence, editorial and safety review. |
| Scheduled-care adherence | **Build the historical opportunity data model** | A migration-safe historical opportunity contract and supporting model are in scope. Adherence metrics ship only after completeness, eligibility and lifecycle behavior are validated. |

These decisions replace the former open questions and recommendations. Remaining engineering choices—especially the exact historical opportunity representation—are implementation design work under the approved product requirement, not unresolved product scope.

## 15. Replaces

PRD-024 brings together the useful plant-level understanding currently spread across Care History, Plant Story, Growth Review, Plant Check-ins and Weekly Garden Reflection. It does not replace those source capabilities, the care routine, the Plant Journal or the Plant Care Guide.

## 16. Delivery tracking

- **Implementation issue:** Not created. Create only after the first-slice scope and relevant product/technical decisions are approved.
- **Foundations:** [PRD-012 — Growth Review](PRD-012-growth-review.md), [PRD-013 — Weekly Garden Reflection](PRD-013-weekly-garden-reflection.md), [PRD-014 — Plant Check-ins](PRD-014-plant-check-ins.md), [PRD-018 — Plant Changes Timeline](PRD-018-plant-changes-timeline.md).
- **Care data dependencies:** [PRD-022 — Care Activity Lifecycle](PRD-022-care-activity-lifecycle.md), [PRD-023 — Structured Care Outcomes](PRD-023-structured-care-outcomes.md), [PRD-020 — Seasonal and Quiet Periods](PRD-020-seasonal-quiet-periods.md).
- **Related proposals:** [#64 — Growth Review](https://github.com/melusi-k/Feed-Good/issues/64), [#65 — Weekly Garden Reflection](https://github.com/melusi-k/Feed-Good/issues/65), [#66 — Plant Check-ins](https://github.com/melusi-k/Feed-Good/issues/66), [#72 — Plant Changes Timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- **Dependency direction:** PRD-024 consumes source records and approved outcomes; it does not own or mutate them. Scheduled adherence remains gated by a separate historical opportunity contract.
- **Implementation status:** Not started. This document records product intent and staged delivery only.
