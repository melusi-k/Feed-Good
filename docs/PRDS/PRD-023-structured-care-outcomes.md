# PRD-023 — Structured Care Outcomes

**Status:** Draft for product review; no implementation issue created  
**Stage:** 2 — Rich care records and outcomes  
**Priority:** Proposed P1 trust and learning capability  
**Release:** After PRD-022 lifecycle and occurrence semantics are approved  
**Primary surfaces:** Care completion, Plant Care history, Plant Story

## 1. One-line goal

Let people record useful context about what they actually did during plant care, turning a simple completion checkmark into a trustworthy, optional and searchable care record without making every action feel like a form.

## 2. Users and use cases

- A user waters a plant and wants to record whether the soil was dry, moist or wet.
- A user fertilises or prunes a plant and wants to record a small amount of relevant context.
- A user looks back at care history to understand what happened before a later observation.
- A user wants to attach a photo or note to a care event without creating a duplicate journal entry.
- A user prefers a quick one-tap completion and does not want to answer extra questions every time.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Quick completion | Complete care without mandatory extra fields | [measure] | [target: no-regression primary completion journey] | [owner] / [date] |
| Structured capture | Save valid optional outcome fields against the correct event | [measure] | [target: validation and relationship tests pass] | [owner] / [date] |
| Historical clarity | Distinguish recorded facts, user observations and guidance | [measure] | [target: content and UI review passes] | [owner] / [date] |
| Edit/delete integrity | Correct or remove outcome details without changing the active routine | [measure] | [target: transactional history-only tests pass] | [owner] / [date] |
| Portability | Preserve supported outcome data and media through export/restore | [measure] | [target: versioned round-trip tests pass] | [owner] / [date] |

## 4. Behavior changes

- Extend the existing care-completion flow with optional, task-relevant outcome details. A user must still be able to complete a care task without filling in structured fields.
- Begin with a deliberately small field set:
  - Optional soil condition observation (for example, dry, slightly moist, moist, wet, not checked), shown only when relevant to the activity and never treated as a sensor reading.
  - Optional amount/quantity with an explicit unit and a clear “not measured” path; do not imply that a suggested amount is correct for every plant.
  - Optional action-specific details for feeding, pruning or custom care only after the product review confirms that the field is genuinely useful.
  - Existing optional note, with its current privacy and editing behavior preserved.
  - Optional photo only if it can reuse the established local photo-storage and archive policy without duplicating the journal photo library.
- Store structured values as typed, validated data with explicit units and stable raw-value compatibility. Do not encode structured values into free-form note strings.
- Preserve the task-title snapshot, plant association and completion timestamp on the historical event.
- Keep a clear distinction between:
  - What the user did (care action).
  - What the user observed (for example, soil felt wet).
  - What the app says or suggests (guidance).
- Make structured fields editable as historical event details under the history-only policy. Editing or deleting an outcome must not silently change the active task due date or interval.
- Keep the first version local-first and usable offline. Do not require photos, measurements or a network connection.
- Make Plant Story display concise summaries and provide access to the complete record without overwhelming the timeline.

## 5. Out of scope

- Sensor readings, automatic soil-moisture detection or inferred quantities.
- Diagnosing plant health or claiming that an action caused a later change.
- Automatically adjusting care schedules based on recorded outcomes.
- Mandatory checklists or forms for every completion.
- Duplicate storage of journal photos or a second general-purpose media library.
- Social sharing, cloud sync, remote analytics or AI-generated interpretations.

## 6. Surfaces

- Quick care-completion action.
- Optional “Add details” expansion or follow-up sheet.
- CareEvent detail and history correction flow.
- Concise care-event row in Plant Story.
- Export/restore representation and validation errors.
- Empty, not-measured, unsupported-field and media-unavailable states.

## 7. Pricing

Included in the local-first app. No account, subscription, remote processing or third-party dependency is required.

## 8. Safety bar

- Optional values must be explicitly described as user observations, not objective measurements unless the user entered a measured quantity with a unit.
- Never recommend an amount or treatment based solely on a recorded value.
- Do not infer that watering was needed because the user recorded dry soil, or that watering was harmful because the user recorded wet soil.
- Do not infer causation between a care event and later plant growth or symptoms.
- Preserve privacy: notes and photos must not appear in notification text, logs or analytics.
- Validate numeric values and units; reject invalid, non-finite or unreasonable input without silently coercing it.
- Preserve old archive compatibility and handle unknown future structured values safely.
- Maintain one-tap completion, offline use and accessible controls.

## 9. Launch plan

1. Review current CareEvent schema, history editor, plant story projection, photo storage and JournalEntry media policy.
2. Agree a minimal field matrix by CareKind; avoid a universal form that asks irrelevant questions.
3. Decide whether structured outcomes extend CareEvent directly or require a separate value object/model. Prefer the smallest migration-safe design that preserves one historical source of truth.
4. Define value validation, unit representation, optionality, localization and unknown-value fallback.
5. Define photo ownership and export semantics before allowing a care event to attach media.
6. Implement transactional creation/edit/delete and rollback; ensure no mutation of CareTask schedule state.
7. Add migration, archive round-trip, validation, plant-isolation, accessibility and UI tests.
8. Review completion time and task friction with users before expanding the field set.

## 10. Replaces

Replaces the limitation of a care event that records only a task title, date and free-form note. It does not replace the Journal, Plant Check-ins or the care routine.

## 11. Decisions and open questions

1. Which fields are genuinely useful for each existing CareKind, and which should remain note-only?
2. Should soil condition be captured only for watering, or also for a distinct soil-check task? The app must not imply that checking soil and watering are the same action.
3. Are quantities useful enough to include in the first release? If included, which units and validation ranges are appropriate for user-entered values?
4. Should a care event support a photo, or should users create a JournalEntry and link/navigate to it? Avoid storing the same image bytes twice.
5. Should structured values be stored directly on CareEvent or in a typed child/value model? Decide based on migration safety, query needs and archive complexity.
6. How are old events represented when new fields are introduced? Missing values must remain “not recorded,” not be backfilled with guesses.
7. Which event fields can be corrected under PRD-011's history-only policy, and how are field-level edits/deletes confirmed?
8. How should export versioning, unknown enum values and downgrade/restore behavior work?

## 12. Delivery tracking

- **Implementation issue:** Not created. Create only after this PRD and its field/model decisions are reviewed and approved.
- **Prerequisite:** [PRD-022 — Care Activity Lifecycle and Occurrence Management](PRD-022-care-activity-lifecycle.md).
- **Existing foundations:** [PRD-002 — Care Routine](PRD-002-care-routine.md), [PRD-009 — Settings & Data Portability](PRD-009-settings-data-portability.md), [PRD-011 — Care History Corrections](PRD-011-care-history-corrections.md).
- **Related proposals:** [#63 — Care History Corrections](https://github.com/melusi-k/Feed-Good/issues/63), [#66 — Plant Check-ins](https://github.com/melusi-k/Feed-Good/issues/66), [#72 — Plant Changes Timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- **Dependency direction:** PRD-023 depends on the lifecycle and occurrence semantics approved in PRD-022. It provides richer historical inputs for PRD-024 but does not automatically alter schedules.
- **Implementation status:** Not started. This document records product intent only.
