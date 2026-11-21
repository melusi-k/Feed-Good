# PRD-003 — Care Reminders

**Status:** Draft for product review  
**Release:** MVP milestone 2  
**Primary surface:** iOS local notifications and in-app reminder preferences

## 1. One-line goal

Help people remember useful plant check-ins through optional, dependable local notifications that remain respectful, understandable and fully under the user's control.

## 2. Users and use cases

- A user chooses to receive reminders for selected plant-care routines.
- A user grants or declines notification permission without losing access to the app.
- A user changes a care schedule and expects pending reminders to reflect the change.
- A user pauses or disables reminders when they are away or no longer want notifications.
- A user taps a notification and expects to reach the relevant plant or care context.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Opt-in permission | Request authorization only in a relevant context | [measure] | [target: no premature or repeated prompts] | [owner] / [date] |
| Scheduling | Schedule a notification for the intended plant/task and local time | [measure] | [target: agreed scheduling test matrix passes] | [owner] / [date] |
| Rescheduling | Update or cancel pending notifications after routine changes | [measure] | [target: no stale reminder in lifecycle tests] | [owner] / [date] |
| Permission denial | App remains fully usable when notifications are denied | [measure] | [target: core journeys pass without authorization] | [owner] / [date] |
| Notification routing | Tapping a reminder opens relevant in-app context | [measure] | [target: correct destination in UI tests] | [owner] / [date] |

## 4. Behavior changes

- Reminders are opt-in and use iOS UserNotifications for local delivery.
- Explain the value of reminders before asking for notification permission.
- Do not request permission on first launch without context.
- Keep reminder configuration separate from the operating system's notification delivery/authorization state.
- Schedule, update and cancel pending notifications when a routine is created, changed, paused or deleted.
- Avoid duplicate and stale notifications; use stable identifiers tied to the relevant plant and care task.
- Respect local time and calendar behavior. Reconcile pending notifications when schedules change or the app next runs.
- If permission is denied, provide a clear explanation and a route to system Settings without blocking core functionality.
- Notification content should be concise, kind and specific enough to identify the plant and suggested check-in.
- Tapping a notification should route to the relevant plant or care action where possible.

## 5. Out of scope

- Remote push notifications or server-side scheduling.
- Email, SMS or third-party messaging.
- Shared reminders across household members.
- Location-triggered or sensor-triggered alerts.
- Urgent plant-health warnings or claims that a plant is in danger.

## 6. Surfaces

- Contextual permission explanation.
- iOS notification authorization prompt.
- In-app reminder controls in care settings or the relevant plant/task flow.
- Notification Center presentation.
- Deep link / app navigation destination after notification interaction.
- Permission-denied and disabled states.

## 7. Pricing

Included in the free initial release. Uses the operating system's local notification capability; no subscription, account or server is required.

## 8. Safety bar

- Never make notification permission mandatory.
- Never imply that missing a notification means a plant will be harmed.
- Do not expose sensitive journal notes in notification previews.
- Use respectful, non-urgent language unless a future, evidence-backed use case is explicitly approved.
- Do not create notification loops or excessive duplicate reminders.
- Ensure notification denial, disabled alerts and Focus settings do not break the app.

## 9. Launch plan

1. Agree notification preference scope and default behavior.
2. Test authorization granted, denied, provisional where applicable, and later changed in Settings.
3. Test schedule create/update/pause/delete and app relaunch.
4. Verify time-zone changes, daylight-saving boundaries and duplicate prevention.
5. Test notification tap routing on supported iOS versions and physical devices.
6. Ship with notifications off until the user opts in; document the permission rationale.

## 10. Replaces

Replaces reliance on memory alone for users who opt in. It does not replace the in-app care schedule, observation or a user's own judgment.

## 11. Open questions

- Are reminders configured per care task, per plant, or through a global preference plus task-level controls?
- What are the default reminder time and delivery behavior?
- Should users be able to set quiet hours or snooze?
- How should overdue tasks be represented without sending repeated notifications?
- What reconciliation should happen after reinstall, device restore or significant time-zone changes?
- Which notification preview details are safe and useful?


## 12. Delivery tracking

- GitHub implementation issue: [#5 — Local care reminders and notification lifecycle](https://github.com/melusi-k/Feed-Good/issues/5).
