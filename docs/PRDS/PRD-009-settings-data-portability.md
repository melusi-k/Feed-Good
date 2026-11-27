# PRD-009 — Settings & Data Portability

**Status:** Delivered — the Settings surface (appearance, plain-language privacy and data explanation, notification authorization status with a direct iOS Settings route, version and build) and the versioned garden archive with additive, previewed recovery are implemented and merged. The archive is at version 5: v2 complete garden archive (#15), additive v3 Quiet Period history (#125), v4 scheduled-care opportunities and v5 the effective due boundary (#145, #150). The follow-ups in §11 remain open product decisions.  
**Release:** MVP release-readiness requirement  
**Primary surface:** Settings, Export, Restore

## 1. One-line goal

Give people clear control over Feed Good's behavior and confidence that their locally stored garden records can be understood, exported and recovered.

## 2. Users and use cases

- A user wants to understand what data Feed Good stores and where it is stored.
- A user checks notification permission and knows how to change it in iOS Settings.
- A user wants to export plants, care history, journal entries and associated media.
- A user restores an archive after reinstalling or moving data to a new device.
- A user needs to understand app version, privacy behavior and support information.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Privacy transparency | Explain local storage, permissions and data handling in plain language | [measure] | [target: privacy content review passes] | [owner] / [date] |
| Settings accuracy | Show current notification authorization and relevant app settings | [measure] | [target: displayed state matches system state] | [owner] / [date] |
| Export completeness | Export agreed records and media into a documented archive | [measure] | [target: round-trip fixture and integrity tests pass] | [owner] / [date] |
| Restore safety | Validate archive and preview impact before restore | [measure] | [target: invalid archive and cancellation tests pass; no silent overwrite] | [owner] / [date] |
| Failure recovery | Explain export/restore failures without losing source data | [measure] | [target: failure injection tests pass] | [owner] / [date] |

## 4. Behavior changes

- Provide a Settings area with plain-language privacy and local-storage information.
- Show notification authorization state and offer a direct route to the relevant iOS Settings page; notification scheduling remains owned by PRD-003.
- Show app version and basic about information.
- Preserve the existing version-1 journal archive for compatibility.
- Define version 2 as a complete local garden archive containing plants, optional growing context, profile photos, care routines, care history, journal entries and journal photos.
- Define and document the archive format, versioning and compatibility expectations.
- Validate an archive before restore and show what will be added or skipped.
- Restore additively: add missing records, skip identical records and reject conflicting IDs before writing.
- Never overwrite existing user-authored records during merge recovery.
- Surface actionable errors and preserve original records when export or restore fails.
- Keep the experience usable without an account or network connection.

## 5. Out of scope

- Cloud backup, cross-device sync or account management.
- Third-party storage integrations.
- Automated scheduled backups.
- Subscription or paid export tiers.
- Duplicating notification scheduling controls already owned by PRD-003.

## 6. Surfaces

- Settings root and privacy explanation.
- Notification status and iOS Settings link.
- About/version details.
- Export archive flow and share/save destination.
- Restore selection, validation, preview and confirmation.
- Success, partial-failure and recovery states.

## 7. Pricing

Included in the free initial release. Export and restore are core trust and data-portability capabilities, not paid features.

## 8. Safety bar

- Never silently overwrite or discard existing user data.
- Validate archive structure, version and integrity before applying it.
- Preserve source data if export or restore fails.
- Treat journal text and photos as private user content.
- Explain what is included in an archive, including media and any excluded transient/system data.
- Do not claim that local storage is backed up by iCloud or another service unless that behavior is explicitly implemented and verified.
- Ensure privacy explanations match actual runtime behavior.

## 9. Launch plan

1. Retain JSON version 1 as journal-only compatibility input.
2. Define version 2 as a complete garden archive, retaining JSON, optional growing context from PRD-007 and the current additive merge policy.
3. Round-trip plants, profile photos, care routines, care events, journal entries and journal photos.
4. Verify relationship integrity, duplicate handling, conflicts and unsupported versions.
5. Test corrupt/incomplete archives and failure rollback.
6. Review privacy copy against the actual archive contents.

## 10. Replaces

Replaces opaque app settings and fragile manual recovery with explicit user control and a documented local data path. It does not replace a full cloud backup service.

## 11. Open questions

- Should future versions add archive encryption or password protection? Version 2 remains JSON unless a separate privacy decision changes this.
- How long must older archive versions remain restorable? Version 1 remains supported for import.
- Should the app offer a separate destructive delete-all-data action, and what confirmation is appropriate?

## 12. Delivery tracking

- GitHub implementation issue: [#15 — Settings: privacy, notification state, export and recovery](https://github.com/melusi-k/Feed-Good/issues/15) (closed; delivered by merged PR #15).
- Delivered archive versions: v1 journal-only import compatibility is retained; v2 complete garden archive (plants, growing context, profile photos, care routines, care history, journal entries and journal photos) merged in #15; additive v3 Quiet Period history and task snapshots (#125); v4 scheduled-care opportunities and v5 effective due boundary (#145, #150). v1–v4 archives remain importable.
- Delivered Settings surfaces: appearance, plain-language privacy and data explanation, notification authorization status with a direct iOS Settings route, and app version/build in About.
- Delivered export and recovery: documented archive contents in the export flow; restore validates first, shows a pre-restore preview of what will be added, requires explicit confirmation, then merges additively — adding missing records, skipping identical records and rejecting conflicting IDs before any write. Existing user records are never overwritten, and export/restore failures surface actionable errors while preserving source data.
- Verification: round-trip, Quiet Period archive compatibility, unsupported-version rejection and failure-path coverage live in FeedGoodTests (including QuietPeriodArchiveTests and JournalTests).
