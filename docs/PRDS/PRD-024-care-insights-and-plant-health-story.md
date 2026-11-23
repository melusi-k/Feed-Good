# PRD-024 — Care Analytics, Streaks & Plant Health Insights

**Status:** Expanded draft for product and technical decision review  
**Stage:** 3 — Care understanding, consistency and plant-health evidence  
**Priority:** Proposed P2 capability  
**Release:** Incremental delivery after the source-record contracts in PRD-022, PRD-023 and relevant plant-history foundations are stable  
**Primary surfaces:** Plant Profile, Plant Story, Growth Review and Today  
**Data posture:** Local-first, derived from authoritative user records; no duplicate care ledger

## 1. One-line goal

Help people understand how they care for their plants and what has been happening to each plant by turning existing care records, observations and visual history into transparent analytics, fair consistency streaks and carefully qualified plant-health insights—without rewarding unnecessary care, shaming users, diagnosing disease or claiming unsupported causality.

## 2. Problem and intended outcomes

Care information is currently distributed across schedules, care outcomes, check-ins, journal entries, plant changes and photos. Users need to answer three different questions:

1. **Care activity:** What care has been planned and recorded, and how has that pattern changed over time?
2. **Care consistency:** Have eligible care commitments been kept over time, without counting periods when care was not due or was intentionally paused?
3. **Plant story and health evidence:** What has the user observed about this plant, what has visibly changed, and what can reasonably be said from the available evidence?

The product must keep these questions distinct. A care metric is not a plant-health measurement. A streak is not a judgement of a user's commitment or a reason to perform unnecessary interventions. An observation is not a diagnosis.

Success means users can understand their own records, spot meaningful changes, and navigate from every displayed result to the records that support it.

## 3. Users and use cases

- Understand the care history and activity pattern for one plant or a selected collection.
- See whether scheduled care is being completed, deferred, skipped or left unresolved, with each outcome represented honestly.
- Recognise periods of consistent completion without being penalised for disabled tasks, valid pauses, quiet periods or times when no care was due.
- Review current and longest eligible care streaks and meaningful milestones.
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

### 5.2 Care consistency streaks

Provide a derived consistency view for a plant and optionally for a collection, based on eligible scheduled care opportunities—not raw event volume.

Initial product contract:

- A streak is a sequence of consecutive eligible care opportunities that received an authoritative completed outcome within the permitted completion window defined by the occurrence contract.
- The streak advances only when an eligible opportunity is completed.
- A final skipped outcome breaks the current streak but remains visible as a skip; it does not erase historical streak records.
- An unresolved eligible opportunity breaks the current streak only after its due/completion window has definitively elapsed under the agreed local-time contract.
- A deferred/rescheduled occurrence follows its new authoritative due boundary and is counted once.
- Disabled tasks, explicit task pauses, valid quiet periods and periods in which no care is due are neutral: they neither advance nor break a streak.
- Editing a task interval or due date must follow the schedule lifecycle contract. Do not retroactively rewrite a streak as if a care action happened.
- A correction to a care event updates the derived streak according to the source correction history; preserve an auditable history of the corrected source record, not a fabricated streak event.
- A streak must never encourage users to perform care earlier or more often than the plant's schedule requires.

**Streak outputs**

- Current streak, if one exists, with its start date and count of eligible opportunities.
- Longest historical streak, with its date range and eligible-opportunity count.
- Recent streak history, including interruptions and neutral periods.
- Milestones only where they are a by-product of the same fair calculation; no rewards that encourage extra care.

**Collection consistency**

Collection-level consistency must not require every plant to have care due on the same day. It is derived from the union of eligible opportunities across the selected active plants, and advances only when all eligible opportunities in the relevant bounded period are completed. Periods with no eligible opportunities are neutral and do not create artificial progress. The UI must disclose the selected plant set and period. Archived plants are excluded from the active collection by default, with historical results still available through the archived plant's own story.

If the union-of-opportunities model proves confusing or misleading in usability testing, ship plant-level streaks first and defer collection streaks rather than substituting a raw activity streak.

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

- PRD-022 care task, occurrence, pause/quiet-period and lifecycle state.
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
- [ ] Streaks use eligible scheduled opportunities, not raw event count.
- [ ] Completed, skipped, deferred, unresolved, disabled, paused and no-due periods follow the contract in §5.2.
- [ ] A streak cannot incentivise unnecessary or early care.
- [ ] Current and longest streaks are deterministic and traceable to source occurrences.
- [ ] Source corrections and historical edits recompute results without fabricating events.
- [ ] Collection streaks are deferred if the union-of-opportunities model is not understandable in usability testing.

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
4. **Phase 3 — Plant care streaks:** Add the plant-level streak calculator and historical view; collection consistency remains gated by usability and calculation validation.
5. **Phase 4 — Evidence-led plant insights:** Add approved deterministic templates over check-ins, journal/plant-change records and comparable Growth Review evidence. No AI interpretation.
6. **Phase 5 — Hardening and release:** Validate edits/deletes, time-zone changes, quiet periods, pause/disable, archive/restore, import/export, offline, accessibility and performance.

