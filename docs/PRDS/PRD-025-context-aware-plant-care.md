# PRD-025 — Context-Aware Plant Care

**Status:** Draft for product review; no implementation issue created  
**Stage:** 4 — Context-aware and adaptive care  
**Priority:** Proposed P2 learning and decision-support capability  
**Release:** Later follow-up, after lifecycle, outcomes and observation contracts are stable  
**Primary surfaces:** Plant Profile, Plant Care, Today, offline Care Guide

## 1. One-line goal

Help people make better-informed care decisions by bringing together their plant's explicitly provided growing context and recent observations, while keeping the final decision with the user and avoiding automatic schedule changes or unsupported diagnosis.

## 2. Users and use cases

- A user is unsure whether a plant needs watering and wants a useful next check rather than a fixed instruction.
- A user wants care guidance to take account of the environment and light conditions they chose to record.
- A user records an observation and wants to know which additional context may be useful to inspect.
- A user wants to understand why a care suggestion is being shown and which information it relies on.
- A user has incomplete or conflicting information and needs the app to say so rather than invent certainty.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Context transparency | User can see which supplied facts inform a suggestion | [measure] | [target: explanation and provenance review passes] | [owner] / [date] |
| Safe next checks | Suggestions are bounded, qualified and source-backed | [measure] | [target: editorial/safety review approves all shipped guidance] | [owner] / [date] |
| User control | Suggestions never silently mutate routines or record completion | [measure] | [target: no-implicit-mutation tests pass] | [owner] / [date] |
| Missing-data handling | Unknown or conflicting context produces a neutral fallback | [measure] | [target: fallback matrix passes] | [owner] / [date] |
| Offline availability | Core guidance remains usable without network | [measure] | [target: offline journey passes] | [owner] / [date] |

## 4. Behavior changes

- Introduce decision support as a user-invoked “What should I check?” experience, not an autonomous care scheduler.
- Use only context the user has explicitly supplied or observations they have explicitly recorded, such as:
  - Plant species/name when known, with clear handling for unknown or user-entered species.
  - Growing environment and light condition already stored on the Plant profile.
  - User-recorded soil observations or other approved structured outcomes from PRD-023.
  - User-authored check-ins from PRD-014 and relevant care/journal history.
  - Bundled, reviewed Care Guide content with source provenance.
- Show the relevant inputs and their freshness/unknown status. A user must be able to correct the source context through its owning editor.
- Present one or more qualified next checks, questions or educational references. Examples should prefer “check the soil” or “observe the leaves” over “water now” when the app cannot know the plant's current condition.
- Explain why each suggestion appears and link to the supporting user-entered facts and reviewed guide content.
- When data is missing, contradictory, stale or outside the reviewed content set, show a neutral fallback and do not guess.
- Keep suggestions separate from care tasks. The user may choose to open the existing routine editor, record an observation or complete a task, but the suggestion itself must not create, complete, skip, snooze or reschedule anything.
- Do not automatically change a due date, interval, reminder preference, plant lifecycle state or quiet period.
- Keep the initial capability deterministic and local-first. No remote AI, image diagnosis, weather feed, precise location, sensor integration or external account is required.
- Treat any future automated or sensor-fed adaptation as a separate product decision and PRD, not an implicit extension of this scope.

## 5. Out of scope

- Autonomous watering, feeding, pruning or schedule mutation.
- Automatic diagnosis, disease/pest identification or treatment prescription.
- AI interpretation of photos, private journal text or free-form notes.
- Weather, geolocation, sensors, connected pots or external environmental APIs.
- Universal watering intervals, quantities or species assumptions.
- Claims that an observation proves a plant's health or that a care action caused an outcome.
- Replacing the existing care routine, Plant Care Guide or user judgment.

## 6. Surfaces

- User-invoked “What should I check?” entry point from Plant Profile and Plant Care.
- Optional Today contextual entry point where relevant and non-intrusive.
- Explanation view showing supplied context, unknown values, suggestion and source.
- Links to Plant Profile context editor, check-in, care history and bundled Care Guide.
- Neutral fallback for missing, conflicting, stale or unsupported inputs.
- Clear boundary between guidance and task completion.

