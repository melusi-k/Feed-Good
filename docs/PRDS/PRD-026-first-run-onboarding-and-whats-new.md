# PRD-026 — First-Run Onboarding and Release What's New

**Status:** Product-approved scope; implementation in progress  
**Stage:** MVP — first-use experience and release communication  
**Priority:** P1 — foundational first-use and release-awareness experience  
**Release:** MVP; release notes are maintained for each subsequent app release  
**Primary surfaces:** App launch, onboarding presentation, What's New sheet, existing Add Plant flow

## 1. One-line goal

Introduce Feed Good clearly and warmly on a genuine first launch, let users choose how to begin without setup friction, and keep returning users informed about meaningful changes in each new release.

## 2. Users and use cases

- A new user wants to understand Feed Good's purpose before entering the app.
- A new user wants to add a first plant immediately, without completing a questionnaire or configuring the app.
- A new user wants to explore the app before adding any plants.
- A returning user wants a concise explanation of what changed after installing a new release.
- A user wants to skip onboarding or dismiss release notes without losing access to the app.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| First-use clarity | New user can identify the app's promise and the purpose of its three primary tabs | [measure] | [target: copy and usability review approved] | [owner] / [date] |
| Low-friction entry | User can skip onboarding or enter the app without adding a plant | [measure] | [target: all three pages skippable; both final choices work] | [owner] / [date] |
| First-plant handoff | Add-first-plant action opens the existing Add Plant flow without an extra onboarding form | [measure] | [target: existing plant creation and validation tests pass] | [owner] / [date] |
| First-run eligibility | Onboarding is limited to a genuine first launch and is not replayed on app updates | [measure] | [target: fresh-install and upgrade scenarios pass] | [owner] / [date] |
| Release awareness | A release with notes is presented once after an upgrade | [measure] | [target: version gating, dismissal and relaunch tests pass] | [owner] / [date] |
| Privacy and permissions | First-run flow requires no account, setup questionnaire, notification permission or network | [measure] | [target: offline and permission-denied journeys pass] | [owner] / [date] |
| Accessibility | All pages and release notes support assistive technology and text scaling | [measure] | [target: VoiceOver, Dynamic Type and appearance review passes] | [owner] / [date] |

## 4. Behavior changes

### A. First-run onboarding

On a genuine fresh installation, present exactly three skippable pages in this order. The experience is part of the Feed Good visual and editorial theme: calm, warm, plant-centred and encouraging.

**Page 1 — Welcome**

- Show the Feed Good icon or a suitable plant-themed mark.
- Promise: **“Care for your plants, one day at a time.”**
- Communicate three benefits:
  - **Know what to do today** — a clear, calm daily check-in.
  - **Every plant has a story** — care, observations and milestones belong to each plant.
  - **Private and local-first** — personal garden information stays on the device; no account is required.
- Keep the promise and three points concise and scannable.

**Page 2 — How it works**

Explain the three primary destinations in one line each:

- **Today:** A daily view of care that needs attention, recent moments and useful guidance.
- **My Plants:** The user's plant collection, profiles and plant-specific care.
- **Journal:** Notes, photos and milestones that build each plant's story.

**Page 3 — Get started**

Present two clear choices:

- **Add your first plant** — open the existing Add Plant flow directly.
- **Explore first** — dismiss onboarding and enter the normal app experience.

The user must be able to skip from every page. Provide a clear progress indicator and a simple Continue action on the first two pages. Do not make the user complete all pages to access the app.

### B. First-run boundaries

- Do not request or require account creation, sign-in, subscription or network access.
- Do not ask onboarding setup questions or introduce a separate Garden Setup questionnaire.
- Do not ask for notification permission during onboarding.
- Do not request a plant, species, growing environment, light condition, location or care preference as a condition of entering the app.
- Do not create a care routine, care task or reminder automatically.
- Do not add a mandatory plant-catalogue selection step.
- Choosing **Add your first plant** must hand off to the existing Add Plant flow and its existing validation. Any existing optional fields remain optional under their owning PRDs.
- Choosing **Explore first** must open the normal app tabs with no plant required.
- Reminders remain opt-in and are offered contextually from a plant's care setup, under PRD-003.
- Onboarding completion state is separate from plant data and from the What's New seen-version state.
- Mark onboarding complete when the user skips or chooses either final action. If the app is interrupted before a deliberate exit, onboarding remains pending for the next launch.
- Show onboarding once for a genuine fresh installation only. An existing installation receiving an app update must not be treated as a first-time user merely because the onboarding feature has been introduced or its state key is absent.

### C. What's New in this release

What's New is a separate, release-driven experience, not a fourth onboarding page.

