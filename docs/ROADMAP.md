# Feed Good — Initial Roadmap

This is an outcome-led sequence, not a promise of calendar dates. Every implementation PR should link to an issue and carry explicit acceptance criteria.

## Foundation — bootstrap

- [x] Establish product brief and initial technical direction.
- [x] Add XcodeGen project and native SwiftUI app shell.
- [x] Add the first plant model and collection screen.
- [ ] Establish CI build and test evidence.
- [ ] Add issue templates, PR standards and repository governance.

## Milestone 1 — My Plants

- Plant create, view, edit and delete.
- Plant profile: name, species/common name, photo and notes.
- Empty, loading and error states.
- Persistence and relationship tests.
- Accessibility and visual QA.

## Milestone 2 — Care Routine

- Plant-specific care tasks (watering, feeding, pruning and custom care).
- Record completed care with date and optional note.
- Clear due/overdue/upcoming presentation.
- Opt-in local notifications, permission-denied and rescheduling behavior.
- Tests for date calculations, time zones and notification lifecycle.

## Milestone 3 — Plant Journal

- Dated notes and photos per plant.
- Milestones such as first new leaf, flowering or repotting.
- Preserve user-authored entries through edits and app upgrades.
- Photo storage, export and deletion policy.

## Milestone 4 — Feed Good daily experience

- Daily mantra and practical care tip.
- Thoughtful home dashboard combining today's care and plant progress.
- Content provenance and review process for horticultural guidance.
- Offline availability.

## Release readiness

- Product acceptance inventory and QA matrix.
- Privacy manifest and permission-purpose review.
- Accessibility audit and supported-device testing.
- Data export, deletion and recovery expectations.
- Release build, install and physical-device acceptance.

## Delivery policy

Use focused PRs and exact-head checks. Do not merge a change merely because it compiles. Record what was built, tested, manually verified and left unverified.
