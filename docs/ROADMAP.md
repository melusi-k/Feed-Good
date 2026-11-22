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

## Next development tranche — proposed post-MVP

These are the recommended next features after the MVP foundation. They are ordered by trust and relationship value, not by novelty:

1. **Care History Corrections** ([PRD-011](PRDS/PRD-011-care-history-corrections.md), [Issue #63](https://github.com/melusi-k/Feed-Good/issues/63)) — repair a mistaken event without silently changing the active schedule. Recommended policy: history-only correction by default.
2. **Growth Review** ([PRD-012](PRDS/PRD-012-growth-review.md), [Issue #64](https://github.com/melusi-k/Feed-Good/issues/64)) — compare existing journal photos for one plant, with source dates and no visual diagnosis.
3. **Weekly Garden Reflection** ([PRD-013](PRDS/PRD-013-weekly-garden-reflection.md), [Issue #65](https://github.com/melusi-k/Feed-Good/issues/65)) — reflect real care and observation moments without streaks, scores or guilt.
4. **Plant Check-ins and Cautious Troubleshooting** ([PRD-014](PRDS/PRD-014-plant-check-ins.md), [Issue #66](https://github.com/melusi-k/Feed-Good/issues/66)) — add an observation path and reviewed offline next checks, gated on editorial and safety ownership.

Each item requires its own focused implementation PR, exact-head CI verification, accessibility review, archive compatibility review and physical-device evidence. The PRDs define intended behavior; they do not authorize implementation without product review.

## Later opportunities — explicitly deferred

These ideas remain discovery-only and should not be pulled into the next tranche:

- Plant identification: assisted identification with clear confidence and verification limits.
- Multiple gardens/spaces: reusable spaces and more advanced collection organisation.
- Weather-aware care and sensor integrations: only with clear consent, data quality and offline fallback.
- Shared garden access and community/social features.
- Home-screen widgets and Live Activities.
- Remote or AI diagnosis, including image-based symptom claims.

They require separate product decisions, evidence of user value, privacy/safety review, a PRD and a linked issue before implementation. Their deferral protects Feed Good's relationship-first, local-first direction while the current core loop matures.

## Release readiness

- Product acceptance inventory and QA matrix.
- Privacy manifest and permission-purpose review.
- Accessibility audit and supported-device testing.
- Data export, deletion and recovery expectations.
- Release build, install and physical-device acceptance.

## Delivery policy

Use focused PRs and exact-head checks. Do not merge a change merely because it compiles. Record what was built, tested, manually verified and left unverified. A roadmap item is not complete until its linked issue's acceptance criteria and PRD requirements are met.
