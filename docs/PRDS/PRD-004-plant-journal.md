# PRD-004 — Plant Journal

**Status:** Draft for product review  
**Release:** MVP milestone 3  
**Primary surface:** Plant Journal, Plant Profile timeline, Add Entry

## 1. One-line goal

Give every plant a personal, chronological story so people can capture observations, photos and milestones and notice meaningful change over time.

## 2. Users and use cases

- A user records a quick observation about a plant's condition or environment.
- A user adds a photo to remember a new leaf, flower, repotting or recovery.
- A user revisits older entries to see how a plant has changed.
- A user records a milestone without needing to complete a care task.
- A user corrects or removes their own entry and expects the rest of the plant's history to remain intact.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Entry creation | Create a dated note for the correct plant | [measure] | [target: persistence and relationship tests pass] | [owner] / [date] |
| Photo attachment | Attach, view and remove a photo safely | [measure] | [target: supported image lifecycle tests pass] | [owner] / [date] |
| Timeline | Display entries chronologically with correct dates | [measure] | [target: ordering and date-boundary tests pass] | [owner] / [date] |
| Milestones | Record and distinguish meaningful plant moments | [measure] | [target: agreed milestone flows pass] | [owner] / [date] |
| Content preservation | Retain user-authored entries through edits and upgrades | [measure] | [target: migration and persistence tests pass] | [owner] / [date] |

## 4. Behavior changes

- Journal entries belong to one plant and have a date/time, optional text, optional photo and an optional milestone type.
- Make a basic entry quick to create; a photo or milestone must not be mandatory.
- Present entries in chronological order and make their associated plant clear.
- Support observations and milestones such as new leaf, flowering, repotting and recovery without forcing users into a fixed taxonomy.
- Allow users to edit or delete their own entries with clear confirmation where deletion is destructive.
- Preserve user-authored text and photos through ordinary edits and app upgrades.
- Treat photo selection, storage and deletion as explicit lifecycle operations.
- Support offline creation and viewing.
- Do not automatically infer plant health from a journal entry or image.

## 5. Out of scope

- Public sharing, social feeds, comments or community messaging.
- AI image diagnosis or guaranteed species identification.
- Cloud photo backup, cross-device sync or public web galleries.
- Side-by-side photo comparison, automated growth measurement and advanced growth analytics; these are later opportunities requiring separate product validation.
- Complex media editing.

## 6. Surfaces

- Journal timeline across the user's garden.
- Plant-specific journal timeline on Plant Profile.
- Add/Edit Journal Entry.
- Photo selection and photo viewing.
- Milestone selection and presentation.
- Empty state and photo-unavailable state.

## 7. Pricing

Included in the free initial release. Entries and photos are stored locally; no account or cloud subscription is required.

## 8. Safety bar

- Journal text and photos are private user content and must not be transmitted or logged.
- Request photo-library access only when needed and use the least-privileged supported picker.
- Explain destructive deletion and preserve unrelated entries.
- Do not infer diagnosis, toxicity or treatment from text or photos.
- Avoid exposing private notes in notifications or other surfaces without user intent.
- Establish storage, backup, export and deletion behavior before release.

## 9. Launch plan

1. Agree the entry schema, supported milestone types and photo-storage policy.
2. Verify create/edit/delete and plant relationship integrity.
3. Test chronological ordering, local dates, time-zone behavior and empty states.
4. Test photo permission, selection, unavailable files and deletion.
5. Validate persistence and migration behavior with realistic user-authored content.
6. Complete privacy, accessibility and physical-device checks before release.

## 10. Replaces

Replaces scattered camera-roll photos and disconnected notes with a plant-centred record. It does not replace a full photo-management or cloud-backup service.

## 11. Open questions

- Is the journal a dedicated primary tab at MVP, or is it first accessed through plant profiles?
- Which milestone types are predefined, and can users create custom milestones?
- Are multiple photos per entry supported?
- What image formats, size limits and storage strategy are acceptable?
- What export format and backup expectations apply to journal content?
- What happens to journal entries and photo files when a plant is deleted?
- Is a date-only entry sufficient, or must exact time be preserved?

## 12. Delivery tracking

- Journal entries, photos and garden-wide chronology: [#12 — Plant Journal](https://github.com/melusi-k/Feed-Good/issues/12).
- Combined care/journal timeline and milestones: [#14 — Plant story](https://github.com/melusi-k/Feed-Good/issues/14).
