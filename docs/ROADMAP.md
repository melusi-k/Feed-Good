# Feed Good — Product Roadmap

This is an outcome-led sequence, not a promise of calendar dates. Every implementation PR must link to an issue and carry explicit acceptance criteria. MVP scope is deliberately limited; post-MVP proposals are not implementation commitments.

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

## Post-MVP proposal portfolio

The following issues are marked **Proposal Consistent**. That status confirms the proposal is coherent; it does not mean implementation is complete, scheduled or approved for release. Prioritisation and capacity are still planning decisions.

### A. Trust and relationship improvements
1. **PRD-011 — Care History Corrections** ([#63](https://github.com/melusi-k/Feed-Good/issues/63)) — correct a historical event without silently changing the active routine. PR #68 is merged; remaining Today, reminder and export/recovery verification is outstanding.
2. **PRD-012 — Growth Review** ([#64](https://github.com/melusi-k/Feed-Good/issues/64)) — compare existing journal photos for one plant, with dates and source observations. PR #76 is open; populated comparison and source-navigation coverage remain.
3. **PRD-013 — Weekly Garden Reflection** ([#65](https://github.com/melusi-k/Feed-Good/issues/65)) — reflect real care and observation moments without streaks, scores or guilt.
4. **PRD-014 — Plant Check-ins** ([#66](https://github.com/melusi-k/Feed-Good/issues/66)) — add a distinct observation path and reviewed offline next checks. Troubleshooting content is blocked on accountable editorial/safety ownership and approval.

### B. Data foundation and dependent collection capabilities
5. **PRD-015 — Plant Archive and Restore** ([#69](https://github.com/melusi-k/Feed-Good/issues/69)) — reversible collection state that preserves identity, story, media, care history and export/restore. Selected foundation; #63's outstanding verification gates the parent PR merge.
6. **PRD-016 — Plant Lifecycle States** ([#70](https://github.com/melusi-k/Feed-Good/issues/70)) — define minimal state vocabulary and transition table, reusing archive state from #69. #69 is a hard prerequisite; #70 also blocks #74.
7. **PRD-018 — Plant Changes Timeline** ([#72](https://github.com/melusi-k/Feed-Good/issues/72)) — capture explicit plant/environment changes. #69 is a hard compatibility prerequisite; choose typed JournalEntry metadata versus a dedicated model before implementation.
8. **PRD-021 — Optional Plant Tags** ([#75](https://github.com/melusi-k/Feed-Good/issues/75)) — lightweight user-authored collection labels. #69 is a hard compatibility prerequisite; decide multi-tag AND/OR filtering before the UI.

### C. Independent routine and journal capabilities
9. **PRD-017 — Care Routine Review** ([#71](https://github.com/melusi-k/Feed-Good/issues/71)) — review and explicitly edit existing routine settings using CareTaskEditor; growing context remains owned by Plant Profile. Blocks #74 but is not blocked by #69.
10. **PRD-019 — Plant Journal Prompts** ([#73](https://github.com/melusi-k/Feed-Good/issues/73)) — optional bundled prompts whose answers create ordinary JournalEntry records. #65 integration is optional.

### D. Coordinated care adjustment
11. **PRD-020 — Seasonal and Quiet Periods** ([#74](https://github.com/melusi-k/Feed-Good/issues/74)) — user-controlled care pause with preview and explicit resume policy. Requires both #70 lifecycle decisions and #71 routine/reminder behavior; this is an AND dependency.

## Dependency and delivery gates

- **#63 → #69 merge gate:** finish Today consistency, local reminder validity and export/recovery round-trip verification before the #69 parent PR is eligible to merge. Do not bundle #63 into #69.
- **#69 → #70, #66, #72, #75:** archive identity and relationship preservation must be established before these features are released.
- **#70 AND #71 → #74:** both lifecycle transition behavior and routine/reminder pause-resume behavior must be approved.
- **Independent of #69:** #64, #65, #71 and #73 can progress independently while respecting archived visibility and active-care restrictions.
- **Optional relationship:** #73 may integrate with #65; neither blocks the other.

## Later opportunities — explicitly deferred

- Plant identification: assisted identification with clear confidence and verification limits.
- Multiple gardens/spaces: reusable spaces and more advanced collection organisation.
- Weather-aware care and sensor integrations: only with clear consent, data quality and offline fallback.
- Shared garden access and community/social features.
- Home-screen widgets and Live Activities.
- Remote or AI diagnosis, including image-based symptom claims.

These require separate product decisions, evidence of user value, privacy/safety review, a PRD and a linked issue before implementation.

## Release readiness

- Product acceptance inventory and QA matrix.
- Privacy manifest and permission-purpose review.
- Accessibility audit and supported-device testing.
- Data export, deletion and recovery expectations.
- Release build, install and physical-device acceptance.

## Delivery policy

Use focused PRs and exact-head checks. Do not merge a change merely because it compiles. Record what was built, tested, manually verified and left unverified. A roadmap item is not complete until its linked issue's acceptance criteria and PRD requirements are met.
