# Feed Good — Product Roadmap

This is an outcome-led sequence, not a promise of calendar dates. Every implementation PR must link to an issue and carry explicit acceptance criteria. Post-MVP proposals are delivered in dependency-aware stages; a proposal being consistent does not mean implementation is complete.

## Foundation — bootstrap

- [x] Establish product brief and initial technical direction.
- [x] Add XcodeGen project and native SwiftUI app shell.
- [x] Add the first plant model and collection screen.
- [x] Establish CI build and test evidence.
- [x] Add issue templates, PR standards and repository governance.

## MVP — trusted garden foundation

### Milestone 1 — My Plants and growing context
- [x] Plant create, view, edit and delete; complete plant profiles and photos (#3).
- [x] Basic collection search and useful sorting.
- [x] Optional, skippable growing context (#22).

### Milestone 2 — Care Routine and reminders
- [x] Plant-specific care tasks (#4).
- [x] Record completed care with date and optional note.
- [x] Optional local notifications and reminder lifecycle (#5).

### Milestone 3 — Plant Journal and plant story
- [x] Dated notes and photos per plant (#12).
- [x] Milestones and combined care/journal timeline (#14).

### Milestone 4 — Today and learning
- [x] Today dashboard (#13).
- [x] Feed Good Moments (#16).
- [x] Bundled offline Care Guide (#23).

### Milestone 5 — Settings and data portability
- [x] Settings, privacy transparency and tested export/restore (#15).
- [x] Reversible Plant Archive and Restore (#69 / PRD-015).
- [x] Care History Corrections (#63).
- [x] Growth Review (#64).

## Phase 1 — trust and data foundation (complete, 2026-11-23)

- [x] Plant archive/restore and legacy-store migration (#69; parent PR #88).
- [x] Care history correction verification (#63).
- [x] Growth Review device verification (#64).
- [x] Care Routine Review foundation (#71; PR #82), integrated with archive-aware behavior in PR #88.
- [x] Owner-confirmed archive/restore, offline, Dynamic Type, light/dark and accessibility checks.
- [x] PRD-015 completion record merged to main (PR #91).

## Phase 2 — relationship and care-context improvements

Phase 2 is active. Work is staged by dependency and design gates; implementation does not start while required product decisions remain unresolved.

### Stage 1 — Lifecycle vocabulary and transition contract
1. **PRD-016 / #70 — Plant Lifecycle States.** Review the Active/Archived transition table and decide whether a genuinely distinct additional state is justified. Reuse the existing `Plant.archivedAt` contract; never add a duplicate archive flag. The proposed Active/Archived-only model is awaiting product approval.
2. Resolve #70 before starting #74 implementation.

### Stage 2 — Quiet-period design and implementation
3. **PRD-020 / #74 — Seasonal and Quiet Periods.** Starts only after #70's lifecycle contract and #71's routine/reminder behavior are both resolved. Required design decisions: due-date pause/resume policy, open-ended periods, all-vs-selected tasks, and lifecycle constraints.

### Parallel relationship capabilities (can be separately prioritised)
- **PRD-014 / #66 — Plant Check-ins.** Data/observation work may proceed; troubleshooting guidance cannot ship until an accountable editorial/safety owner, source rules and content review are approved.
- **PRD-018 / #72 — Plant Changes Timeline.** Decide typed JournalEntry metadata vs a dedicated model before implementation; preserve offline and archive/export behavior.
- **PRD-021 / #75 — Optional Plant Tags.** Decide normalization and multi-tag AND/OR filtering before filter UI implementation; preserve active and archived relationships.
- **PRD-013 / #65 — Weekly Garden Reflection.** Derived local reflection only; no second activity ledger, scores or streaks.
- **PRD-019 / #73 — Plant Journal Prompts.** Optional bundled prompts; answers create ordinary JournalEntry records. #65 integration remains optional.

## Dependency and delivery gates

- **#69 complete → #70, #66, #72, #75:** archive identity and relationship preservation is available on main.
- **#70 AND #71 → #74:** both lifecycle transition behavior and routine/reminder pause-resume behavior must be approved.
- **#71 is implemented:** PR #82 is merged; archive-aware routing is part of PR #88.
- **#66 safety gate:** no troubleshooting content ships without editorial ownership, provenance and review.
- **#72 model gate:** choose the source-of-truth model before adding persistence.
- **#75 query gate:** decide tag normalization and multi-tag filtering semantics before UI delivery.
- **#65 and #73:** independent of the lifecycle/quiet-period critical path; #73 may optionally integrate with #65.

## Later opportunities — explicitly deferred

- Plant identification, multiple gardens/spaces, shared access, weather-aware care, sensors, widgets and Live Activities.
- Remote or AI diagnosis, including image-based symptom claims.

These require separate product decisions, evidence of user value, privacy/safety review, a PRD and a linked issue before implementation.

## Release readiness

- Product acceptance inventory and QA matrix.
- Privacy manifest and permission-purpose review.
- Accessibility audit and supported-device testing.
- Data export, deletion and recovery expectations.
- Release build, install and physical-device acceptance.

## Delivery policy

Use focused PRs and exact-head checks. Do not merge a change merely because it compiles. Record automated, simulator and physical-device evidence separately. A roadmap item is not complete until its linked issue's acceptance criteria and PRD requirements are met.
