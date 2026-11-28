# PRD-014 — Plant Check-ins and Cautious Troubleshooting

**Status:** Data-contract decision approved; implementation in progress; troubleshooting release remains safety-gated  
**Priority:** P2  
**Release:** Check-in records may be implemented independently; troubleshooting guidance remains post-MVP and safety-gated  
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

1. Assign editorial and safety ownership before selecting the initial symptom set; do not ship troubleshooting content before the owner, source hierarchy and review process are approved.
2. Implement a distinct `PlantCheckIn` model; do not extend `JournalEntry` with check-in semantics. Add the SwiftData V7 migration from V6 and preserve all existing V1–V6 schema definitions.
3. Keep troubleshooting content disabled and out of this implementation phase. A later content phase may begin only after each item has complete source provenance and independent qualified review.
4. Add content validation for stable IDs, provenance, review status and safe wording.
5. Test record/edit/delete, plant isolation, archive compatibility, offline traversal and unknown inputs.
6. Complete product, accessibility, privacy, content and physical-device review before release.

## 10. Replaces

Replaces the need to use only free-form notes when a plant looks different and provides a safer first learning path. It does not replace professional horticultural advice or make a diagnosis.

## 11. Decisions and open questions

The safety dependency is a release gate, not a post-launch cleanup item. Product review must name the editorial owner, source hierarchy and correction process before implementation begins. The first content set should remain small enough to review thoroughly.

### Approved editorial and source policy

The following policy is approved as a mandatory content and release gate for all bundled troubleshooting guidance:

- **Permitted sources:** official government or university cooperative/extension services and recognised horticultural societies. Do not use commercial vendor, nursery, influencer, forum or unsourced general-web material as an authority for troubleshooting claims.
- **Language:** cautious, educational and non-judgmental. Use qualified phrasing such as “consider checking” or “one possible factor”; never state or imply a diagnosis, certainty, guaranteed identification or guaranteed treatment outcome.
- **Prohibited instructions:** no pesticide, chemical or other treatment dosage; no prescriptive chemical application; and no unsupported treatment instructions.
- **Per-item provenance:** record the source organisation, exact source title, relevant section, URL, publication/update date when available, review status, named reviewer and reviewer role/qualification, and the review date. Missing required provenance blocks publication.
- **Reviewer suitability:** the reviewer must have relevant horticultural knowledge or demonstrable professional experience appropriate to the content. The content author cannot self-approve their own item as the sole reviewer.
- **Uncertainty and escalation:** unknown, conflicting or unsupported observations must lead to a neutral observation/checklist path and, where appropriate, a suggestion to seek qualified local horticultural advice. The app must not imply that its guidance replaces that advice.
- **Maintenance:** retain a correction path. Re-review content when its source changes, a safety concern is raised, or the guidance is materially revised; withdraw or disable an item if its source or safety cannot be verified.

This policy approves the editorial standard only. It does not approve any specific troubleshooting content or remove the existing release gate: each item must still be reviewed and have complete provenance before it ships.

### Approved data and persistence contract

Product has approved a separate `PlantCheckIn` model. It is a first-class observation record, not a `JournalEntry`, `CareEvent`, care completion or care opportunity.

- Preserve the existing `JournalEntry` contract and all immutable `FeedGoodSchemaV1` through `FeedGoodSchemaV6` definitions.
- Add `PlantCheckIn` to a new `FeedGoodSchemaV7` and migrate V6 to V7 without rewriting historical records. Existing installs must retain plant identity, journal/media, care, opportunity, quiet-period and tag relationships.
- Each check-in belongs to exactly one plant and has a stable ID, observation date, one or more validated observable-sign identifiers, optional context note and optional photo using the existing local-media policy. Do not infer signs from photos or notes.
- Check-in create/edit/delete is local-first and transactional. Plant deletion follows the existing cascade lifecycle. Archived plants retain their check-ins and story; archived check-ins remain editable only where the existing archived-plant policy permits, and no check-in may reactivate a plant.
- Check-ins are projected into Plant Story as a visibly labelled observation. Plant Story remains a projection, not a second persisted history store.
- Saving, editing or deleting a check-in must not mutate care tasks, due dates, reminders, `CareEvent`, care opportunities or streak/analytics qualification.
- Bump the JSON archive format from v5 to v6. Export check-ins with their plant IDs and media; decode v1–v5 archives as containing no check-ins; validate IDs, plant references, sign values, media, duplicate/conflicting records and record limits before writes; include check-ins in preview counts and transactional restore. Existing same-ID records must be identical or recovery must fail without partial writes.
- Keep offline troubleshooting content out of this data-contract implementation. The approved editorial policy is not approval of any content item. A named independent reviewer, qualifications, source-level provenance and review date remain mandatory before any guidance can ship.

### Delivery phases

1. **Data foundation:** V7 model/migration, archive v6 compatibility, validation, export/restore and offline CRUD.
2. **Story and entry points:** Plant Story projection and Plant Profile entry point; Today integration only after its navigation/archived-plant behavior is validated.
3. **Guidance (separate release gate):** reviewed offline content, neutral unknown/conflicting fallback, provenance UI and offline journey. This phase cannot ship until every item passes the approved editorial/safety review.

Issue #69 — Plant Archive and Restore — is closed and its archive contract is delivered. It is no longer an outstanding blocker; this work must preserve and extend that contract rather than re-open #69.

## 12. Delivery tracking

- GitHub implementation issue: [#66 — Add cautious plant check-ins and offline troubleshooting guidance](https://github.com/melusi-k/Feed-Good/issues/66).
- Existing Plant Journal: [PRD-004 — Plant Journal](PRD-004-plant-journal.md).
- Existing Plant Care Guide: [PRD-008 — Plant Care Guide](PRD-008-care-guide.md).