- Present it once after an app update when the installed release has a matching bundled release-notes entry and that release has not already been acknowledged.
- Do not show What's New on a fresh installation. First-run onboarding covers that journey.
- If both onboarding and release notes are pending on a device, finish or skip onboarding first, then present What's New. Do not present two sheets simultaneously.
- Keep its persisted seen-version state independent from onboarding completion. A user skipping onboarding must not accidentally mark release notes as seen, and dismissing release notes must not reset onboarding.
- Identify an installed build using the app's version identity (marketing version and build number); use the marketing version to find the bundled release-notes entry. Routine CI builds stamp the marketing version with the workflow run number so every build is identifiable and the release path is validated end to end; a product release sets the marketing version deliberately and adds its bundled notes before shipping. A build whose marketing version has no bundled entry presents the newest bundled release's notes, labelled with that release's version, rather than no sheet. Each newly installed build remains independently acknowledgeable, as required by the version identity.
- Each release that is intended to show What's New must include a matching local release-notes entry. Include a concise version label and a short list of factual highlights.
- Bundle release notes in the app. They must be available offline and must not require a remote service.
- Use a data-driven release-notes model so adding or changing release highlights does not require changing the presentation view.
- Provide an explicit Continue/dismiss action. Standard sheet dismissal may also be supported; every accepted dismissal records that release as seen.
- A release with no matching notes entry does not display an empty What's New sheet.
- Reopening the same installed release after acknowledgement must not show the sheet again.

### D. Launch orchestration

- On a fresh installation, show onboarding first. After the user chooses Add your first plant or Explore first, continue into the relevant existing app flow. Do not show What's New for the fresh install.
- On an existing installation upgrading to a release with unseen notes, do not show first-run onboarding; show What's New once, then enter the app.
- If an existing user has a genuinely pending first-run onboarding state and a release-notes entry is also pending, onboarding has presentation priority. The two experiences retain independent state.
- Returning users with neither experience pending go directly to the normal app.
- Launch orchestration may coordinate presentation order, but it must not combine the underlying onboarding and release-note persistence models.

## 5. Out of scope

- A first-run garden questionnaire, growing-context wizard or mandatory profile completion.
- Plant creation, plant editing or plant validation logic beyond handing off to the existing Add Plant flow.
- Care routine creation, reminder scheduling or notification permission requests during onboarding.
- Account creation, authentication, cloud sync, remote configuration or server-driven release notes.
- Personalised marketing, promotional offers, ratings prompts or analytics consent screens.
- Replacing Today, My Plants, Journal or any existing app destination.
- A new plant model, garden model or persistence schema solely for onboarding.
- Replaying onboarding after an app update, for returning users, or because a release notes entry changed.

## 6. Surfaces

- Three-page first-run onboarding presentation.
- Skip action available on every onboarding page.
- Progress indicator and Continue action on the first two pages.
- Final Add your first plant and Explore first actions.
- Existing Add Plant sheet or route.
- Existing app tab experience.
- Separate What's New sheet containing the release version and highlight rows.
- No new persistent plant-data surface is introduced.

## 7. Pricing

Included in the free, local-first Feed Good experience. No account, subscription, network service or paid onboarding tier is required. What's New is informational release communication, not a promotional paywall.

## 8. Safety and privacy bar

- Do not block access to the app based on account, plant, location, care or notification setup.
- Do not imply that the app measures environmental conditions or independently knows what a plant needs.
- Describe privacy and local-first behavior accurately; do not promise security properties beyond the app's actual storage and data practices.
- Do not request notification permission until the user opts into reminders from a plant's care setup.
- Do not include private plant names, journal text, photos or other user content in release notes or notifications.
- Keep onboarding and release notes fully usable offline.
- Support VoiceOver with meaningful headings and labels, Dynamic Type without clipped content, sufficient contrast, light and dark appearance, and comfortable touch targets.
- Ensure Skip, Add your first plant, Explore first and What's New dismissal are accessible and have deterministic outcomes.
- Do not lose or modify existing plant, care or journal data when onboarding or release notes are presented or dismissed.

## 9. Launch plan

1. Confirm the exact onboarding copy, icon/illustration, page layout and Feed Good design-token usage.
2. Implement the three pages as a presentation layer only; reuse existing navigation and Add Plant behavior.
3. Define and test fresh-install detection so existing installations are not incorrectly shown first-run onboarding when upgrading.
4. Persist onboarding completion independently from release-notes acknowledgement.
5. Implement release-note lookup and once-per-release gating using bundled entries and the app's version identity.
6. Define launch sequencing for fresh installs, existing installs upgrading, users with pending onboarding, users with pending release notes and returning users.
7. Add unit tests for state transitions, version lookup, fresh-install suppression, update detection, repeated launches and dismissal persistence.
8. Add UI tests for all three pages, Skip from each page, both final actions, Add Plant handoff, Explore first, upgrade presentation and fresh-install suppression.
9. Verify offline behavior, VoiceOver, Dynamic Type, light/dark appearance and physical-device launch behavior.
10. Verify reminders remain opt-in and no notification prompt appears before a user enters plant care setup.

## 10. Replaces

Replaces an unexplained first app launch with a concise introduction and a user-controlled starting choice. Replaces ad hoc release announcements with a consistent, version-aware What's New experience. It does not replace plant setup, care setup, reminders or the app's core destinations.

## 11. Decisions and open questions

