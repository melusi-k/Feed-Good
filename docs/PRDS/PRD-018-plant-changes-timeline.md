# PRD-018 — Plant Changes Timeline

**Status:** Source-of-truth decision recorded (option A); implementation in progress  
**Priority:** P2  
**Release:** Post-MVP, after archive compatibility  
**Primary surfaces:** Plant Profile, Plant Story, Journal

## 1. One-line goal
Make important changes in a plant's environment or care context visible alongside observations without claiming that a change caused a later outcome.

## 2. Users and use cases
A user repots a plant, moves it indoors or changes its light setup and wants to remember when. Later, they want to see the change in the plant's story alongside observations and photos.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| Capture | Persistence and validation tests | Correct plant and event type saved |
| Story projection | Ordering and UI tests | Change is visibly distinct |
| Record integrity | Edit/delete tests | Only selected change and media are affected |
| Archive compatibility | Export/restore tests | Same plant identity and media retained |
| Model choice | Documented design decision | Migration and semantics reviewed before coding |

## 4. Behavior changes
- Allow explicit user-created change types: moved location, repotted, changed pot/soil, grow light started/stopped, moved indoors/outdoors and custom change note.
- Capture event date, optional note and optional photo using existing local media policies.
- Display records chronologically in Plant Story with a distinct label.
- Support editing and deleting one change record.
- Preserve records and media through archive/export/restore.

## 5. Out of scope
Automatic environmental detection, location tracking, weather/sensors, health scores, diagnosis, causal inference and a general project/task log.

## 6. Surfaces
Plant-change capture/editor; distinct Plant Story row; edit/delete controls; archive/export/restore representation.

## 7. Pricing
Included in the local-first app. No account or network service is required.

## 8. Safety and data integrity
- Change records are not care completions or ordinary journal observations.
- No causal, diagnostic or health claim is generated from a change and a later observation.
- Editing/deleting affects only the selected change and associated media.
- Offline creation, editing and viewing work.
- Equal timestamps require a deterministic, documented tie-break rule.
- Do not create a second photo library.

## 9. Launch plan
1. Compare (A) typed PlantChange metadata on JournalEntry and (B) a dedicated PlantChange model.
2. Decide based on semantics, migration safety, edit/delete behavior, Plant Story projection and export versioning; record the decision before implementation.
3. Implement capture, editing and story projection.
4. Extend archive/export/restore while preserving plant identity.
5. Test validation, plant isolation, ordering, edit/delete, media privacy and round-trip.
6. Complete accessibility and physical-device review.

## 10. Replaces
Replaces reliance on free-form notes alone for a small set of structured plant changes. It does not replace the Journal.

## 11. Decisions and dependencies
- Builds on Plant Journal #12 and Plant Story #14.
- Hard archive compatibility prerequisite: PRD-015 / issue #69.
- Related to PRD-012 Growth Review, which may display change context; neither blocks the other.
- Source-of-truth model decision is mandatory before implementation and must be reflected in the implementation PR.
- **Decision (recorded before implementation):** Option A — a typed `changeKindRaw` on the existing `JournalEntry` model. A change record is one kind of entry (a record carries a milestone or a change kind, never both); ordinary observations without a kind never appear as changes by inference. Semantics: one timeline of plant observations, with the kind making the change explicit. Migration safety: an additive optional field, the same pattern as `milestoneRaw` and `Plant.archivedAt`; existing stores and pre-change archives decode unchanged. Edit/delete: the existing journal edit/delete path, which already affects only the selected record and its media. Story projection: the existing single-source projection stays, with a distinct "Plant change" label; equal timestamps keep the documented tie-break (newest first, then namespaced stable ID ascending). Export versioning: optional `changeKindRaw` key on archive version 2; unknown kinds and kind conflicts are rejected on recovery.

## 12. Delivery tracking
- GitHub issue: [#72 — Add plant changes to the story timeline](https://github.com/melusi-k/Feed-Good/issues/72).
- Status: model decision recorded (option A); implementation in progress.
