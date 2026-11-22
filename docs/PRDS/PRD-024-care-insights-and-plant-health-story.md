# PRD-024 — Care Insights and Plant Health Story

**Status:** Draft for product review; no implementation issue created  
**Stage:** 3 — Plant health observations and insights  
**Priority:** Proposed P2 relationship and understanding capability  
**Release:** After the required source-record and archive contracts are stable  
**Primary surfaces:** Plant Profile, Plant Story, Growth Review, Today

## 1. One-line goal

Help people understand what has been happening with an individual plant by bringing together real care records, observations and visual history—without assigning unsupported health scores, diagnosing problems or claiming that one event caused another.

## 2. Users and use cases

- A user wants to understand the recent story of one plant rather than browse disconnected records.
- A user notices a change and wants to compare it with earlier care and observations.
- A user wants a useful summary of what has actually been recorded over a chosen period.
- A user wants to identify missing context, such as a long gap in observations, without being told that the plant is unhealthy.
- A user has only a few records and still needs a neutral, useful experience.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Record traceability | Every displayed insight links to its source record | [measure] | [target: source-reference tests pass] | [owner] / [date] |
| Summary accuracy | Summary reflects the current local records and edits/deletions | [measure] | [target: deterministic projection tests pass] | [owner] / [date] |
| Plant isolation | No record from another plant appears in the summary | [measure] | [target: relationship/isolation tests pass] | [owner] / [date] |
| Neutral interpretation | No unsupported health or causal claim is presented | [measure] | [target: product/editorial review passes] | [owner] / [date] |
| Offline behavior | Story and insights remain available without network | [measure] | [target: offline UI journey passes] | [owner] / [date] |

## 4. Behavior changes

- Provide a plant-centred view that helps users make sense of the records they have already created.
- Derive content from existing source-of-truth records where possible:
  - CareEvent records, including any approved structured outcomes from PRD-023.
  - Plant Check-ins and their user-entered observations from PRD-014.
  - JournalEntry notes, photos and milestones.
  - Explicit plant-change records from PRD-018 when available.
- Offer a small set of transparent summaries, such as:
  - Recent recorded care actions.
  - Recent observations and journal moments.
  - A chronological sequence of notable recorded changes.
  - Photo comparisons using the existing Growth Review capability.
  - A neutral indication that there is little or no recent information, without implying neglect or poor health.
- Every summary item must be traceable to one or more source records. Selecting it opens the correct source plant and record.
- Recompute derived content from current records so edits, deletions, plant archive/restore and data recovery do not leave stale summaries.
- Use user-selected time ranges or clearly labelled local-calendar periods. Define calendar and time-zone behavior for deterministic summaries.
- Keep summaries explanatory: show what was recorded and when, not a conclusion about why a plant changed.
- Do not create a second care ledger or duplicate journal content. Persist only minimal presentation preferences when necessary.
- Keep the experience useful with sparse data, no photos, no check-ins and no structured care outcomes.

## 5. Out of scope

- Plant health scores, grades, rankings, streaks or collection-wide performance dashboards.
- Diagnosis, disease identification, treatment recommendations or claims of guaranteed recovery.
- Causal inference between care actions, environmental changes and plant outcomes.
- AI interpretation of journal text or photos, sentiment analysis or automated symptom extraction.
- Remote analytics, account requirements, cloud sync or network-dependent summaries.
- Replacing Plant Story, Growth Review, Journal, Plant Check-ins or Weekly Garden Reflection.

## 6. Surfaces

- Plant Profile summary/insights section.
- Plant Story chronological view and source-record navigation.
- Growth Review entry point and photo comparison.
- Optional Today contextual link to a plant's recent story.
- Selected-period filter and transparent empty/sparse-data states.
- Archived-plant read-only story state, consistent with archive policy.

## 7. Pricing

Included in the local-first app as a derived experience. No account, network service, subscription or third-party analytics is required.

## 8. Safety bar

- Every displayed statement must be supported by a current user-authored or explicitly sourced record.
- Distinguish recorded fact (“Watered on 12 May”) from observation (“User noted yellow leaves”) and interpretation (“Consider checking light conditions”).
- Do not infer a health status from inactivity, missing records, photo frequency or completion percentages.
- Do not imply that a care action caused an improvement or decline.
- Never produce a numerical health score or risk label.
- Respect archive visibility and preserve source identity through export/restore.
- Keep notes and photos private and local; do not expose them in notifications.
- Support offline use, accessible chart alternatives, VoiceOver descriptions and Dynamic Type.

## 9. Launch plan

1. Inventory the source records and projections available in the current app and the status of PRD-012, PRD-014, PRD-018 and PRD-023.
2. Define a bounded first summary with explicit inclusion/exclusion rules and no duplicated data store.
3. Specify deterministic ordering and tie-breaking for records with equal timestamps.
4. Define local-calendar/time-zone behavior and the response to edits, deletion, archive/restore and import.
5. Create source-navigation contracts for every summary row and test plant identity.
6. Add derived-projection tests for empty, sparse, dense, edited, deleted and mixed-record histories.
7. Complete product/content review for every explanatory phrase and ensure it does not imply diagnosis or causality.
8. Verify accessibility, offline behavior, performance on long histories and physical-device presentation.

## 10. Replaces

Replaces the need to manually piece together a plant's recent history across care, journal and photo screens. It does not replace the source records or claim to measure biological health.

## 11. Decisions and open questions

1. What is the smallest useful first summary: a combined timeline, a compact recent-activity overview, or both?
2. Which source types are included in the first release, and how should unavailable/archived source types be presented?
3. Should users select a period, or should the first version use a fixed recent window? Avoid arbitrary periods that obscure the user's local calendar.
4. Which summaries are safe and meaningful with sparse data? Avoid percentages or trend language without a defensible denominator.
5. What is the deterministic ordering/tie-break rule when care events, check-ins and journal entries share timestamps?
6. How should an imported record with an unknown future type appear without being dropped or mislabelled?
7. Should this capability live inside Plant Story or as a distinct profile summary? Avoid creating competing navigation destinations.
8. Which parts can be derived synchronously and which need bounded precomputation for long histories? Performance claims require profiling evidence.

## 12. Delivery tracking

- **Implementation issue:** Not created. Create only after this PRD and the first-slice source/summary decisions are reviewed and approved.
- **Foundations:** [PRD-012 — Growth Review](PRD-012-growth-review.md), [PRD-013 — Weekly Garden Reflection](PRD-013-weekly-garden-reflection.md), [PRD-014 — Plant Check-ins](PRD-014-plant-check-ins.md), [PRD-018 — Plant Changes Timeline](PRD-018-plant-changes-timeline.md).
- **Care data dependency:** [PRD-022 — Care Activity Lifecycle](PRD-022-care-activity-lifecycle.md) and [PRD-023 — Structured Care Outcomes](PRD-023-structured-care-outcomes.md).
- **Related proposals:** [#64 — Growth Review](https://github.com/melusi-k/Feed-Good/issues/64), [#65 — Weekly Garden Reflection](https://github.com/melusi-k/Feed-Good/issues/65), [#66 — Plant Check-ins](https://github.com/melusi-k/Feed-Good/issues/66), [#72 — Plant Changes Timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- **Dependency direction:** PRD-024 consumes existing records and approved PRD-023 outcomes; it does not own or mutate those records. It can be delivered incrementally as source capabilities become available.
- **Implementation status:** Not started. This document records product intent only.