1. The three-page structure, page order, skippability and final choices are approved product direction.
2. The welcome promise and benefit statements are the baseline copy; final visual treatment may be refined without changing their meaning.
3. What's New is separate from onboarding, appears once for an upgraded release with bundled notes, and is suppressed on fresh installation.
4. Existing installs must not be mistaken for fresh installs when the onboarding feature is first introduced. The implementation must demonstrate how it distinguishes an actual first install from an upgrade.
5. Each release owner is responsible for supplying accurate, concise release highlights and a matching version entry before shipping.
6. The approved implementation dependency exception, if retained, must remain pinned and documented in the repository's third-party notices. It must not become permission to add unrelated dependencies.

## 12. Delivery tracking

PRD-026 is delivered through one parent issue and four sequenced implementation issues. The parent issue owns feature-level completion; child issues own focused stages and their corresponding stacked PRs.

### Parent initiative

- **[Issue #89 — PRD-026 parent: First-Run Onboarding and What's New](https://github.com/melusi-k/Feed-Good/issues/89):** single source of truth for the complete feature, its dependency graph, delivery sequence and definition of done.

### Implementation work breakdown

| Order | Issue | Stage | Dependency |
|---|---|---|---|
| 1 | [#94](https://github.com/melusi-k/Feed-Good/issues/94) | Launch eligibility and orchestration foundation | None |
| 2 | [#95](https://github.com/melusi-k/Feed-Good/issues/95) | Three-page first-run onboarding | #94 |
| 3 | [#96](https://github.com/melusi-k/Feed-Good/issues/96) | Bundled What's New release experience | #94 |
| 4 | [#97](https://github.com/melusi-k/Feed-Good/issues/97) | Launch integration and full acceptance verification | #95 and #96 |

PRs must link exactly to their child issue, remain focused, include tests and target the preceding stack branch. Stages 2 and 3 may branch from the completed foundation; final integration must reconcile their shared root launch presentation. No child PR may bypass its declared dependency.

### Superseded implementation history

- **[PR #90](https://github.com/melusi-k/Feed-Good/pull/90):** originating standalone What's New implementation and review history. It is superseded as an active delivery path; its model, tests and review discussion remain reference material.
- **[PR #92](https://github.com/melusi-k/Feed-Good/pull/92):** combined onboarding + What's New prototype. It is superseded as an active delivery path; its onboarding UI, launch-flow work, tests and dependency decision must be assessed and selectively reused or replaced against issues #94–#97.
- **[PR #93](https://github.com/melusi-k/Feed-Good/pull/93):** documentation PR adding PRD-026, registering it and including it in the roadmap. It remains separate from implementation.

PR #90 and #92 overlap in root presentation and What's New files. They must not be merged independently. Their branches are historical inputs only; new implementation work proceeds through the staged issue/PR sequence.

### Implementation review gates

- Prove existing-install upgrade detection. Missing onboarding state alone must not cause an existing user to see first-run onboarding.
- Keep onboarding completion and What's New acknowledgement independent.
- Confirm the exact package identity, licence, transitive dependencies and repository policy before retaining OnboardingKit. Native SwiftUI remains acceptable; no dependency is assumed necessary.
- Verify fresh install, upgrade to the onboarding-introduction release, onboarding pending, What's New pending, both pending, no matching notes and returning-user launch.
- Verify skip on every onboarding page, both final choices, existing Add Plant handoff, dismissal persistence, offline operation, accessibility and regression safety.
- Do not alter existing plant, care or journal records.

**Implementation status:** the parent issue and four child issues are established. The former implementation PRs #90 and #92 are closed unmerged as superseded active paths. The draft implementation stack is [PR #98](https://github.com/melusi-k/Feed-Good/pull/98) / issue #94 (launch eligibility foundation) → [PR #99](https://github.com/melusi-k/Feed-Good/pull/99) / issue #95 (native onboarding presentation) → [PR #100](https://github.com/melusi-k/Feed-Good/pull/100) / issue #96 (bundled What's New experience) → [PR #102](https://github.com/melusi-k/Feed-Good/pull/102) / issue #97 (launch integration and UI acceptance). All four PRs are draft and mergeable in GitHub's branch comparison; CI is still running or queued. PR #93 remains the documentation delivery.

**Closure rule:** the parent issue and PRD-026 implementation status remain open until stage 4 is merged and every acceptance criterion has recorded evidence. A documentation-only PR does not certify implementation completion.

### Related product requirements

[PRD-001 — My Plants](PRD-001-my-plants.md) owns plant creation and profiles; [PRD-003 — Care Reminders](PRD-003-care-reminders.md) owns opt-in reminders; [PRD-004 — Plant Journal](PRD-004-plant-journal.md), [PRD-005 — Today](PRD-005-today.md) and [PRD-006 — Feed Good Moments](PRD-006-feed-good-moments.md) own the destinations described in onboarding; [PRD-007 — Garden Setup & Growing Context](PRD-007-garden-setup.md) owns optional plant-level context and explicitly excludes a separate first-run setup flow.
