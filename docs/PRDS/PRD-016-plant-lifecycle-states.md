# PRD-016 — Plant Lifecycle States

**Status:** Phase 2, Stage 1 — transition design proposed; implementation gated on product approval  
**Priority:** P2  
**Release:** Post-MVP, after archive/restore  
**Primary surfaces:** My Plants, Plant Profile, Today, Care Routine, Plant Story

## 1. One-line goal
Give each plant a small, understandable collection/lifecycle state without creating a complex status-management system.

## 2. Users and use cases
A user wants to distinguish plants they actively care for from plants in a genuinely different relationship or care context. They need clear consequences before changing a state and confidence that the plant's story remains intact.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| State clarity | Product/content review | Each approved state has a distinct plain-language meaning |
| Transition safety | Approved transition table and tests | Every allowed transition is deterministic |
| Data preservation | Persistence/export tests | No history or media loss |
| Care behavior | Today/reminder tests | Eligibility and reminders match state |
| Compatibility | Migration/unknown-value tests | Future values fail safely |

## 4. Recommended product decision

**Recommendation: retain only Active and Archived for the current release; do not add Dormant or Away as a lifecycle state yet.**

The archive foundation already provides a persisted, reversible distinction between Active and Archived through `Plant.archivedAt`. A second lifecycle enum or archive Boolean would create a competing source of truth. A user-controlled Dormant/Away label currently has no sufficiently distinct, consistently actionable meaning: if it pauses care, it duplicates the proposed Quiet Period (#74); if it does not affect care, Today or reminders, it adds status-management complexity without a clear user benefit.

This is a deliberate scope recommendation, not an automatic implementation decision. A future additional state requires a validated user need, a plain-language definition and a distinct behavior contract.

## 5. Proposed transition table

| Current state | User action | Result | Care eligibility | Today visibility | Reminder behavior | Journal/story |
| --- | --- | --- | --- | --- | --- | --- |
| Active | Archive, explicit confirmation | Archived; persist archive timestamp | No active care actions | Excluded from active Today | Cancel pending plant reminders | Remains readable |
| Archived | Restore, explicit confirmation | Active; clear archive timestamp | Eligible under existing task settings | Appears according to current due state | Recreate only eligible future reminders and only when permitted | Preserved |
| Active | Cancel archive | No change | Unchanged | Unchanged | Unchanged | Unchanged |
| Archived | Cancel restore | No change | Remains unavailable for active care | Remains excluded | Remains cancelled | Remains readable |

The table reuses the delivered PRD-015 archive contract; it does not authorize a second persisted state field.

## 6. Behavior changes
- Keep Active/Archived as the only supported lifecycle distinction for this delivery.
- Reuse PRD-015's persisted `Plant.archivedAt: Date?`; do not add an enum or duplicate archive flag.
- Keep archive and restore explicit and reversible.
- Keep journal/story readable while archived; suppress active-care, Today and routine-review actions while archived.
- Keep temporary care pauses separate and time-bounded/open-ended only through PRD-020 Quiet Periods.
- Do not infer dormancy, health, inactivity or care needs.

## 7. Out of scope
Automatic dormancy detection, inactivity inference, weather/location inference, multiple gardens, shared ownership, social memorials, lifecycle analytics and a second archive representation.

## 8. Surfaces
Existing archive/restore controls and status presentation in Plant Profile, active and archived collections, Today/care exclusion and preserved Plant Story. No new status picker is proposed unless a distinct additional state is approved.

## 9. Safety and product boundaries
- Archived means removed from active collection/care and is reversible under PRD-015.
- A Quiet Period under PRD-020 is a care-schedule adjustment, not a lifecycle state.
- State transitions never delete or rewrite care events, journal entries, photos or milestones.
- Unknown stored values must not crash or silently turn an archived plant Active.
- Lifecycle state is not a plant-health diagnosis.
- The delivered archive timestamp remains the single source of truth.

## 10. Launch plan
1. Review and approve/reject the recommended Active/Archived-only transition table.
2. If a distinct additional state is requested, document its user need and separate behavior before implementation.
3. Reconcile issue #70: close as no-additional-state-needed if the recommendation is accepted, or revise scope and acceptance criteria if another state is justified.
4. Use the approved lifecycle contract as the prerequisite for PRD-020 / #74.
5. Do not introduce code or schema changes for a duplicate archive representation.
6. Complete product/content and accessibility review for any newly introduced state surface.

## 11. Replaces
Replaces ambiguous or overloaded plant status labels. It does not replace archive, care routines or quiet periods.

## 12. Decisions and dependencies
- Hard prerequisite: PRD-015 / issue #69 archive/restore and its persisted data contract — complete and merged.
- Precedes and blocks PRD-020 / issue #74 until lifecycle vocabulary and transition behavior are explicitly resolved.
- Related to PRD-017 / issue #71, which is implemented in merged PR #82; archive-aware integration is included in merged PR #88.
- Builds on Plant Collection #1, Care Routine #4, Care Reminders #5, Plant Story #14 and Data Portability #15.
- The Active/Archived-only table above is a recommendation pending product approval, not an approved scope change.

## 13. Delivery tracking
- GitHub issue: [#70 — Add explicit plant lifecycle states after archive/restore](https://github.com/melusi-k/Feed-Good/issues/70).
- Phase 2 Stage 1: lifecycle vocabulary and transition decision.
- Status: design recommendation prepared; implementation intentionally gated until the transition decision is approved.
