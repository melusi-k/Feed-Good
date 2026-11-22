# PRD-018 — Plant Changes Timeline

**Status:** Proposed for post-MVP product review  
**Priority:** P2 relationship and learning feature  
**Release:** After journal and story projection are stable  
**Primary surfaces:** Plant Story, Plant Profile, Journal

## 1. One-line goal

Make meaningful environmental changes visible alongside observations so users can remember what changed without implying causality.

## 2. Users and use cases

A user moved a plant, repotted it, changed soil or started a grow light and wants that context beside later observations. They want a durable memory of the garden, not another care task.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Capture | Record a typed change against one plant | [measure] | [target: persistence tests pass] | [owner] / [date] |
| Story integration | Show deterministic chronology | [measure] | [target: Plant Story tests pass] | [owner] / [date] |
| Edit safety | Edit/delete only the selected change | [measure] | [target: isolation tests pass] | [owner] / [date] |
| Archive integrity | Preserve changes through recovery | [measure] | [target: round-trip tests pass] | [owner] / [date] |

## 4. Behavior changes

- Add a small set of typed events: moved, repotted, new pot/soil, grow light started, moved outdoors/indoors and custom change.
- Capture date, optional note and optional photo using the existing local photo policy.
- Show change events distinctly from care completion and ordinary journal observations.
- Allow edit and delete without changing tasks, care events or reminders.
- Include changes in Plant Story and export/restore.
- Keep the flow offline and provide a neutral empty state.

## 5. Out of scope

- Automatic environmental detection, location tracking, weather or sensors.
- Health scores, diagnosis or causal claims.
- A general project log or second photo library.

## 6. Surfaces

- Add Plant Change flow.
- Typed change selection.
- Plant Story change row and detail.
- Edit/delete controls.
- Optional photo attachment and source navigation.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Label changes as user-recorded context, not explanations of plant health.
- Never infer that a later event was caused by a recorded change.
- Keep photos and notes local and private.
- Preserve user-authored content through edits, deletion and archive recovery.
- Support Dynamic Type, VoiceOver and clear event labels.

## 9. Launch plan

1. Decide whether typed changes extend JournalEntry or use a separate model.
2. Define story ordering for equal timestamps and archive schema behavior.
3. Add domain and projection tests for each approved type.
4. Add UI coverage for capture, edit, delete, missing media and source navigation.
5. Verify accessibility, privacy and physical-device behavior.

## 10. Replaces

Replaces the need to encode environmental changes as vague free-form notes. It does not replace the Journal or Care Routine.

## 11. Decisions and open questions

The model choice should minimise duplicate sources of truth. Extending JournalEntry may simplify story and archive integration, while a typed PlantChange may keep semantics clearer. Product review should approve the initial event vocabulary before implementation.

## 12. Delivery tracking

- GitHub implementation issue: [#72 — Add plant changes to the story timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- Existing PRD: [PRD-004 — Plant Journal](PRD-004-plant-journal.md).
