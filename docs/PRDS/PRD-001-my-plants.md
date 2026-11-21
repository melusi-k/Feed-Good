# PRD-001 — My Plants

**Status:** Draft for product review  
**Release:** Initial release / MVP  
**Primary surface:** My Plants, Add Plant, Plant Profile

## 1. One-line goal

Make Feed Good the trusted home for a person's plants, giving every plant a clear identity and a profile that can grow into its care and life story.

## 2. Users and use cases

- A beginner adds their first houseplant without needing to understand complex horticultural terminology.
- An established plant owner keeps a collection organised and can quickly find a specific plant.
- A user gives a plant a personal name while retaining its species or common name as useful context.
- A user opens a profile to understand the plant's current details and reach its care or journal history.
- A user corrects details, changes a photo or removes a plant they no longer own.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Plant creation | Create a valid plant with required fields | [measure] | [target: all required-field and persistence tests pass] | [owner] / [date] |
| Plant identity | Preserve chosen name and botanical/common-name fields | [measure] | [target: values survive relaunch and edits] | [owner] / [date] |
| Collection retrieval | Find and open the correct plant from My Plants | [measure] | [target: no wrong-record navigation in test set] | [owner] / [date] |
| Edit and delete | Update a plant and confirm destructive removal | [measure] | [target: relationship integrity and confirmation tests pass] | [owner] / [date] |
| Accessibility | Navigate primary plant journeys with VoiceOver and Dynamic Type | [measure] | [target: no blocking accessibility defects] | [owner] / [date] |

## 4. Behavior changes

- Treat the plant as the authoritative record to which care activities, reminders and journal entries attach.
- Support create, view, edit and delete journeys with clear validation and forgiving form behavior.
- Support a chosen plant name, species/common name, photo and notes as described by the product brief; mark any field not yet implemented as planned rather than implying availability.
- Make empty states explain the value of adding a plant and offer a clear first action.
- Make destructive deletion explicit. Explain what associated data will be removed and require confirmation.
- Preserve plant identity and relationships through ordinary edits and app relaunches.
- A missing photo must never prevent a plant from being created or viewed.

## 5. Out of scope

- Guaranteed species identification or AI diagnosis.
- Public plant profiles, sharing, social feeds or community messaging.
- Mandatory account creation, cloud sync or cross-device collaboration.
- A comprehensive botanical catalogue unless separately approved.
- Automated health scoring or unsupported claims about plant condition.

## 6. Surfaces

- My Plants collection and its empty state.
- Add Plant and Edit Plant forms.
- Plant Profile / Plant Detail.
- Photo selection and photo presentation.
- Entry points from Today, Care Routine and Plant Journal.
- Light and dark appearances; iPhone layouts supported by the app's deployment target.

## 7. Pricing

No feature-level charge. My Plants is part of the free, local-first initial release. No subscription, account or network service is required.

## 8. Safety bar

- Do not imply that a plant is unhealthy or dying based only on incomplete profile data.
- Validate user input without losing entered values.
- Explain deletion and its impact on associated care and journal records before confirmation.
- Keep plant data on-device in the initial release; do not transmit profile details or photos.
- Ensure essential actions do not rely on colour alone and remain accessible.

## 9. Launch plan

1. Confirm the plant data contract and required/optional fields.
2. Verify create, read, update and delete behavior, including SwiftData relationship integrity.
3. Test empty, populated, long-name, missing-photo and deletion states.
4. Verify persistence after relaunch and accessibility in light and dark appearances.
5. Record unit, UI, simulator and physical-device evidence independently.
6. Release with the core app; monitor [measure: add completion, edit errors and deletion issues] where privacy-respecting measurement is available.

## 10. Replaces

Replaces an informal or fragmented way of keeping plant details in memory or separate notes with one local plant record. It does not replace a specialist botanical reference or professional horticultural advice.

## 11. Open questions

- Is plant name mandatory, and should species/common name be optional?
- Does initial onboarding offer a curated plant catalogue, manual entry first, or both?
- Which profile fields are required at MVP versus later?
- What exact deletion and recovery behavior is expected for associated photos, care activity and journal entries?
- Is plant photo storage limited to app-managed local files, and what is the backup/export expectation?
- Which sort and filter options are essential for the first release?


## 12. Delivery tracking

- GitHub implementation issue: [#3 — My Plants: complete plant profiles and editing](https://github.com/melusi-k/Feed-Good/issues/3).
