# PRD-007 — Garden Setup & Growing Context

**Status:** Implementation in progress  
**Release:** MVP foundation, after the first plant profile flow  
**Primary surface:** Add Plant, Edit Plant, Plant Profile

## 1. One-line goal

Let people optionally describe where and how they grow plants so Feed Good can provide more relevant context without making onboarding feel like a form or requiring sensitive location access.

## 2. Users and use cases

- A beginner wants a simple starting point without knowing horticultural terminology.
- A plant owner records whether a plant lives indoors, outdoors or on a balcony.
- A user notes the light conditions they observe in a growing space.
- A user adds a plant without supplying context.
- A user changes a plant's environment and updates that plant's context.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Optional context | Add a plant with no context and later add/edit/clear context | [measure] | [target: all paths pass; plant creation never blocked] | [owner] / [date] |
| Persistence | Save and reload supported environment and light fields | [measure] | [target: model and persistence tests pass] | [owner] / [date] |
| Privacy | Verify no precise location permission or network request is required | [measure] | [target: privacy review passes] | [owner] / [date] |
| Accessibility | Add and edit context fields with assistive technology and Dynamic Type | [measure] | [target: no blocking accessibility defects] | [owner] / [date] |

## 4. Behavior changes

- Capture optional context inline when adding a plant and allow it to be changed from Edit Plant.
- Store context directly on the plant for MVP; do not assume all plants in one home share the same conditions.
- Support broad environment values (indoors, outdoors, balcony, other) and user-observed light conditions (low, bright indirect, direct sunlight, mixed).
- Leave both fields unset by default and allow users to clear them.
- Explain why information is requested and distinguish user observations from measured environmental data.
- Keep setup independent of notification permission and network availability.
- Use available context to qualify guidance, never to manufacture certainty or diagnosis.

## 5. Out of scope

- Precise GPS location, address collection or background location.
- Weather APIs, climate automation or sensor integrations.
- Multiple independently managed gardens/spaces with membership and sharing.
- Automated light measurement or plant placement detection.
- A separate first-run Garden Setup flow.
- A reusable Garden or GrowingSpace entity in MVP.
- Mandatory onboarding questionnaires or a required catalogue selection.

## 6. Surfaces

- Add Plant context fields.
- Edit Plant context fields.
- Plant Profile context summary.
- Relevant explanatory copy in care guidance.

## 7. Pricing

Included in the free, local-first initial release. No account, subscription, network service or location permission is required.

## 8. Safety bar

- Ask only for context that has a clear product purpose.
- Do not collect precise location or infer a user's address.
- Make clear that light conditions are user-described, not sensor-verified.
- Do not treat context as a diagnosis or guarantee that a care schedule is correct.
- Allow users to skip, edit or clear context without losing plant records.
- Preserve existing data through schema changes.

## 9. Launch plan

1. Capture environment and light context inline in Add Plant and Edit Plant.
2. Verify default-unset, edit, clear and persistence behavior.
3. Verify existing plant records remain readable after the SwiftData schema change.
4. Confirm no location permission or network dependency is introduced.
5. Validate explanatory wording and accessibility on supported devices.

## 10. Replaces

Replaces implicit assumptions about where a plant lives with optional, user-described context. It does not replace environmental sensors, local weather services or horticultural assessment.

## 11. Open questions

- Should future releases introduce reusable growing spaces when users need to share one context across multiple plants?
- Should temperature or humidity be manually recorded in a later release?
- How should future guidance qualify or use user-described context without implying measured conditions?

## 12. Delivery tracking

- GitHub implementation issue: [#22 — Plant profiles: optional growing context](https://github.com/melusi-k/Feed-Good/issues/22).
- Implementation PR: [#22 — optional growing context](https://github.com/melusi-k/Feed-Good/pull/22).
