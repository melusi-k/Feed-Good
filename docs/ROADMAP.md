# Feed Good — Product Roadmap

This is an outcome-led sequence, not a promise of calendar dates. Every implementation PR should link to an issue and carry explicit acceptance criteria. MVP scope is deliberately limited to the capabilities below; later opportunities are not implementation commitments.

## Foundation — bootstrap

- [x] Establish product brief and initial technical direction.
- [x] Add XcodeGen project and native SwiftUI app shell.
- [x] Add the first plant model and collection screen.
- [ ] Establish CI build and test evidence.
- [ ] Add issue templates, PR standards and repository governance.

## MVP — trusted garden foundation

### Milestone 1 — My Plants and growing context
- Plant create, view, edit and delete; complete plant profiles and photos (#3).
- Basic collection search and useful sorting; avoid a complex filter builder in v1.
- Optional, skippable growing context (broad location type and observed light) (#22).
- Clear empty, validation, deletion and failure states.
- Persistence, relationship, migration and accessibility tests.

### Milestone 2 — Care Routine and reminders
- Plant-specific care tasks (watering, feeding, pruning and custom care) (#4).
- Record completed care with date and optional note.
- Clear due/overdue/upcoming presentation.
- Opt-in local notifications, permission-denied and rescheduling behavior (#5).
- Tests for date calculations, time zones and notification lifecycle.

### Milestone 3 — Plant Journal and plant story
- Dated notes and photos per plant (#12).
- Milestones such as first new leaf, flowering or repotting.
- Combined care and journal timeline (#14).
- Preserve user-authored entries through edits and app upgrades.
- Photo storage, export and deletion policy.
- Advanced side-by-side photo comparisons are a later opportunity, not an MVP dependency.

### Milestone 4 — Today and learning
- Daily mantra and practical care moment (#16).
- Thoughtful home dashboard combining today's care and plant progress (#13).
- A modest, bundled Care Guide with source provenance and editorial review (#23).
- Offline availability and contextual links from plant profiles/care tasks.
- No AI diagnosis or unsupported plant-specific recommendations.

### Milestone 5 — Settings and data portability
- Plain-language privacy and local-storage explanation.
- Notification status and route to iOS Settings.
- About/version information.
- Tested export and restore for plants, care history, journal entries and required media (#15).
- Archive validation, explicit restore confirmation and failure recovery.

## Later opportunities — discovery only

These ideas are intentionally outside MVP scope. Each requires a separate product decision, evidence of user value, a PRD and a linked issue before implementation.

- Growth progress: side-by-side photo comparisons and richer visual timelines.
- Plant health troubleshooting: symptom education and cautious possible-cause exploration; no definitive diagnosis.
- Plant identification: assisted identification with clear confidence and verification limits.
- Multiple gardens/spaces: reusable spaces and more advanced collection organisation.
- Weather-aware care and sensor integrations: only with clear consent, data quality and offline fallback.
- Shared garden access and community features.
- Home-screen widgets and Live Activities.

## Release readiness

- Product acceptance inventory and QA matrix.
- Privacy manifest and permission-purpose review.
- Accessibility audit and supported-device testing.
- Data export, deletion and recovery expectations.
- Release build, install and physical-device acceptance.

## Delivery policy

Use focused PRs and exact-head checks. Do not merge a change merely because it compiles. Record what was built, tested, manually verified and left unverified. A roadmap item is not complete until its linked issue's acceptance criteria and PRD requirements are met.
