# PRD-005 — Today

**Status:** Draft for product review  
**Release:** MVP milestone 4  
**Primary surface:** Today tab / home experience

## 1. One-line goal

Give people a calm daily check-in that helps them see what matters in their garden, take one useful action and notice progress without feeling managed by a task dashboard.

## 2. Users and use cases

- A user opens Feed Good and wants to know whether anything in their garden deserves attention.
- A beginner needs a simple, non-intimidating starting point for caring for their plants.
- A returning user wants to see recent growth or a meaningful journal moment.
- A user wants to move from a summary into a specific plant, care action or journal entry.
- A user with no plants needs a welcoming explanation and a clear first step.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Daily relevance | Show only relevant care and garden information | [measure] | [target: agreed relevance rubric] | [owner] / [date] |
| Care accuracy | Summary matches underlying plant/task state | [measure] | [target: no mismatch in deterministic test set] | [owner] / [date] |
| Navigation | Open the correct plant or action from each summary item | [measure] | [target: all primary routes pass UI tests] | [owner] / [date] |
| Empty garden | Guide a new user to add their first plant | [measure] | [target: first-plant journey passes usability check] | [owner] / [date] |
| Calm experience | Avoid unnecessary urgency, clutter and guilt | [measure] | [target: product/design review checklist passes] | [owner] / [date] |

## 4. Behavior changes

- Today is a thoughtful daily check-in, not a complete task-management backlog.
- Prioritise a warm welcome and daily reflection, the most relevant care check-in, a visual view of the user's plants and a recent journal moment or prompt.
- Show due, upcoming and overdue care with context and plain-language explanations.
- Do not show every task merely to fill the screen; relevance is more important than volume.
- Provide direct routes to the relevant plant, care action or journal entry.
- Adapt the empty state for a user who has not added plants.
- Handle no care due, no journal history, disabled notifications and offline use gracefully.
- Use the user's local calendar context for daily content and date labels.
- Keep content concise and allow plant photography and meaningful moments to remain the visual focus.

## 5. Out of scope

- A social or algorithmic feed.
- Public activity, likes, comments or follower counts.
- Gamified streaks, guilt-based task completion or competitive leaderboards.
- Real-time weather or sensor dashboards unless separately approved.
- Personalized AI diagnosis or recommendations.

## 6. Surfaces

- Today tab / home screen.
- Daily care summary and plant collection preview.
- Recent journal moment or observation prompt.
- Empty, no-care-due and offline states.
- Deep links into Plant Profile, Care Routine and Plant Journal.

## 7. Pricing

Included in the free initial release. Uses local plant, care and journal data; no account or remote service is required.

## 8. Safety bar

- Never present a due task as proof that care is biologically required.
- Do not hide important context to make the dashboard appear simpler.
- Avoid urgency-red defaults and shame-oriented language.
- Do not display fabricated activity, plant health or progress.
- Ensure summaries are consistent with the underlying records and remain usable offline.
- Meet accessibility requirements in all summary and empty states.

## 9. Launch plan

1. Confirm content hierarchy and rules for what qualifies as relevant today.
2. Validate each summary against source plant, care and journal records.
3. Test empty, populated, no-care-due, overdue, offline and notification-denied states.
4. Verify navigation destinations and date labels.
5. Conduct design, accessibility and usability review [measure].
6. Ship as the primary daily entry point once dependent feature behavior is stable.

## 10. Replaces

Replaces a blank landing screen or an undifferentiated list of tasks with a context-aware daily garden check-in. It does not replace the full care schedule or plant collection.

## 11. Open questions

- Is Today the default launch destination for every session?
- What is the final ordering and weighting of care, plants, journal moments and daily content?
- What qualifies as “relevant” when many tasks are due?
- Should the screen vary by season or local weather in a later release?
- How much content should appear before scrolling?
- Which interactions should be available directly on Today versus opening a feature screen?
