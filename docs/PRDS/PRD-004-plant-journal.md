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
| Timeline | Combine care events and journal entries per plant with correct dates | [measure] | [target: ordering and date-boundary tests pass] | [owner] / [date] |
| Milestones | Record and distinguish meaningful plant moments | [measure] | [target: agreed milestone flows pass] | [owner] / [date] |
| Content preservation | Retain user-authored entries through edits and upgrades | [measure] | [target: migration and persistence tests pass] | [owner] / [date] |

## 4. Behavior changes

- Journal entries belong to one plant and have a date/time, optional text, optional photo and an optional milestone type.
- Make a basic entry quick to create; a photo or milestone must not be mandatory.
- Present entries in chronological order and make their associated plant clear.
- For #14, provide a per-plant story combining existing care events and journal entries in one date-ordered timeline. Distinguish the record kinds and include milestone observations. Read from the existing source records, not a duplicate history store. Reflect edits and deletions supported by either source without losing unrelated records.
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
- Plant-specific combined care and journal timeline on Plant Profile (#14).
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
3. Test chronological ordering, local dates, time-zone behavior and empty states. For #14, test mixed-source merge ordering (including deterministic ties), plant isolation, care-only/journal-only/empty timelines, milestone display, and source edits/deletions updating the timeline without duplicate records or unrelated data loss.
4. Test photo permission, selection, unavailable files and deletion.
5. Validate persistence and migration behavior with realistic user-authored content.
6. Complete privacy, accessibility and physical-device checks before release.

## 10. Replaces

Replaces scattered camera-roll photos and disconnected notes with a plant-centred record. It does not replace a full photo-management or cloud-backup service.

## 11. Decisions and open questions

Reconciled against the app on main (b5e593f8) on 2026-11-21.

### Settled (current baseline)

- **Journal is a primary tab and is also reachable from each plant profile.** The tab bar is Today, My Plants, Journal, Settings; a plant profile links to a journal filtered to that plant. Source: `AppTabView`, `PlantDetailView`.
- **One photo per entry.** An entry has a date, a note and an optional single photo; it needs a note or a photo to save. Source: `JournalEntry`, `JournalDraft.isValid`, `JournalView`.
- **Photo handling:** system picker, no library permission, resized to 1200 px longest edge and recompressed to JPEG (quality 0.82), stored locally in SwiftData external storage. Unreadable images are rejected and the previous photo is kept. Source: `PlantPhotoService`, `JournalView`.
- **Entries keep date and time.** The entry date is a full date-time chosen with a date picker, defaulting to now. Source: `JournalDraft.date`, `JournalView`.
- **Export format and expectations:** Settings > Export journal writes a versioned JSON archive with plant IDs, names, species, notes, creation dates and every entry's ID, plant ID, date, note and JPEG bytes. It is a manual export, not an automatic backup, and it does not include plant profile photos, care routines or history, or settings. Source: `docs/JOURNAL_ARCHIVE.md`.
- **Recovery is additive:** Settings > Recover journal adds missing plants and entries and never overwrites existing records. A conflicting ID, broken reference, unsupported version or invalid record rejects the whole import. Limits are 25 MB and 1,000 entries. Source: `docs/JOURNAL_ARCHIVE.md`.
- **Deleting an entry deletes its photo.** The confirmation says it can't be undone and exported archives are unchanged. **Deleting a plant deletes all its journal entries and photos.** Recovering an older archive can bring them back, only when the user chooses to. Source: `JournalStore.delete`, `Plant` cascade rule, `docs/JOURNAL_ARCHIVE.md`.

### Still open

- **Milestones are not implemented.** There are no predefined or custom milestone types in the app. Tracked in #14; the types and whether users can create custom ones are undecided. Product decision.
- **Combined care and journal timeline** (#14) is not built. Journal shows entries only.
- **Multiple photos per entry.** Current baseline is one. Decide whether MVP needs more.
- **Installed-store migration on a real device** has not been tested, per `docs/JOURNAL_ARCHIVE.md`. Do not claim upgrade acceptance until it is. Owner-reported device checks so far (build 7): create, view and edit.
- **Archive scale.** The 1,000-entry and 25 MB limits are a v1 safety choice. A streaming archive is future work.

## 12. Delivery tracking

- Journal entries, photos and garden-wide chronology: [#12 — Plant Journal](https://github.com/melusi-k/Feed-Good/issues/12).
- Combined care/journal timeline and milestones: [#14 — Plant story](https://github.com/melusi-k/Feed-Good/issues/14).
