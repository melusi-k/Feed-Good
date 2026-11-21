# PRD-002 — Care Routine

**Status:** Draft for product review  
**Release:** MVP milestone 2  
**Primary surface:** Plant Care, Plant Profile, Today

## 1. One-line goal

Help people understand what care may be useful for each plant, record what they actually do, and learn from a reliable history without treating every plant as if it follows the same schedule.

## 2. Users and use cases

- A plant owner checks which plants may need attention today.
- A user records watering, feeding, pruning or another care activity against the correct plant.
- A user looks back at the last completed care action before deciding what to do next.
- A beginner needs a plain-language explanation of why a check-in may be useful.
- A user changes a routine as seasons, conditions or personal observations change.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Care task definition | Create and edit plant-specific care tasks | [measure] | [target: valid task lifecycle tests pass] | [owner] / [date] |
| Activity recording | Record care against the correct plant with date and optional note | [measure] | [target: 100% correct plant association in test cases] | [owner] / [date] |
| Due-state calculation | Verify due, overdue and upcoming states across date boundaries | [measure] | [target: agreed date/time-zone test matrix passes] | [owner] / [date] |
| History integrity | Preserve append-oriented care activity history | [measure] | [target: edits do not silently rewrite past activity] | [owner] / [date] |
| Guidance clarity | User can explain why an action is suggested | [measure] | [target: [agreed comprehension threshold]] | [owner] / [date] |

## 4. Behavior changes

- Care tasks belong to a specific plant and may include watering, feeding, pruning and custom care.
- Separate a recurring care plan from the record of a completed action.
- Allow a user to record completion with a date and optional note.
- Present due, overdue and upcoming states in plain language; do not imply that an interval is a biological deadline.
- Show the last completed action and the next suggested check-in where available.
- Explain the reason for a suggested action and distinguish user-defined schedules from general guidance.
- Allow users to adjust or pause routines. A missed task should not trigger guilt-oriented copy or destructive catch-up behavior.
- Keep date calculations deterministic and test daylight-saving changes, time zones and calendar boundaries.
- Care history is append-oriented. Correcting an error should be explicit and must not silently erase the historical record.

## 5. Out of scope

- Automatic sensing of soil moisture, light or environmental conditions.
- Guaranteed diagnosis or treatment recommendations.
- Universal watering schedules or fixed quantities for all plants.
- Complex horticultural automation or remote expert consultation.
- Social comparisons, streak pressure or punitive gamification.

## 6. Surfaces

- Plant Care view and care-task editor.
- Plant Profile care summary and activity history.
- Today care check-in and care action entry point.
- Completion confirmation and optional note entry.
- Relevant empty, due, upcoming and overdue states.

## 7. Pricing

Included in the free initial release. Care records and scheduling are local-first; no paid service or account is required.

## 8. Safety bar

- A schedule is a reminder to inspect or consider care, not proof that the plant needs water or treatment.
- Use qualified language such as “check the soil” where conditions cannot be observed.
- Never present general guidance as verified plant-specific advice.
- Avoid harmful prescriptive quantities or diagnosis without reliable context.
- Preserve history and clearly label user-entered versus app-suggested information.
- Keep care history available offline and avoid logging private notes.

## 9. Launch plan

1. Agree the care task model, supported task types and schedule semantics.
2. Implement and test due-state calculations independently of SwiftUI views.
3. Verify activity creation, association, editing/correction and persistence.
4. Test date boundaries, time zones, daylight-saving transitions and app relaunch.
5. Validate language and interaction with beginner users [measure].
6. Ship with clear explanations and a visible distinction between schedule and observed need.

## 10. Replaces

Replaces ad hoc memory or generic recurring task lists with plant-specific routines and a traceable care history. It does not replace observation of the plant or professional advice.

## 11. Open questions

- Are schedules interval-based, calendar-based, or both?
- Which task types are included at MVP, and how are custom tasks represented?
- Does completion advance the next due date automatically, or can the user review it first?
- Can users record an activity without a pre-existing task?
- How should paused, seasonal and one-off care be represented?
- What is the correction/deletion policy for an incorrectly recorded care event?
- Which source, if any, will support species-specific care recommendations?


## 12. Delivery tracking

- GitHub implementation issue: [#4 — Care Routine: plant-specific care tasks and history](https://github.com/melusi-k/Feed-Good/issues/4).
