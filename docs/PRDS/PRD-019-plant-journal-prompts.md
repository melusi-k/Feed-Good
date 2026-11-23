# PRD-019 — Plant Journal Prompts

**Status:** Implementation in progress; selection, cooldown and reset rules defined  
**Priority:** P2  
**Release:** Post-MVP  
**Primary surfaces:** Plant Profile, Journal, Plant Story, optional Weekly Reflection

## 1. One-line goal
Help people notice and preserve meaningful details about a plant through occasional prompts that feel like a journal companion, never another obligation.

## 2. Users and use cases
A user wants a gentle idea for what to observe or remember. A user may skip a prompt without penalty, or answer it as an ordinary journal entry linked to a plant.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| Optionality | UI tests | Prompts never block core tasks |
| Selection | Deterministic unit tests | Stable for equivalent inputs |
| Journal integration | Relationship tests | Answer creates a normal JournalEntry |
| Cooldown | State tests | Dismissed prompts do not recur too soon |
| Content quality | Editorial/accessibility review | Copy is calm and inclusive |

## 4. Behavior changes
- Provide a small curated library of plant-specific reflection prompts.
- Surface contextually from Plant Profile, Journal, Plant Story and optionally Weekly Reflection.
- Let users answer, skip, dismiss or start an ordinary journal entry.
- Ship bundled, versioned content with deterministic local selection.
- Keep prompt state minimal and independent of private journal content.

## 5. Out of scope
Streaks, points, completion rates, notifications, AI-generated prompts based on private content, diagnosis, sentiment analysis, remote CMS and automatic evaluation of answers.

## 6. Surfaces
Optional prompt card; answer-to-journal flow; skip/dismiss controls; quiet empty/cooldown state.

## 7. Pricing
Included in the local-first app. No account or network service is required.

## 8. Safety and data integrity
- Skip/dismiss has no penalty and creates no failed task or progress score.
- Answering creates a normal user-authored JournalEntry linked to the selected plant and chosen date.
- Do not create a separate answer store or copy journal text into prompt state.
- Prompt IDs remain stable across content revisions; define a version/revision strategy.
- Do not inspect or infer sentiment from private journal text.
- Works without photos, network access or notification permission.
- Archived plant presentation must not offer active-care actions.

## 9. Launch plan
1. Curate and editorially review the initial prompt set.
2. Define stable IDs, content revision and deterministic selection inputs.
3. Define cooldown and reset rules.
4. Implement answer/skip/dismiss and normal JournalEntry creation.
5. Test selection, stable IDs, cooldown, state reset and journal relationships.
6. Complete UI, accessibility and editorial review.

## 10. Replaces
Replaces the absence of occasional guided observation ideas. It does not replace free-form Journal entries.

## 11. Decisions and dependencies
- Builds on Plant Journal #12 and bundled content conventions.
- **Defined rules (recorded with implementation):** Prompt IDs are stable slugs (`prompt.<slug>`) with a single `contentVersion` integer bumped when the bundled set changes; selection is deterministic over a djb2 hash of `plantID|civil-day` (Gregorian, local timezone, the DailyMoments convention) modulo the eligible set, so the same plant, day and prompt state always produce the same prompt without Swift's seeded hashing. Dismissed prompts are excluded for 14 civil days and return on their own; `reopen` reverses a dismissal immediately. Skip and answer both record one interaction day per plant and hide the card only for that plant that day; neither carries a penalty. Prompt state is presentation-only (UserDefaults), excluded from archives, and stores no answers or journal text.
- PRD-013 Weekly Reflection / issue #65 is an optional integration only; neither blocks the other.
- Not dependent on PRD-015, PRD-016 or PRD-020, but respects archived visibility.
- Dismissal/last-shown metadata is minimal local presentation state and must not duplicate journal content.

## 12. Delivery tracking
- GitHub issue: [#73 — Add optional plant-specific journal prompts](https://github.com/melusi-k/Feed-Good/issues/73).
- Status: proposal consistent; implementation outstanding.
