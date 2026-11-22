# PRD-020 — Seasonal and Quiet Periods

**Status:** Proposal consistent; pause/resume policy design gate open  
**Priority:** P2  
**Release:** Post-MVP, after lifecycle and routine-review decisions  
**Primary surfaces:** Plant Profile, Care Routine, Today, local reminders, Plant Story

## 1. One-line goal
Let users intentionally adjust care expectations for a plant during a seasonal or temporary quiet period without relying on weather, location or missed-care assumptions.

## 2. Users and use cases
A user wants to pause selected care tasks while a plant is resting or while they are away. They need to understand the effect on due dates, Today and reminders and know how care resumes.

## 3. Capability targets
| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| User control | UI tests | Explicit start/edit/end/cancel |
| Impact clarity | Product review | Affected tasks and reminders previewed |
| Date behavior | Calendar tests | Approved pause/resume policy is deterministic |
| Data integrity | Persistence/export tests | History and records preserved |
| Notification behavior | Reminder tests | Permission and settings respected |

## 4. Behavior changes
- Provide an explicit optional quiet-period action for an active plant.
- Capture start date, optional end date or explicitly open-ended period, user-selected reason/label and affected care tasks.
- Preview effects on each affected task, Today item and local reminder before confirmation.
- Allow edit, early end and cancellation.
- Preserve quiet-period history in Plant Story and export/restore.
- Keep ordinary journal observations available during a quiet period.

## 5. Out of scope
Automatic seasonal schedules, weather-aware automation, location inference, dormancy diagnosis, universal winter rules and replacement of routine review.

## 6. Surfaces
Quiet-period setup/editor; task-selection and impact preview; confirmation; active-period indicator; end/cancel flow; Plant Story history.

## 7. Pricing
Included in the local-first app. No account, network or location permission is required.

## 8. Safety and data integrity
- Never silently infer, start or end a quiet period.
- Open-ended periods remain open until the user ends them; they do not silently expire or generate overdue guilt states.
- Journal observations remain available and do not automatically end the period.
- Quiet periods do not delete or rewrite care history, journal content or photos.
- Ending/cancelling follows the approved policy and current reminder permission/settings.
- Archived plants cannot start or actively run care quiet periods.
- Lifecycle state, archive state and quiet period are separate concepts.

## 9. Launch plan
1. Resolve the required pause/resume policy decisions.
2. Define behavior for tasks due during an open-ended period.
3. Decide whether all tasks or selected tasks can be affected.
4. Define lifecycle constraints and the transition table.
5. Implement preview, explicit confirmation, edit/end/cancel and reminder reconciliation.
6. Test date boundaries, DST/time zones, pause/resume, cancellation, archive compatibility, export/restore and permission-denied behavior.
7. Complete accessibility and physical-device review.

## 10. Replaces
Replaces informal or ambiguous handling of a temporary care pause. It does not replace archive, lifecycle state or routine editing.

## 11. Decisions and dependencies
- Hard AND prerequisites: PRD-016 / issue #70 lifecycle vocabulary and transition behavior **and** PRD-017 / issue #71 routine editing/reminder reconciliation policy.
- Builds on Care Routine #4 and Care Reminders #5.
- Related to PRD-015 archive; archived plants cannot have active quiet periods.
- Required design decisions: preserve prior due date vs shift by duration vs require explicit new date on resume; handling of due tasks in open-ended periods; all-vs-selected tasks; lifecycle constraints.
- No implementation should begin by silently choosing one of these policies.

## 12. Delivery tracking
- GitHub issue: [#74 — Add explicit seasonal and quiet-period support](https://github.com/melusi-k/Feed-Good/issues/74).
- Status: proposal consistent; required design decisions and implementation outstanding.