## 7. Pricing

Included as a local-first decision-support capability if reviewed bundled content is approved. No account, subscription, remote inference or third-party service is required.

## 8. Safety bar

- Guidance must be qualified, bounded and traceable to reviewed source material.
- Do not present a suggestion as a diagnosis, certainty claim or guaranteed treatment.
- Do not infer current soil moisture, light exposure, temperature, humidity, weather or location from a stored profile value.
- A growing-environment or light field is user-described context, not a live measurement.
- A recorded observation may be old; show its date and do not treat it as current without user confirmation.
- Conflicting or insufficient data must lead to a neutral next-check list or “not enough information” state.
- Suggestions never alter care schedules, reminders, lifecycle state or history.
- No private journal note or photo is sent to a remote service; no sensitive content appears in notifications.
- Editorial ownership, source provenance, review date and correction process are mandatory before any new guidance ships.
- Maintain offline behavior, accessibility and understandable explanations.

## 9. Launch plan

1. Audit current Plant profile context, Care Guide provenance and the approved data contracts from PRD-022 through PRD-024.
2. Select one narrow, low-risk use case for the first release; do not launch a broad recommendation engine.
3. Define the exact allowed input fields, freshness rules, conflict handling and unsupported-input fallback.
4. Map each output to reviewed bundled content with source title/section, reviewer/owner, review status and review date.
5. Write and independently review all decision paths before implementation.
6. Implement a deterministic rules/content layer outside SwiftUI views, with no network dependency and no hidden state mutation.
7. Add tests for missing, stale, conflicting, unknown and supported inputs, including proof that task schedules and notifications remain unchanged.
8. Complete horticultural/editorial safety review, accessibility, privacy, offline and physical-device review before release.

## 10. Replaces

Replaces generic, context-free reminders with transparent, user-invoked next-check guidance. It does not replace the user's care routine, the Plant Care Guide or qualified horticultural advice.

## 11. Decisions and open questions

1. Which single use case offers enough value to justify the first version without implying diagnosis?
2. Which existing context fields are sufficiently reliable and understandable to use? How do we distinguish unknown, unspecified and stale values?
3. What counts as stale for each observation type, and should the user confirm it before it informs a suggestion?
4. Which bundled Care Guide sources and editorial owners are approved for decision-support use?
5. How should conflicting inputs be explained without overwhelming a beginner?
6. Should the result show one next check or a short ordered checklist? Avoid a pseudo-precise confidence score.
7. How does the user navigate from a suggestion to the existing routine editor without implying the suggestion has already changed the routine?
8. What evidence is required before any future sensor, weather or automated adaptation is considered? Such work is explicitly outside this PRD.

## 12. Delivery tracking

- **Implementation issue:** Not created. Create only after this PRD and the first supported use case, source set and safety review are approved.
- **Prerequisites:** [PRD-022 — Care Activity Lifecycle](PRD-022-care-activity-lifecycle.md), [PRD-023 — Structured Care Outcomes](PRD-023-structured-care-outcomes.md), and relevant reviewed content from [PRD-008 — Plant Care Guide](PRD-008-care-guide.md).
- **Observation inputs:** [PRD-014 — Plant Check-ins](PRD-014-plant-check-ins.md), [PRD-024 — Care Insights and Plant Health Story](PRD-024-care-insights-and-plant-health-story.md).
- **Routine boundary:** [PRD-017 — Care Routine Review](PRD-017-care-routine-review.md). Any actual schedule change remains an explicit user action through the existing routine editor.
- **Related proposals:** [#66 — Plant Check-ins](https://github.com/melusi-k/Feed-Good/issues/66), [#71 — Care Routine Review](https://github.com/melusi-k/Feed-Good/issues/71).
- **Dependency direction:** PRD-025 consumes approved user context, care outcomes and reviewed guide content. It must not mutate the source records or active care routine.
- **Implementation status:** Not started. This document records product intent only.
