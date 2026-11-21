# PRD-006 — Feed Good Moments

**Status:** Draft for product review  
**Release:** MVP milestone 4  
**Primary surface:** Today and contextual plant-care moments

## 1. One-line goal

Make plant care feel encouraging and rewarding through short daily mantras and practical tips that help people notice, understand and enjoy their plants.

## 2. Users and use cases

- A user opens the app and finds a brief thought that makes plant care feel approachable.
- A beginner learns one useful, understandable care concept.
- A user receives a gentle prompt to observe a plant rather than blindly complete a task.
- A returning user encounters fresh content without being overwhelmed by notifications or a noisy feed.
- A user needs to distinguish an encouraging reflection from factual horticultural guidance.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Content quality | Review content for clarity, warmth and usefulness | [measure] | [target: editorial rubric approved] | [owner] / [date] |
| Factual reliability | Verify practical tips against trusted sources | [measure] | [target: every factual tip has provenance and review] | [owner] / [date] |
| Daily selection | Select appropriate content for the local day | [measure] | [target: deterministic selection and date tests pass] | [owner] / [date] |
| Offline availability | Display content without network access | [measure] | [target: full MVP content set available offline] | [owner] / [date] |
| Tone | Avoid guilt, pressure and unsupported certainty | [measure] | [target: content review checklist passes] | [owner] / [date] |

## 4. Behavior changes

- Distinguish a mantra or reflection from an actionable care tip.
- Mantras may be reflective and encouraging; factual tips must be reviewed and traceable to an appropriate source.
- Keep content short, accessible and relevant to the daily garden experience.
- Use a curated, bundled content set for the initial offline-first release unless remote content is separately approved.
- Avoid repeating content too frequently where a deterministic local selection strategy can prevent it.
- Do not personalise factual recommendations beyond the plant information and evidence available.
- Pair tips with an observation or an optional next step where useful; do not turn every moment into a task.
- Content must remain available without network access.

## 5. Out of scope

- User-generated public content or community submissions.
- Remote AI-generated horticultural advice.
- Push campaigns, marketing notifications or engagement streaks.
- Personalised diagnosis or treatment recommendations.
- A continuously scrolling content feed.

## 6. Surfaces

- Daily mantra / reflection on Today.
- Practical care tip on Today or a relevant care surface.
- Optional contextual prompt in Plant Profile or Plant Journal.
- Content fallback and offline presentation.

## 7. Pricing

Included in the free initial release. Initial content is bundled with the app; no subscription or remote content service is required.

## 8. Safety bar

- Factual horticultural tips require editorial review and source provenance.
- Clearly distinguish general education from plant-specific guidance.
- Do not present a mantra as factual advice.
- Avoid unsafe or overconfident instructions, including prescriptive watering quantities without context.
- No guilt, shame or claims that a user has failed their plant.
- Provide a way to correct or remove content found to be inaccurate in a future content update process.

## 9. Launch plan

1. Define the editorial voice and separate reflection content from factual guidance.
2. Build a reviewed, bundled content set with source and review metadata for factual tips.
3. Review content for horticultural accuracy, accessibility and tone.
4. Test daily selection, date changes, repeat behavior and offline fallback.
5. Include a content review owner and update process before adding new tips.
6. Launch with a modest, reviewed set rather than optimising for volume.

## 10. Replaces

Replaces generic filler or an empty home-screen message with a distinctive, supportive daily moment. It does not replace care instructions, a horticultural reference or expert advice.

## 11. Open questions

- Is daily content bundled permanently for v1, or can app updates refresh it?
- What is the minimum viable content library and how often may an item repeat?
- Who owns horticultural review and source approval?
- Should users be able to save or revisit past mantras and tips?
- Should content vary by season, hemisphere or known plant collection?
- Is content attribution displayed in the UI, in an about/source view, or both?
