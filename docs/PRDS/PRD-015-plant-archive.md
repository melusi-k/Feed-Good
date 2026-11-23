# PRD-015 — Plant Archive and Restore

**Status:** Complete — Phase 1 implementation merged and owner-verified (2026-11-23)  
**Priority:** P1 foundation  
**Release:** Post-MVP foundation; archive compatibility is a prerequisite for dependent features  
**Primary surfaces:** My Plants, Plant Profile, Plant Story, Settings / Data Portability

## 1. One-line goal
Let people remove a plant from active care without deleting its identity, story, photos, milestones, care history or other user-authored records.

## 2. Users and use cases
A user no longer owns or actively cares for a plant but wants to retain its history. A user temporarily removes visual clutter from the active collection and later wants the same plant restored. A user exports or recovers a garden and expects archived plants and relationships to survive.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| Reversible state | Persisted optional `Plant.archivedAt: Date?`; legacy records without the field migrate as active |
| Active-surface exclusion | Archived plants excluded from active collection, Today, active care and routine-review navigation |
| Reminder reconciliation | Archive cancels pending notifications; restore schedules only eligible future reminders according to task settings and permission |
| Data integrity | Export/recovery preserves archive state and supported relationships/media; rollback and duplicate-prevention behavior covered |
| Usability | Archive confirmation, archived collection, restore flow and readable archived Plant Story |

## 4. Behavior changes
- Add explicit Archive and Restore actions.
- Persist archive as a reversible collection state; never infer it from inactivity or implement it as deletion.
- Exclude archived plants from the active collection, Today and active due-care actions.
- Cancel pending local notifications on archive. On restore, schedule only eligible future reminders according to saved task settings and current permission.
- Provide an accessible archived collection/list and keep archived Plant Story readable with a clear archived indicator.
- Include archive state and related records/media in export and restore.
- Keep permanent Delete separate, destructive and separately confirmed.

## 5. Out of scope
Automatic inactivity archiving, multiple gardens, shared spaces, memorial/social features, archive analytics, lifecycle taxonomy and unrelated redesign of permanent deletion.

## 6. Surfaces
Active collection actions; archive confirmation; archived collection; archived plant profile/story; restore confirmation/state; export and restore flows.

## 7. Pricing
Included in the local-first app. Archive/restore is a data-trust capability, not a paid feature.

## 8. Safety and data integrity
- Archiving never deletes the Plant, CareTask, CareEvent, JournalEntry, milestone, photo or related user content.
- No care completion can be recorded through active Today/care flows for an archived plant.
- Restore reactivates the same identity and must not duplicate tasks, events or media.
- Failed persistence restores the prior archive state without discarding unrelated pending edits.
- Persist archive as an optional `archivedAt: Date?` timestamp: nil is Active and a timestamp is Archived. This avoids an extensible raw-value enum; older archive files without the optional field decode as Active.
- Recovery into an empty destination restores the archived timestamp. Existing same-ID plant records are never overwritten during additive recovery, including their current archive state.
- Archive is distinct from Dormant, Away, paused care and Quiet Period.

## 9. Launch plan
1. Define the persisted archive field/state and migration behavior.
2. Implement transactional archive/restore and active-collection filtering.
3. Reconcile local notifications on both transitions.
4. Add archived collection/story and explicit restore.
5. Extend the current data archive format and validate all relationships/media.
6. Test migration, failure rollback, duplicate prevention, Today exclusion and round-trip recovery.
7. Complete accessibility, Dynamic Type, appearance, offline and physical-device review.

## 10. Replaces
Replaces deletion-or-leave-active as the only ways to manage an inactive plant. It does not replace permanent deletion.

## 11. Decisions and dependencies
- #63 Care history corrections and #64 Growth Review are closed as completed after owner-confirmed manual verification and implementation evidence.
- Builds on Plant Collection #1, Plant Story #14 and Data Portability #15 / PRD-009.
- Hard prerequisite for PRD-016 lifecycle states, PRD-014 check-ins, PRD-018 plant changes and PRD-021 tags.
- PRD-012 Growth Review, PRD-013 Weekly Reflection and PRD-017 Routine Review are independent but must respect archived visibility and disable active-care actions.
- Delivery uses focused stacked sub-PRs #79, #83 and #84. The consolidated parent integration [PR #88](https://github.com/melusi-k/Feed-Good/pull/88) is merged to `main` at `acbd3c810af71d2a204ee85fee9b37aafd257007`.

## 12. Delivery tracking
- GitHub issue: [#69 — Archive a plant without deleting its story](https://github.com/melusi-k/Feed-Good/issues/69) — completed.
- Implementation stack: [PR #79 — archive state and active-care exclusion](https://github.com/melusi-k/Feed-Good/pull/79), [PR #83 — archived collection and restore flow](https://github.com/melusi-k/Feed-Good/pull/83), and [PR #84 — export/recovery, legacy SwiftData migration and archive-aware routine review](https://github.com/melusi-k/Feed-Good/pull/84). [Parent integration PR #88](https://github.com/melusi-k/Feed-Good/pull/88) consolidates the complete implementation. The sub-PRs are review slices and are not independently releasable.

## 13. Phase 1 verification and sign-off
- iOS build and unit tests, App Intents metadata verification, test attachment export, Thread Sanitizer and review rules passed on PR #88.
- The on-disk legacy-store migration test verified plant fields, photo data, CareTask/CareEvent and JournalEntry relationships survive migration, with legacy plants remaining active (`archivedAt == nil`).
- **Owner-confirmed manual verification (2026-11-23):** archive/restore journey, offline behavior, and archive accessibility/appearance checks including Dynamic Type and light/dark.
- Growth Review populated two-photo PhotosPicker device journey passed on build 43 / `FeedGood-0.1.43-build43.ipa` (2026-11-23).
- Phase 1 issues #63, #64 and #69 are closed as completed.
- Related data contract: [PRD-009 — Settings & Data Portability](PRD-009-settings-data-portability.md).
