# PRD-012 — Growth Review

**Status:** Proposed for post-MVP product review  
**Priority:** P1/P2 relationship feature  
**Release:** Post-MVP, after journal/photo lifecycle is release-stable  
**Primary surfaces:** Plant Profile, Plant Story, Journal

## 1. One-line goal

Help people notice and remember change by turning existing plant journal photos into a simple, plant-centred visual review.

## 2. Users and use cases

A user wants to see whether a plant has changed since an earlier observation. A user records a new leaf, flowering, repotting or recovery and wants to compare it with a prior photo. A user wants the context of each photo, not just an image. A user has no or only one photo and needs a clear, encouraging next step.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Eligible photos | Show only valid photos for one plant | [measure] | [target: plant-isolation tests pass] | [owner] / [date] |
| Comparison | Select and compare two dated observations | [measure] | [target: primary comparison journey passes] | [owner] / [date] |
| Context | Keep dates, milestones and notes visible | [measure] | [target: source context is unambiguous] | [owner] / [date] |
| Source integrity | Reflect JournalEntry edits/deletions | [measure] | [target: projection tests pass] | [owner] / [date] |
| Privacy | Keep photos on-device | [measure] | [target: no network/storage regression] | [owner] / [date] |

## 4. Behavior changes

- Add a Growth review entry point from a plant profile and its plant story.
- Derive the gallery from existing `JournalEntry` records that contain local photos; do not copy image bytes into a second history store.
- Show eligible photos for the current plant, newest first, with the observation date, milestone label and a concise note preview where available.
- Let the user select two different entries from the same plant and view them side by side or in a swipe comparison. The comparison is temporary in the first slice and does not need a saved comparison record.
- Provide a route from each compared image back to its source journal entry.
- Show a useful empty state for zero or one photo and a direct route to Add observation.
- Reflect journal edits and deletions on the next render.
- Keep the entire experience offline and do not infer growth, health or causality from pixels.

## 5. Out of scope

- Automatic growth measurement, computer vision, image similarity ranking or AI comparison.
- Plant-health scores, diagnosis, treatment recommendations or species identification.
- Cloud photo sync, public sharing, albums, multi-plant comparison or a general photo editor.
- Multiple photos per journal entry unless separately approved.

## 6. Surfaces

- Plant Profile Growth review route.
- Plant Story Growth review route.
- Photo selection grid/list with dates and milestones.
- Two-photo comparison view.
- Empty, one-photo, missing/unreadable-photo and deleted-source states.
- Navigation back to the source Journal entry.

## 7. Pricing

Included in the local-first app. Existing photos remain on-device and no account or remote service is required.

## 8. Safety bar

- Never represent visual difference as proof of healthy or unhealthy growth.
- Label the dates and source observations clearly; do not manufacture a baseline or measurement.
- Respect local photo storage and do not transmit or log private images.
- Avoid pressure, streak language and implied failure when a user has not taken photos.
- Use lazy or bounded image loading consistent with the existing photo downsampling policy.
- Support accessibility labels that identify plant, date and comparison position without relying on colour.

## 9. Launch plan

1. Confirm the temporary-comparison interaction and whether a swipe or side-by-side layout is clearer at iPhone widths.
2. Implement the eligible-photo projection and deterministic selection rules.
3. Add unit tests for filtering, ordering, same-plant selection and missing source records.
4. Add UI coverage for the two-photo journey, empty states and source navigation.
5. Review memory use with the existing 1200 px JPEG storage policy.
6. Complete light/dark, Dynamic Type, VoiceOver, privacy and physical-device review.

## 10. Replaces

Replaces the need to manually scroll a mixed plant story to compare individual photos. It does not replace the Journal or create a separate photo-management product.

## 11. Decisions and open questions

The first release should keep comparisons temporary and derived from JournalEntry. Product review should decide between side-by-side and swipe comparison after a quick usability check. The current one-photo-per-entry contract remains sufficient for the proposed slice; multiple photos should not be added as an implicit dependency.

If a later version supports saved comparisons, store references to journal-entry IDs rather than duplicating image bytes and define archive behavior before implementation.

## 12. Delivery tracking

- GitHub implementation issue: [#64 — Add a per-plant growth review from journal photos](https://github.com/melusi-k/Feed-Good/issues/64).
- Existing Plant Journal: [PRD-004 — Plant Journal](PRD-004-plant-journal.md).
- Existing Plant Story: [PRD-004 — Plant Journal](PRD-004-plant-journal.md).