Each phase requires its own implementation issue or sub-issue with testable acceptance criteria. Do not start implementation until the product decisions in §13 are approved and the required source contracts are stable.

## 13. Product and technical decisions required

The following are proposed defaults for review, not silently finalised decisions.

### Product decisions

1. **Primary experience:** Proposed: Plant Story is the canonical timeline; Plant Profile hosts compact summaries and entry points. Confirm.
2. **Analytics scope:** Proposed: ship plant-level metrics first; collection analytics follow once denominator and cross-plant semantics are validated. Confirm.
3. **Completion rate:** Proposed: completed ÷ resolved eligible opportunities (completed + skipped + any other final non-completion outcome), with unresolved shown separately. Confirm whether deferred occurrences are excluded until their new due boundary.
4. **Streak semantics:** Proposed: consecutive eligible opportunities completed within the allowed window; skip or definitively overdue breaks; disabled/paused/quiet/no-due intervals are neutral. Confirm.
5. **Collection streak:** Proposed: defer from first release unless usability testing validates the union-of-eligible-opportunities model. Confirm.
6. **Health insight language:** Proposed: “evidence-led plant insights” rather than definitive “health conclusions”; no diagnoses, scores or causal claims. Confirm.
7. **Minimum evidence:** Proposed: no trend from a single record; require at least two comparable, dated observations for a basic change statement, with stronger thresholds for stronger language. Confirm threshold and whether photo comparisons require Growth Review's existing comparison contract.
8. **Period selection:** Proposed: user-selectable date range plus clearly labelled local-calendar presets. Confirm presets and default range.
9. **Archived plants:** Proposed: exclude from active collection analytics by default; retain read-only individual history. Confirm.

### Technical decisions

10. **Source-of-truth mapping:** Confirm exact persisted models/fields and stable IDs for care tasks, occurrences, care events, outcomes, check-ins, journal entries, plant changes and photos.
11. **Eligible occurrence boundary:** Confirm the authoritative due timestamp, completion window/grace period, and when an unresolved occurrence becomes definitively overdue for analytics/streak calculations.
12. **Outcome semantics:** Confirm how skipped, deferred, rescheduled, cancelled, disabled and paused states are represented and whether lifecycle history is available for historical reconstruction.
13. **Quiet-period and pause integration:** Confirm how PRD-020 quiet periods and task pauses alter eligible occurrences, including edits made during an active quiet period.
14. **Time-zone/calendar contract:** Confirm canonical instant storage, user time-zone source, day/week/month boundaries and behavior when the user travels or changes time zone.
15. **Projection strategy:** Proposed: pure deterministic calculators over source records first; introduce rebuildable versioned caches only if profiling demonstrates a need. Confirm.
16. **Invalidation contract:** Confirm event/change hooks for create, update, delete, archive, restore, import and migrations.
17. **Historical corrections:** Confirm whether corrected/backdated source records may revise past metrics and how audit/history is surfaced.
18. **Collection membership:** Confirm active plant selection rules, treatment of archived plants, and behavior when plants are added/removed from a selected collection.
19. **Unknown record types:** Confirm safe timeline fallback and whether unknown types are excluded from specific metrics with an explicit count.
20. **Performance budgets:** Set budgets after profiling representative histories and physical devices; do not guess targets.
21. **Migration/export:** Confirm whether projections are omitted and rebuilt on restore/export, and how calculation-version changes trigger rebuilds.

## 14. Dependencies and delivery tracking

- **Care lifecycle:** [PRD-022 — Care Activity Lifecycle](PRD-022-care-activity-lifecycle.md). It remains the authority for task/occurrence/outcome lifecycle. PRD-024 derives analytics and streaks; it does not add gamification to the lifecycle engine.
- **Structured care outcomes:** [PRD-023 — Structured Care Outcomes](PRD-023-structured-care-outcomes.md). Supplies structured care evidence but does not itself establish plant health.
- **Plant observations/history:** [PRD-014 — Plant Check-ins](PRD-014-plant-check-ins.md), [PRD-018 — Plant Changes Timeline](PRD-018-plant-changes-timeline.md), JournalEntry and photo source contracts.
- **Visual history:** [PRD-012 — Growth Review](PRD-012-growth-review.md).
- **Reflection:** [PRD-013 — Weekly Garden Reflection](PRD-013-weekly-garden-reflection.md), to be reviewed for overlap; do not duplicate its reflection experience.
- **Related proposals:** [#64 — Growth Review](https://github.com/melusi-k/Feed-Good/issues/64), [#65 — Weekly Garden Reflection](https://github.com/melusi-k/Feed-Good/issues/65), [#66 — Plant Check-ins](https://github.com/melusi-k/Feed-Good/issues/66), [#72 — Plant Changes Timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- **Implementation issue:** Not created. Create the parent implementation issue and phase sub-issues only after §13 decisions are resolved and this PRD is approved.
- **Implementation status:** Not started. This document records the expanded product and technical contract for review.
