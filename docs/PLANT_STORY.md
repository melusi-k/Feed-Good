# Plant story implementation notes

The combined timeline is a read-only projection of the existing CareEvent and JournalEntry stores. No record is copied into a new history store. Records are filtered by plant ID, sorted newest first, with namespaced stable IDs breaking equal-date ties. The UI distinguishes recorded care, journal observations and optional milestone labels.

Journal source editing is offered through the existing JournalEditor; deletion remains in the confirmed Journal screen. Care history stays read-only in the current product. The projection still reflects underlying care-source changes in tests, without adding an unapproved care-history editing flow. Deleting a care task preserves its events as before.

Milestone schema/archive compatibility is delivered first in PR #25. Timeline integration should use that merged baseline. The PlantDetailView growing-context changes belong to another slice; do not overwrite them while adding a route. All screenshots and tests use synthetic plant names and notes, never owner journal content.

Verification cases: mixed-source order, deterministic ties and namespaced IDs, plant isolation, empty/single-source stories, milestone visibility, source edits/deletions and no unrelated record loss. CI plus actual screenshot pixel inspection are separate from physical-device and installed-store migration acceptance.
