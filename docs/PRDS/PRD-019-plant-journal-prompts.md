# PRD-019 — Plant-Specific Journal Prompts

**Status:** Proposed for post-MVP product review  
**Priority:** P2 relationship feature  
**Release:** After Weekly Garden Reflection tone review  
**Primary surfaces:** Plant Profile, Journal, Plant Story, Today

## 1. One-line goal

Help people notice and preserve meaningful details through occasional, optional prompts that feel like a journal companion rather than an obligation.

## 2. Users and use cases

A beginner does not know what is worth recording. An experienced user wants a thoughtful nudge to notice a plant's season or change. A user wants to answer a prompt in the normal Journal without completing a task or maintaining a streak.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Prompt usefulness | Users understand and can skip prompts | [measure] | [target: content review passes] | [owner] / [date] |
| Journal continuity | Prompt answer becomes a normal entry | [measure] | [target: relationship tests pass] | [owner] / [date] |
| Pressure avoidance | No obligation or guilt language | [measure] | [target: content/accessibility review passes] | [owner] / [date] |
| Offline behavior | Bundled prompts work without network | [measure] | [target: offline UI journey passes] | [owner] / [date] |

## 4. Behavior changes

- Offer a small library of bundled prompts related to noticing, change, care context and seasonal reflection.
- Surface prompts from Plant Profile, Journal, Plant Story or Weekly Reflection without creating a mandatory notification stream.
- Let users answer, skip or dismiss a prompt.
- Start the normal journal-entry flow with the selected prompt as optional context.
- Avoid repeating dismissed prompts too aggressively through lightweight local state.
- Keep selection deterministic and local-first, with stable prompt IDs for content updates.

## 5. Out of scope

- Streaks, completion rates, points or compliance reminders.
- AI-generated prompts, sentiment analysis or response evaluation.
- Remote content delivery or a large content CMS.
- Diagnosis or automatic interpretation of responses.

## 6. Surfaces

- Optional prompt card or entry point.
- Prompt selection/detail state.
- Normal journal editor with optional prompt context.
- Skip, dismiss and empty states.

## 7. Pricing

Included in the local-first app. No account, subscription or network service is required.

## 8. Safety bar

- Prompts invite observation and have no correct answer.
- Skipping has no negative consequence and never creates a missed task.
- Do not expose journal responses in notifications or analytics.
- Keep prompt content reviewed, calm and accessible.
- Support no-photo, no-network and notification-denied use.

## 9. Launch plan

1. Create and review a small bundled prompt set.
2. Define stable IDs, dismissal behavior and cadence limits.
3. Integrate with the existing Journal flow without a duplicate entry model.
4. Add tests for plant association, offline behavior and dismissal state.
5. Review tone, accessibility, Dynamic Type and physical-device behavior.

## 10. Replaces

Replaces the blank-page problem for some journal users. It does not replace the Journal, Weekly Reflection or care reminders.

## 11. Decisions and open questions

Decide whether prompts are only user-invoked or can appear as a quiet Today card. The safer starting point is contextual and optional presentation, with no notification permission dependency. Product review should also decide whether Weekly Reflection may reuse the prompt catalog.

## 12. Delivery tracking

- GitHub implementation issue: [#73 — Add optional plant-specific journal prompts](https://github.com/melusi-k/Feed-Good/issues/73).
- Existing PRD: [PRD-004 — Plant Journal](PRD-004-plant-journal.md).
- Related proposal: [PRD-013 — Weekly Garden Reflection](PRD-013-weekly-garden-reflection.md).
