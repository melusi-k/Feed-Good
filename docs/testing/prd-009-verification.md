# PRD-009 verification and remainder checklist

Tracking PR for issue #56 (Settings & data portability). The implementation
merged in #15 and #25; this draft tracks what remains before the issue can be
considered fully verified. It starts as a checklist-only draft.

## Remaining work

### Device verification (manual, recorded per build)
- [ ] Export a populated garden archive on a physical device; confirm the file
      contents match the documented version-2 format.
- [ ] Recover that archive into a wiped install; confirm plants, growing
      context, care routines, care history, journal entries, milestones and
      photos arrive intact.
- [ ] Recover the same archive a second time; confirm idempotent no-change
      behaviour.
- [ ] Attempt recovery of a conflicting-ID archive; confirm rejection with no
      writes.
- [ ] Record device, iOS version, app build and archive size per run.

### Automated remainder (covered by #30 slice 5, PR #54)
- Oversized archive (25 MB / 1,000-record boundaries).
- Corrupt or truncated archive data; rollback with no partial writes.
- Duplicate plant IDs and conflicting relationships during recovery.
- Photo round-trip, invalid image data, missing/invalid references.
- Version 1 import compatibility alongside version 2.

## Related

- Issue: #56
- PRD: docs/PRDS/PRD-009-settings-data-portability.md
- Merged implementation: #15, #25
- Automated remainder: #30 slice 5, PR #54
