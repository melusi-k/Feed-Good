# PRD-016 — Plant Lifecycle States

**Status:** Proposal consistent; design and implementation not started  
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

## 4. Behavior changes
- Define a minimal lifecycle model that includes Active and Archived, reusing PRD-015's archive state rather than adding a second archive flag.
- Evaluate whether one additional user-controlled state, such as Dormant or Away, solves a distinct need. Do not assume both are required.
- Define allowed transitions, reversibility, labels and behavior across collection, profile, Today, care, journal and notifications.
- Make transitions explicit and explain their impact before saving.
- Preserve state through export/restore.

## 5. Out of scope
Automatic dormancy detection, inactivity inference, weather/location inference, multiple gardens, shared ownership, social memorials and lifecycle analytics.

## 6. Surfaces
State label and action in Plant Profile/collection; transition impact summary and confirmation; consistent state presentation in Today, care, journal and archive.

## 7. Pricing
Included in the local-first app if approved. No account or network service is required.

## 8. Safety and product boundaries
- Archived means removed from active collection/care and is reversible under PRD-015.
- Dormant/Away, if approved, must have a distinct user need and must not silently archive a plant.
- Quiet Period under PRD-020 is a care-schedule adjustment, not a lifecycle state.
- State transitions never delete or rewrite care events, journal entries, photos or milestones.
- Unknown stored values must not crash or silently turn an archived plant Active.
- Lifecycle state is not a plant-health diagnosis.

## 9. Launch plan
1. Approve a transition table before implementation: source/destination, action, confirmation, care eligibility, Today visibility, reminder behavior and restore behavior.
2. Decide whether any additional state beyond Active/Archived is justified.
3. Define migration and unknown-value behavior.
4. Implement transitions and impact summaries.
5. Test every approved transition, cancellation, persistence, archive compatibility and export/restore.
6. Complete product/content, accessibility and physical-device review.

## 10. Replaces
Replaces ambiguous or overloaded plant status labels. It does not replace archive, care routines or quiet periods.

## 11. Decisions and dependencies
- Hard prerequisite: PRD-015 / issue #69 archive/restore and its persisted data contract.
- Precedes and blocks PRD-020 / issue #74.
- Related to PRD-017 / issue #71, but neither is a hard prerequisite for the other's initial implementation.
- Builds on Plant Collection #1, Care Routine #4, Care Reminders #5, Plant Story #14 and Data Portability #15.
- The approved transition table and any additional state decision are design gates, not assumptions.

## 12. Delivery tracking
- GitHub issue: [#70 — Add explicit plant lifecycle states after archive/restore](https://github.com/melusi-k/Feed-Good/issues/70).
- Status: proposal consistent; design and implementation outstanding.
