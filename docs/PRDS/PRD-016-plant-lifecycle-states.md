# PRD-016 — Plant Lifecycle States

**Status:** Proposed discovery follow-up  
**Priority:** P2 relationship and organization feature  
**Release:** After PRD-015 proves archive/restore behavior  
**Primary surfaces:** My Plants, Plant Profile, Plant Story, Today

## 1. One-line goal

Give plants a small, understandable lifecycle vocabulary so the app reflects their current relationship to the user's garden without becoming a status-management system.

## 2. Users and use cases

A user wants to distinguish an active plant from one that is dormant, temporarily away or no longer in active care. They want the state to explain why reminders or Today behavior differ, while keeping the plant's history intact.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Vocabulary clarity | Users understand each state | [measure] | [target: content review passes] | [owner] / [date] |
| Transition safety | State changes have predictable effects | [measure] | [target: transition matrix passes] | [owner] / [date] |
| Record preservation | State changes retain all history | [measure] | [target: relationship and archive tests pass] | [owner] / [date] |
| Scope discipline | Minimal state set solves observed need | [measure] | [target: product review approves] | [owner] / [date] |

## 4. Behavior changes

- Begin with Active and Archived from PRD-015, then evaluate one additional state such as Dormant or Away.
- Show the current state on Plant Profile and relevant collection views.
- Define state-specific behavior for care recording, reminders, Today inclusion and journal additions.
- Require explicit confirmation and an impact summary before a transition that affects active care.
- Keep transitions reversible where practical and record them in Plant Story only if the history meaning is clear.
- Preserve lifecycle state through export and restore.
- Handle unknown future state values without crashing or silently converting to Active.

## 5. Out of scope

- Automatic dormancy detection or health inference.
- Weather/location-based state changes.
- Multiple gardens, shared ownership, social memorials or lifecycle analytics.
- A large taxonomy of horticultural states.

## 6. Surfaces

- Plant Profile state control.
- Collection state labels and filters.
- Transition confirmation and impact summary.
- Plant Story state-change entries if approved.
- Today and notification behavior for each supported state.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- State labels must not imply a diagnosis or blame.
- Do not infer dormancy from missed care, photos, weather or location.
- Keep care history, journal entries and photos intact through every transition.
- Explain reminder and Today consequences before saving.
- Keep the state model accessible and understandable without colour alone.

## 9. Launch plan

1. Gather evidence from PRD-015 and define the smallest useful vocabulary.
2. Write a state transition table covering Care, Today, Journal, Story and notifications.
3. Define migration, archive and unknown-value behavior.
4. Implement only the approved state set and focused UI flows.
5. Test transitions, restoration, accessibility and physical-device behavior.

## 10. Replaces

Replaces ad hoc notes or ambiguous archive behavior when users need to explain a plant's current place in their garden. It does not replace care history or create a full project-management status system.

## 11. Decisions and open questions

Product review must decide whether a second non-active state has enough value to justify its complexity. “Dormant” may be too species-dependent; “Away” may be clearer for a plant temporarily outside the user's care. The initial state set should remain small until real usage supports expansion.

## 12. Delivery tracking

- GitHub implementation issue: [#70 — Add explicit plant lifecycle states after archive/restore](https://github.com/melusi-k/Feed-Good/issues/70).
- Depends on: [PRD-015 — Plant Archive and Restore](PRD-015-plant-archive.md).
