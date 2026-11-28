# Journal archive and recovery contract (v1–v6)

Set before the Journal schema is introduced.

- The live garden stays on this iPhone in SwiftData. Journal photos use optional external-storage data, managed as local files by SwiftData. No account, network upload or remote photo store.
- Settings > Export journal creates a versioned JSON archive with all plants' IDs, names, species, notes and creation dates, and every journal entry's ID, plant ID, date, note and prepared JPEG bytes. Plant profile photos, care routines/history and settings are not in this journal-only archive. The export screen states that limit.
- The archive contains private notes and photos in readable form. The user chooses where to save/share it through the system document picker. Export is manual, not automatic backup. Keep it somewhere safe outside the app before deleting the app or a plant.
- Settings > Recover journal opens a saved archive. Recovery is additive: existing plant IDs are reused without changing plant details, missing plants are recreated, and entries with new IDs are inserted. Identical existing entries are skipped. A conflicting entry ID, broken plant reference, unsupported version, invalid image or invalid record rejects the whole import before writes. Existing records are never overwritten.
- All imported records are saved in one transaction. A save failure rolls back the import and is shown. Export/import picker errors are shown. Review the recovered chronology and save a new export afterward.
- Deleting a journal entry permanently deletes its local photo with it. Deleting a plant cascades its journal entries, as the existing plant confirmation states. Neither action deletes an exported archive. Recovering from an older archive can bring deleted entries back; that is explicit recovery, never automatic.
- Archives have a 25 MB import limit and a 1,000-entry safety limit. It is a journal recovery format, not a complete garden backup. Larger gardens need a future streaming archive, not a silent truncation.
- Existing installed-store migration must be tested on a device before claiming upgrade acceptance. Disk reopen tests are not a substitute for that migration test.


## Milestone extension (issue #14)

Journal entries may optionally record New leaf, Flowering, Repotting or Recovery as an owner observation, not a diagnosis. Other moments remain free-form notes. The optional `milestoneRaw` string defaults to nil for existing entries. A milestone alone is a valid observation; removing its label requires keeping a note or photo so an empty entry cannot be saved.

New exports use journal archive version 2 and retain the optional milestone string. Recovery accepts original version-1 archives without the field (nil), or version 2. An unknown milestone or a version-1 archive carrying a milestone is rejected before writes. Version-1 apps reject version 2 rather than silently dropping the observation. Entry-ID conflict comparisons include the milestone. The 25 MB and 1,000-entry limits and additive recovery rules are unchanged.

Full-garden archive integrations must include this field and its conflict/validation semantics before accepting milestone records. This journal-only archive remains separate and still excludes care records and profile photos. Schema defaulting and disk reopen tests do not establish installed-store migration acceptance. Upgrade a retained pre-milestone install on a device and verify existing notes/photos before claiming that acceptance.


## Quiet Period extension (archive v3)

New exports use version 3 and add two optional arrays:

- `quietPeriods`: stable period ID, owning plant ID, creation/start/end instants, lifecycle status, reason and activation/end timestamps.
- `quietPeriodTaskSnapshots`: stable snapshot ID, parent period ID, scalar task UUID and title snapshot, membership state, signed remaining-day offset, original local due-time components, frozen interval, exact Next care override and capture/update timestamps.

Version 1 and 2 archives remain importable. Missing v3 keys decode as empty, so older files do not lose compatibility. Version 1/2 files carrying v3-only records are invalid rather than silently dropping them.

Before writes, recovery validates period and snapshot UUID uniqueness, plant ownership, snapshot-to-period references, lifecycle/membership enum values, date ordering, active-period membership consistency and the referenced enabled task for each active member. A plant may not have overlapping scheduled/active periods. Active periods must contain at least one active snapshot; deleted or disabled task snapshots remain valid audit history when their membership is marked accordingly.

Recovery remains additive and idempotent. Existing same-ID Quiet Periods and snapshots are skipped only when every archived field and relationship matches; changed content is a conflict. New plants, tasks, periods and snapshots are assembled in an isolated context and committed together. Any invalid reference, conflict or save failure rejects the whole import without partial writes or mutation of existing records.

The export includes archived and active plants' Quiet Period history. App settings and notification permissions remain excluded. Plant hard deletion still cascades locally through its Quiet Periods and snapshots; a previously exported archive can restore them as part of explicit recovery.


## Plant Check-in extension (archive v6)

New exports use archive version 6 and add `plantCheckIns`, each containing the stable check-in ID, owning plant ID, observation instant, validated observable-sign identifiers, optional context note and optional local photo bytes.

- Versions 1–5 remain supported and decode with no check-ins. Any v1–v5 JSON payload that contains the v6-only `plantCheckIns` key is rejected, including an empty array; newer observation data is never silently discarded.
- Version 6 requires the `plantCheckIns` key. Validate unique check-in IDs, an existing plant reference, one or more known sign identifiers, unique signs, the exclusive `notSure` selection and valid image data before writes.
- Preview reports check-ins to add and already present. Recovery is additive: an identical same-ID check-in is skipped; a differing same-ID record is a conflict. All new check-ins are inserted in the same isolated recovery context and transaction as the rest of the archive.
- Check-ins are not care completions and restore does not change care tasks, due dates, reminders, opportunities or streak inputs.
