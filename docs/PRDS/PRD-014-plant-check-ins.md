# PRD-014 — Plant Check-ins and Cautious Troubleshooting

**Status:** Proposed for post-MVP product review  
**Priority:** P2, contingent on editorial and safety ownership  
**Release:** Post-MVP, after the Care Guide review process is established  
**Primary surfaces:** Plant Profile, Today, Plant Story, offline Care Guide

## 1. One-line goal

Give people a structured, non-judgmental way to record what they observe when a plant looks different, then guide them toward safe next checks without pretending to diagnose it.

## 2. Users and use cases

A user notices yellowing, wilting, spots, pests or slow growth and wants to record what they saw. A beginner needs help deciding what to inspect next without being given an overconfident answer. A user wants to revisit an observation alongside the plant's story. A user is unsure what they are seeing and needs a neutral path that does not force a label.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Observation capture | Save a typed check-in to the correct plant | [measure] | [target: persistence and relationship tests pass] | [owner] / [date] |
| Safe guidance | Return qualified next-check education | [measure] | [target: editorial/safety review passes all shipped nodes] | [owner] / [date] |
| Offline use | Traverse bundled content without network | [measure] | [target: offline UI journey passes] | [owner] / [date] |
| Story integration | Revisit check-ins with plant chronology | [measure] | [target: projection and edit/delete tests pass] | [owner] / [date] |
| Provenance | Show source and review metadata | [measure] | [target: all shipped content has complete metadata] | [owner] / [date] |

## 4. Behavior changes

- Add a Plant check-in flow reachable from a plant profile, Today and the plant story.
- Capture an observation date, one or more observable signs, optional free-form context and an optional local photo using the existing photo policy.
- Make a check-in a first-class plant observation that appears in the plant story and can be edited or deleted without affecting care tasks or care events.
- Start with a small offline decision tree for a reviewed set of common observations. Results should say what to inspect next, what context would help and when qualified local advice may be appropriate.
- Use stable content IDs, source title/section, review status, review date and reviewer description, following the existing bundled-content provenance pattern.
- Allow “I’m not sure” and conflicting/unsupported selections; fall back to a neutral observation checklist instead of inventing an answer.
- Keep the content educational and qualified. Do not turn a check-in into a health score or a task deadline.

## 5. Out of scope

- AI image diagnosis, guaranteed identification, symptom certainty or remote expert chat.
- Weather, sensors, location, network-dependent recommendations or chemical dosage instructions.
- Pesticide or treatment prescriptions, toxicity claims or species-specific treatment without an approved source and safety review.
- Replacing the free-form Journal, the existing Care Guide or the user's plant-specific routine.

## 6. Surfaces

- Plant Check-in editor.
- Observable-sign selection and neutral “not sure” path.
- Bundled troubleshooting result and provenance sheet.
- Plant Story observation row and edit/delete controls.
- Today entry point when a user wants to record an observation.
- Empty, unsupported-input and offline-content states.

## 7. Pricing

Included in the local-first app if the reviewed content ships. No account or remote AI service is required.

## 8. Safety bar

- Every result must use qualified language such as “consider checking” and “possible factor,” never “diagnosed,” “definitely” or an equivalent certainty claim.
- Never infer a plant's condition from a photo; photos are user evidence for their private record only.
- Shipped content needs an identified editorial/safety owner, source provenance and a review date.
- Content must not advise harmful chemical use or imply that the app replaces qualified local advice.
- Observations remain separate from care schedules and never change a due date or reminder automatically.
- Keep notes and photos local, private and excluded from notifications unless the user intentionally opens them.

## 9. Launch plan

1. Assign editorial and safety ownership before selecting the initial symptom set.
2. Decide whether typed observation metadata extends `JournalEntry` or uses a small `PlantCheckIn` model; preserve the current story projection and archive guarantees.
3. Write and source-check the first 3–5 offline observation paths and their neutral fallback.
4. Add content validation for stable IDs, provenance, review status and safe wording.
5. Test record/edit/delete, plant isolation, archive compatibility, offline traversal and unknown inputs.
6. Complete product, accessibility, privacy, content and physical-device review before release.

## 10. Replaces

Replaces the need to use only free-form notes when a plant looks different and provides a safer first learning path. It does not replace professional horticultural advice or make a diagnosis.

## 11. Decisions and open questions

The safety dependency is a release gate, not a post-launch cleanup item. Product review must name the editorial owner, source hierarchy and correction process before implementation begins. The first content set should remain small enough to review thoroughly.

The schema choice remains open. Extending JournalEntry may minimise relationships and preserve the existing story; a separate PlantCheckIn may keep typed observation state clearer. Either option must define archive versioning, conflict behavior and deletion semantics before code is written.

## 12. Delivery tracking

- GitHub implementation issue: [#66 — Add cautious plant check-ins and offline troubleshooting guidance](https://github.com/melusi-k/Feed-Good/issues/66).
- Existing Plant Journal: [PRD-004 — Plant Journal](PRD-004-plant-journal.md).
- Existing Plant Care Guide: [PRD-008 — Plant Care Guide](PRD-008-care-guide.md).
