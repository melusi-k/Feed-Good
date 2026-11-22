# PRD-015 — Plant Archive and Restore

**Status:** Proposed for post-MVP product review  
**Priority:** P1 trust and lifecycle feature  
**Release:** Next tranche after care-history corrections  
**Primary surfaces:** My Plants, Plant Profile, Today, notifications, Settings & Data Portability

## 1. One-line goal

Let people move a plant out of active care without destroying the relationship record they have built with it.

## 2. Users and use cases

A user has given a plant away, lost a plant, moved it out of the home, or wants to keep a dormant plant out of daily care. They want to stop active reminders without deleting photos, journal entries, milestones or care history. They may later bring the plant back or simply revisit its story.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Reversible archive | Archive and restore one plant | [measure] | [target: lifecycle tests pass] | [owner] / [date] |
| Story preservation | Read all related records while archived | [measure] | [target: relationship tests pass] | [owner] / [date] |
| Reminder safety | Remove active notifications without stale routes | [measure] | [target: notification reconciliation passes] | [owner] / [date] |
| Archive integrity | Export/restore archived state | [measure] | [target: round-trip tests pass] | [owner] / [date] |

## 4. Behavior changes

- Add Archive and Restore actions to Plant Profile and the collection.
- Archiving removes a plant from active collection views, Today and due-care flows.
- Archiving cancels notifications for that plant and does not create overdue work.
- Plant Story, journal, photos, milestones and care history remain readable from an archived-plants view.
- Restore returns the plant to active views without duplicating records or tasks. The user must explicitly review whether reminders should resume.
- Archive confirmation explains that the action is reversible and does not delete the story.
- Permanent Delete remains a separate, more destructive action.
- The feature works offline and preserves archive state through export and restore.

## 5. Out of scope

- Automatic archiving based on inactivity, missed care or inferred plant health.
- Memorial/social features, public sharing or multiple gardens.
- Expanded lifecycle vocabulary; that is PRD-016.
- Changes to existing permanent-deletion semantics beyond making the distinction clear.

## 6. Surfaces

- Active and Archived collection sections or filter.
- Plant Profile archive/restore actions.
- Archive confirmation and restore reminder-review state.
- Archived Plant Story and journal access.
- Settings/export and recovery behavior.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Never delete user-authored content when archiving.
- Do not imply that archiving means the plant is dead or unhealthy.
- Never leave active reminders for an archived plant.
- Make restoration effects on reminders explicit; do not silently re-enable notifications.
- Keep archived private notes and photos out of notifications.
- Support Dynamic Type, VoiceOver, light/dark appearance and offline use.

## 9. Launch plan

1. Define the archive-state and notification transition contract.
2. Add archive/restore domain behavior and migration/archive coverage.
3. Verify Today, Plant Story, care flows and notification reconciliation.
4. Add UI journeys for archive, cancel, restore and reminder review.
5. Test export/restore, accessibility, empty states and physical-device behavior.

## 10. Replaces

Replaces the need to permanently delete a plant merely to remove it from active care. It does not replace permanent deletion or introduce a social memorial system.

## 11. Decisions and open questions

Decide whether restoring a plant should leave reminders off until the user opts back in, or offer a preview of each reminder before re-enabling. The safer default is to restore the record first and require explicit reminder reactivation.

The model should use an explicit archived state rather than deleting relationships or scattering Boolean checks. Unknown future archive values must recover safely.

## 12. Delivery tracking

- GitHub implementation issue: [#69 — Archive a plant without deleting its story](https://github.com/melusi-k/Feed-Good/issues/69).
- Existing PRD: [PRD-009 — Settings & Data Portability](PRD-009-settings-data-portability.md).
- Follow-up lifecycle proposal: [PRD-016 — Plant Lifecycle States](PRD-016-plant-lifecycle-states.md).
