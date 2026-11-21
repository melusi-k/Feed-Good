# PRD-007 — Garden Setup & Growing Context

**Status:** Draft for product review  
**Release:** MVP foundation, after the first plant profile flow  
**Primary surface:** First-run welcome, Garden Setup, Plant Profile / Edit Plant

## 1. One-line goal

Let people optionally describe where and how they grow plants so Feed Good can provide more relevant context without making onboarding feel like a form or requiring sensitive location access.

## 2. Users and use cases

- A beginner wants a simple starting point without knowing horticultural terminology.
- A plant owner records whether a plant lives indoors, outdoors or on a balcony.
- A user notes the light conditions they observe in a growing space.
- A user skips setup and adds plants immediately, then supplies context later.
- A user changes a plant's environment and updates its context.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Optional setup | Complete, skip and resume setup | [measure] | [target: all paths pass; no setup gate blocks plant creation] | [owner] / [date] |
| Growing context | Save and edit supported space and light fields | [measure] | [target: model and persistence tests pass] | [owner] / [date] |
| Context ownership | Associate context with the correct plant or explicitly modelled space | [measure] | [target: relationship and migration tests pass] | [owner] / [date] |
| Privacy | Verify no precise location permission or network request is required | [measure] | [target: privacy review passes] | [owner] / [date] |
| Accessibility | Complete or skip setup with assistive technology | [measure] | [target: no blocking accessibility defects] | [owner] / [date] |

## 4. Behavior changes

- Offer a short, optional setup that can be skipped without penalty.
- Capture only useful, understandable context in the first release: broad growing location (indoors, outdoors, balcony or other) and observed light conditions.
- Allow context to be added or changed from the relevant plant profile.
- Do not assume all plants in one home share the same conditions.
- Explain why information is requested and distinguish user observations from measured environmental data.
- Keep setup independent of notification permission and network availability.
- Use available context to qualify guidance, never to manufacture certainty or diagnosis.

## 5. Out of scope

- Precise GPS location, address collection or background location.
- Weather APIs, climate automation or sensor integrations.
- Multiple independently managed gardens/spaces with membership and sharing.
- Automated light measurement or plant placement detection.
- Mandatory onboarding questionnaires or a required catalogue selection.

## 6. Surfaces

- Optional first-run introduction and setup flow.
- Plant profile context summary.
- Add/Edit Plant context fields.
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

1. Agree the smallest useful context vocabulary and whether context belongs to a plant or a reusable growing-space model.
2. Test skip, completion, edit and clear flows.
3. Verify local persistence, relationships and migration behavior.
4. Confirm no location permission or network dependency is introduced.
5. Validate guidance wording and accessibility on supported devices.

## 10. Replaces

Replaces implicit assumptions about where a plant lives with optional, user-described context. It does not replace environmental sensors, local weather services or horticultural assessment.

## 11. Open questions

- Should the first release attach context directly to each plant, or introduce a lightweight reusable growing-space entity?
- Which light descriptions are understandable and useful without implying measurement?
- Should users be able to record temperature or humidity manually, or is that too much for MVP?
- Should setup be offered immediately after first launch or only when a user adds a plant?
- How should context changes affect existing user-defined care schedules?

## 12. Delivery tracking

- GitHub implementation issue: [#22 — Garden setup: optional growing context and personalisation](https://github.com/melusi-k/Feed-Good/issues/22).
