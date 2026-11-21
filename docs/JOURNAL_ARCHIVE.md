# Journal v1 archive and recovery contract

Set before the Journal schema is introduced.

- The live garden stays on this iPhone in SwiftData. Journal photos use optional external-storage data, managed as local files by SwiftData. No account, network upload or remote photo store.
- Settings > Export journal creates a versioned JSON archive with all plants' IDs, names, species, notes and creation dates, and every journal entry's ID, plant ID, date, note and prepared JPEG bytes. Plant profile photos, care routines/history and settings are not in this journal-only archive. The export screen states that limit.
- The archive contains private notes and photos in readable form. The user chooses where to save/share it through the system document picker. Export is manual, not automatic backup. Keep it somewhere safe outside the app before deleting the app or a plant.
- Settings > Recover journal opens a saved archive. v1 recovery is additive: existing plant IDs are reused without changing plant details, missing plants are recreated, and entries with new IDs are inserted. Identical existing entries are skipped. A conflicting entry ID, broken plant reference, unsupported version, invalid image or invalid record rejects the whole import before writes. Existing records are never overwritten.
- All imported records are saved in one transaction. A save failure rolls back the import and is shown. Export/import picker errors are shown. Review the recovered chronology and save a new export afterward.
- Deleting a journal entry permanently deletes its local photo with it. Deleting a plant cascades its journal entries, as the existing plant confirmation states. Neither action deletes an exported archive. Recovering from an older archive can bring deleted entries back; that is explicit recovery, never automatic.
- Archive v1 has a 25 MB import limit and a 1,000-entry safety limit. It is a journal recovery format, not a complete garden backup. Larger gardens need a future streaming archive, not a silent truncation.
- Existing installed-store migration must be tested on a device before claiming upgrade acceptance. Disk reopen tests are not a substitute for that migration test.
