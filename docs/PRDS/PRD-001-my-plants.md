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
- A user searches for a plant by its chosen name or known species and opens the correct record.
- A user corrects details, changes a photo or removes a plant they no longer own.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Plant creation | Create a valid plant with required fields | [measure] | [target: all required-field and persistence tests pass] | [owner] / [date] |
| Plant identity | Preserve chosen name and botanical/common-name fields | [measure] | [target: values survive relaunch and edits] | [owner] / [date] |
| Collection retrieval | Find and open the correct plant from My Plants | [measure] | [target: no wrong-record navigation in test set] | [owner] / [date] |
| Search and sort | Search by plant name/species and sort by name or recently added | [measure] | [target: deterministic results, empty and case-insensitive search tests pass] | [owner] / [date] |
| Edit and delete | Update a plant and confirm destructive removal | [measure] | [target: relationship integrity and confirmation tests pass] | [owner] / [date] |
| Accessibility | Navigate primary plant journeys with VoiceOver and Dynamic Type | [measure] | [target: no blocking accessibility defects] | [owner] / [date] |

## 4. Behavior changes

- Treat the plant as the authoritative record to which care activities, reminders and journal entries attach.
- Support create, view, edit and delete journeys with clear validation and forgiving form behavior.
- Support a chosen plant name, species/common name, photo and notes as described by the product brief; mark any field not yet implemented as planned rather than implying availability.
- Provide basic collection search across the user's plant names and known species/common-name fields.
- Provide simple, predictable sorting (at minimum name and recently added); preserve the user's selected sort where practical.
- Make empty states explain the value of adding a plant and offer a clear first action.
- Make destructive deletion explicit. Explain what associated data will be removed and require confirmation.
- Preserve plant identity and relationships through ordinary edits and app relaunches.
- A missing photo must never prevent a plant from being created or viewed.

## 5. Out of scope

- Guaranteed species identification or AI diagnosis.
- Public plant profiles, sharing, social feeds or community messaging.
- Mandatory account creation, cloud sync or cross-device collaboration.
- A comprehensive botanical catalogue unless separately approved.
- Complex multi-attribute filter builders, saved searches or multiple garden workspaces.
- Automated health scoring or unsupported claims about plant condition.

## 6. Surfaces

- My Plants collection, basic search/sort controls and its empty state.
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
3. Test empty, populated, long-name, missing-photo, search, sort and deletion states.
4. Verify persistence after relaunch and accessibility in light and dark appearances.
5. Record unit, UI, simulator and physical-device evidence independently.
6. Release with the core app; monitor [measure: add completion, search success, edit errors and deletion issues] where privacy-respecting measurement is available.

## 10. Replaces

Replaces an informal or fragmented way of keeping plant details in memory or separate notes with one local plant record. It does not replace a specialist botanical reference or professional horticultural advice.

## 11. Decisions and open questions

Reconciled against the app on main (b5e593f8) on 2026-11-21. "Current baseline" means shipped behavior that this PRD adopts unless the owner changes it.

### Settled (current baseline)

- **Plant name is required; species and notes are optional.** The edit form blocks saving a blank (whitespace-only) name; values are trimmed. Source: `PlantProfileDraft.isValid`.
- **Onboarding is manual entry first.** There is no plant catalogue in the app. A curated catalogue is out of scope here and belongs to PRD-008. Source: `AddPlantView`, empty state in `PlantListView`.
- **MVP profile fields:** name (required), species (optional), notes (optional), photo (optional), created date (automatic). Source: `Plant` model.
- **Deleting a plant removes its care tasks, care history and journal entries.** The delete alert says so and cannot be undone. Source: cascade rules in `Plant`, alert text in `PlantDetailView`. The journal-photo part is covered in PRD-004.
- **Plant photos are stored locally, nothing is uploaded.** Photos are picked with the system picker, resized to 1200 px on the longest edge and saved as JPEG (quality 0.82) in SwiftData external storage. Source: `PlantPhotoService`.
- **Backup and export:** plant names, species, notes and creation dates are included in the journal archive (Settings > Export journal). Plant profile photos are not. See PRD-004 and PRD-009. Source: `docs/JOURNAL_ARCHIVE.md`.

### Still open

- **Search and sort are not implemented.** Section 3 and section 4 describe search by name or species and sorting by name or recently added. Main only lists plants newest first, with no search field and no sort control. Either build them (issue #3) or mark them "planned" in sections 3 and 4. Product decision: which one?
- **Remembering a sort choice across launches** depends on the above. Stays open until a sort control exists.
- **Plant profile photo backup.** The journal archive leaves out profile photos, so a user who deletes the app loses them. Decide whether a fuller garden backup is wanted (see PRD-009).

## 12. Delivery tracking

- GitHub implementation issue: [#3 — My Plants: complete plant profiles and editing](https://github.com/melusi-k/Feed-Good/issues/3).
