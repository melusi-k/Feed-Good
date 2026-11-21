# PRD-008 — Plant Care Guide

**Status:** Editorial and implementation planning  
**Release:** MVP, after editorial provenance and review process is established  
**Primary surface:** Care Guide, Plant Profile, Care Routine

## 1. One-line goal

Give people a trustworthy, approachable place to learn how plant care works, with practical guidance that is useful offline and honest about what Feed Good does and does not know.

## 2. Users and use cases

- A beginner wants to understand terms such as indirect light, drainage or feeding.
- A plant owner wants to learn about watering, light, soil, pruning or repotting.
- A user opens guidance from a care task to understand the reason behind it.
- A user checks a plant profile for relevant general guidance.
- A user needs to distinguish educational information from a recommendation tailored to their particular plant.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Coverage | Review agreed core care topics for completeness | [measure] | [target: approved MVP topic list is covered] | [owner] / [date] |
| Factual quality | Verify each factual article against appropriate sources | [measure] | [target: provenance and review metadata present for every published item] | [owner] / [date] |
| Findability | Search and browse topics using plain language | [measure] | [target: agreed search and navigation test set passes] | [owner] / [date] |
| Comprehension | Beginner review of terminology and instructions | [measure] | [target: editorial comprehension rubric approved] | [owner] / [date] |
| Offline use | Open guide content without network access | [measure] | [target: full MVP guide available offline] | [owner] / [date] |

## 4. Behavior changes

- Provide a curated guide to core topics including light, watering, soil and drainage, feeding, pruning, repotting and common care practices.
- Organise content by topic and make it searchable using everyday language.
- Explain unfamiliar terms and give practical, appropriately qualified next steps.
- Record source provenance, review status, reviewer and review date for factual content.
- Prefer sources in this order: peer-reviewed horticultural research and university/agricultural extension publications; public botanical gardens and government horticultural bodies; established horticultural institutions. Commercial or community sources may inform topic discovery but are not sole authority for factual claims.
- Distinguish general education from guidance that is genuinely specific to a known plant.
- Link to relevant guide topics from plant profiles and care tasks where useful.
- Keep the guide available offline and avoid turning every article into a scheduled task.
- Use garden context only when it is available and relevant; state when information is insufficient.

## 5. Out of scope

- AI-generated care advice or conversational diagnosis.
- Guaranteed species identification.
- Treatment prescriptions for pests, disease or toxicity.
- Remote content feeds or mandatory network access.
- User-generated public articles, comments or social features.
- Personalised schedules generated without sufficient plant and environment evidence.

## 6. Surfaces

- Care Guide entry point and topic index.
- Search results and topic detail.
- Contextual links from Plant Profile and Care Routine.
- Source and review information within an article or its details.

## 7. Pricing

Included in the free initial release. The MVP guide is bundled and available offline; no subscription or network service is required.

## 8. Safety bar

- Every factual care item must have traceable provenance and editorial review.
- Avoid universal watering intervals, fixed quantities or unsupported certainty.
- State the limits of general guidance and avoid implying professional diagnosis.
- Do not recommend potentially harmful treatments without an appropriately reviewed basis.
- Provide a content correction and withdrawal process when an item is found inaccurate.
- Keep content readable, accessible and free of guilt-based language.

## 9. Launch plan

1. Adopt the source hierarchy and content metadata contract.
2. Assign a named horticultural/editorial reviewer before publishing factual entries.
3. Agree a modest MVP topic list rather than maximising article volume.
4. Create bundled content with provenance, review status, reviewer and review date.
5. Review factual accuracy, clarity, tone and accessibility.
6. Test search, navigation, offline behavior and contextual entry points.
7. Establish a correction/withdrawal process and a review cadence.

## 10. Replaces

Replaces scattered, inconsistent searching with a coherent in-app learning reference. It does not replace specialist horticultural references, local regulations or professional advice.

## 11. Open questions

- Which named person will own horticultural review and approval? This remains a release gate; no unreviewed factual content should ship.
- What review cadence should apply to the bundled content?
- Should the guide ship with a fixed MVP set or a smaller set expanded through app updates?
- How should source citations appear in the interface?
- Which topics are essential for the first release?
- Should users be able to bookmark or save guide articles?

## 12. Delivery tracking

- GitHub implementation issue: [#23 — Plant Care Guide: curated, source-backed horticultural learning](https://github.com/melusi-k/Feed-Good/issues/23).
- Editorial owner remains unassigned; this is a release gate, not an implementation assumption.
