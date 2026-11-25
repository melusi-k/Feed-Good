# PRD-027 — User Lifecycle & Meaningful Engagement

**Status:** Product proposal; implementation not authorised until section 11 gates are closed  
**Priority:** P1 — foundational product strategy  
**Release:** Post-onboarding foundation; incremental delivery  
**Primary surfaces:** Launch, Today, My Plants, Plant Profile, Care Routine, Plant Story, Journal, Care Guide, local reminders and Settings

## 1. One-line goal

Help people move from discovering Feed Good to establishing a useful, sustainable relationship with their plants by making the first meaningful action clear, everyday care dependable, and long-term progress understandable—without manufacturing app engagement or compromising the local-first privacy promise.

## 2. Users and use cases

- **New gardener:** understand the app, add a first plant without friction and know what to do next.
- **Returning gardener:** see a calm, relevant view of what actually needs attention today.
- **Growing collection owner:** move between plants, care, observations and learning without duplicated information.
- **Intermittent user:** return after time away to a neutral, useful experience without guilt, synthetic backlog or streak-loss messages.
- **Privacy-conscious user:** use the app without an account, network connection, remote activity tracking or notification permission.

## 3. Capability targets

These are acceptance thresholds, not claims about current performance. Cross-user conversion/retention targets are not measurable under the current local-only architecture and must not be fabricated.

| Capability | Acceptance evidence | Ship threshold |
| --- | --- | --- |
| First-run comprehension | Copy review and onboarding UI tests | User can understand the app's promise and skip or proceed without forced setup |
| First-plant activation | Unit/UI journey tests | Existing Add Plant flow is reachable from onboarding; Explore first remains available |
| First-care activation | End-to-end tests | User can optionally establish plant-specific care and record care without notification permission |
| Everyday usefulness | Today projection tests and UI review | Today reflects actual records and useful empty, due, upcoming and overdue states |
| Relationship depth | Plant Story, Journal and Growth Review tests | Care and observation history remain attached to the correct plant and source |
| Return after absence | Deterministic date/state tests and copy review | Return experience is accurate and neutral; no invented missed actions or failure language |
| Privacy and resilience | Offline, persistence and permission-denied tests | Core lifecycle works without account, network, remote analytics or notification permission |
| Accessibility | UI/accessibility review | Supported Dynamic Type, VoiceOver, light/dark appearance, contrast and touch targets pass |

Do not add a remote event pipeline to collect baselines. Any future measurement requires a separately approved privacy proposal.

## 4. Behavior changes

### 4.1 Lifecycle model

This lifecycle describes user outcomes; it is not a new persisted user/account state machine.

1. **Discover and understand:** understand the product promise and decide whether to continue.
2. **Start:** explore immediately or add a first plant through the existing flow.
3. **Establish care:** optionally create plant-specific care tasks and understand Today/reminders.
4. **Experience value:** complete care, record observations, learn from the Guide or revisit a plant's story.
5. **Build confidence and return:** see relevant current information and grounded history whenever returning.
6. **Deepen the relationship:** use plant history, journal, growth review and other existing capabilities as the garden grows.

Do not persist a separate user lifecycle stage, activation flag, engagement score or user profile. Derive any in-app guidance from current authoritative records and existing launch preferences.

### 4.2 First-run and onboarding

- PRD-026 is the sole authority for launch eligibility, the three-page onboarding and What's New sequencing.
- Preserve its approved pages/actions: Welcome; How it works; Get started; Skip; Add your first plant; Explore first.
- Onboarding remains skippable. No account, questionnaire, location request, network requirement, plant requirement or notification prompt.
- Do not duplicate onboarding state, launch orchestration, Add Plant logic or What's New state.
- Fresh install and existing-install upgrade continue to follow PRD-026's separate eligibility contract.
- No new onboarding page or activation gate is authorised here.

### 4.3 First meaningful use

- **First plant saved:** first-plant milestone, not proof of full activation.
- **First care routine saved:** optional care-setup milestone; plants without routines remain valid.
- **First care event recorded:** first completed-care milestone.
- These definitions are for design and test scenarios only. Do not add persisted milestone flags or remote event tracking.
- Reuse existing plant, care task, care event and journal records. No parallel activity ledger or duplicate domain model.
- Users can explore with zero plants and use plant profiles/journal without enabling reminders.

### 4.4 Everyday value and return experience

- Today remains the primary daily orientation surface and derives due, upcoming, overdue and recent activity from current records.
- Empty states explain a useful next action without implying failure to set up the app.
- Returning after absence shows current truth: current tasks/dates, plants and genuine recent records. Never create a synthetic backlog, infer missed care or use guilt-based copy.
- A completed care event is meaningful activity, not proof of plant health.
- Journal entries, milestones and Growth Review remain user-authored/record-derived ways to notice change. Preserve source navigation and plant identity.
- Care Guide learning remains optional and available offline.

### 4.5 Contextual communication

- Local reminders remain optional, user-controlled and owned by PRD-003. Ask permission only in the existing contextual enable-reminders flow.
- No remote push, email, marketing campaigns, scheduled engagement nudges or notification calendar.
- Each reminder corresponds to an enabled care task and current approved schedule. Reconcile after task edits, quiet periods, archive/restore and permission changes under owning PRDs.
- Action acknowledgements must be useful, concise and grounded in the action; no celebratory gamification.
- Never notify merely because the user has not opened the app.

### 4.6 Progress, reflection and habit language

- No streaks, scores, completion percentages, badges, leaderboards, rankings or social comparisons as retention mechanics.
- **Approved PRD-024 exception:** private, descriptive streak histories may be shown to the user for each individual stable care-task identity. They are visible only within that user's own app, including clearly labelled per-task summaries in the Garden Profile and the relevant care-task context. They are not engagement/retention mechanics, and must not introduce reminders, streak-loss messaging, rewards, targets, badges, competition, social comparison or pressure to perform care early/more often. Derive them on-device from approved care/task records; do not add account-level streak state, remote tracking or a second activity ledger.
- PRD-013 Weekly Garden Reflection explicitly excludes streaks and scores; the PRD-024 per-task histories must not be included in that reflection.
- Care analytics must distinguish recorded care behavior from observed plant condition and health outcomes. Activity counts/consistency must never be labelled a health score.
- Reuse existing CareEvent, JournalEntry, Plant, PlantStory and other authoritative records. No second activity/history store.
- Insights identify their source and avoid unsupported causal claims.
- Quiet periods, disabled tasks, archived plants and naturally infrequent schedules are not user inactivity or failure.

## 5. Out of scope

- Accounts, authentication, cloud sync, remote profiles or multiple gardens.
- Remote analytics, advertising identifiers, attribution SDKs, cross-app tracking, telemetry uploads or server-side cohorts.
- Growth campaigns, referrals, paid acquisition, subscriptions or monetisation changes.
- Gamification, scores, rankings, pressure-based retention, and streaks used as engagement or retention mechanics. The narrow private, per-task descriptive-history exception approved under PRD-024 is not a retention mechanic and remains subject to PRD-022 lifecycle and data-integrity gates.
- Remote push, email, SMS or scheduled marketing messages.
- AI diagnosis, computer vision, inferred plant health, weather/location inference or automatic care recommendations.
- Replacing Today, My Plants, Care Routine, Journal, Plant Story, Feed Good Moments, Care Guide, Growth Review, Weekly Garden Reflection or reminders.
- Persisted activation/engagement state or duplicate activity ledger.
- Redesigning PRD-026.

## 6. Surfaces and interaction requirements

| Surface | Lifecycle responsibility | Required behavior |
| --- | --- | --- |
| Launch / onboarding | Explain and start | PRD-026 behavior only; no duplicate launch state |
| Add Plant | First plant milestone | Existing save, validation, cancellation and error behavior |
| Plant Profile | Understand a plant | Existing identity, context, care and story entry points remain coherent |
| Care Routine | Establish care | Plant-specific, user-controlled schedules; no universal frequency assumptions |
| Today | Everyday orientation | Accurate due/upcoming/overdue and recent-record projections; useful empty state |
| Local reminders | Optional return support | Existing opt-in, local-only, task-derived contract |
| Journal / Plant Story | Notice and remember | User-authored observations and care history remain connected and source-linked |
| Care Guide | Learn | Curated, qualified, source-backed and offline |
| Growth Review / Reflection | Recognise change | Real source records; no diagnosis, score or invented progress |
| Settings | Trust and control | Local-first privacy explanation, notification state and data portability |

No new top-level tab is authorised.

## 7. Pricing and access

Included in the existing product. No account, subscription, network service or paid tier is required.

## 8. Safety, privacy and data integrity

- Local-first is invariant: core plant, care, journal, guide and lifecycle journeys work offline.
- No account, cloud sync, remote activity collection or precise location collection.
- Do not transmit plant names/species/notes/photos, care history, journal content, notification interaction or usage events.
- Do not infer identity, household, location, gardening skill, motivation, inactivity or plant health.
- Notification permission is optional; denial never blocks activation, care recording, Today or Journal.
- Never convert absence into overdue tasks, missed-care history or a negative engagement signal.
- Preserve user-authored records and archive/export/restore contracts. No migration is expected unless separately approved.
- Derived summaries remain accurate after source edits/deletion, archive/restore, quiet periods and time-zone changes.
- Any future aggregate measurement needs separate PRD/change approval covering purpose, consent, minimisation, retention, deletion, security, offline behavior and exact privacy copy before implementation.
- Retain repository accessibility and appearance standards.

## 9. Launch and delivery plan

Deliver incrementally; do not implement the lifecycle as one large feature branch.

1. **Baseline/contract audit:** map current main implementation against PRD-026, PRD-001–010 and relevant later PRDs. Record actual gaps; do not reopen accepted decisions without evidence.
2. **Activation journey verification:** test fresh install, existing-install upgrade, onboarding skip, Explore first, Add Plant handoff, first plant save, optional care setup and first care completion. Reuse existing flows.
3. **Everyday usefulness audit:** verify Today, empty states, care task state, reminders and return-after-absence behavior across enabled/disabled tasks, quiet periods and archived plants.
4. **Relationship continuity audit:** verify plant identity and source navigation across CareEvent, JournalEntry, Plant Story, Growth Review, Care Guide and Weekly Garden Reflection.
5. **Communication audit:** verify reminders remain task-derived, optional and reconciled by owning contracts. No new channels/triggers.
6. **Close evidenced gaps only:** create focused implementation issues/PRs for verified gaps. Each PR targets one behavior, reuses domain logic and includes exact-head CI evidence.
7. **Release verification:** agreed unit/UI/regression suites, offline and permission-denied checks, accessibility/appearance review, simulator/device checks and data portability regression. Record automated/manual evidence separately.

## 10. Replaces

Establishes one product-level lifecycle and meaningful-engagement framework across existing capabilities. It does not replace or supersede feature PRDs. In a conflict, the owning feature PRD remains authoritative; update both through explicit change control if behavior must change.

## 11. Decisions, constraints and design gates

### Approved constraints

- PRD-026 owns onboarding and What's New.
- Existing feature PRDs own plant, care, reminders, Today, Journal, Guide, profile, archive/lifecycle, quiet periods, growth review and reflection behavior.
- No new analytics pipeline, persisted engagement state, account or activity ledger.
- No streaks or scores as engagement/retention mechanics. PRD-024's private, descriptive per-task streak history is the sole approved exception; retain PRD-013's exclusion of streaks from Weekly Garden Reflection.
- Care consistency is not plant health.
- Notifications remain local, optional and task-derived.

### Gates before implementation issues are authorised

1. Audit the current app and map each lifecycle stage to existing screens, models, coordinators and tests. Identify only verified gaps.
2. Confirm first-care definitions against current UX: a saved enabled care task is care setup; a recorded CareEvent is first completed care. Neither is required for a plant to be valid.
3. Decide whether additional in-app return guidance is needed after the audit. Default: no new UI if Today and existing plant/story surfaces already provide an adequate return path.
4. Review care analytics/streak/health-conclusion proposals against sections 4.6 and 8. PRD-024 is the approved narrow exception for private, descriptive streak histories scoped to one stable care-task identity. This does not authorise gamification, streak-based reminders, retention nudges, social comparison or combined plant/garden streaks. Implementation remains gated by PRD-022's scheduled-opportunity identity/lifecycle contract and PRD-024's own acceptance criteria.
5. If business growth measurement is desired, create a separate privacy proposal. This PRD does not authorise telemetry, analytics SDKs, attribution or cross-user funnel measurement.

These gates prevent duplicated shipped functionality and silent changes to established contracts; they are not permission to expand scope.

## 12. Delivery tracking

- **PRD:** PRD-027 — User Lifecycle & Meaningful Engagement.
- **Parent issue:** [#114 — User Lifecycle & Meaningful Engagement](https://github.com/melusi-k/Feed-Good/issues/114).
- **Related authority:** PRD-026 onboarding/What's New; PRD-001 My Plants; PRD-002 Care Routine; PRD-003 Care Reminders; PRD-004 Plant Journal; PRD-005 Today; PRD-006 Feed Good Moments; PRD-008 Care Guide; PRD-009 Settings & Data Portability; PRD-010 Garden Profile; PRD-012 Growth Review; PRD-013 Weekly Garden Reflection; PRD-015 Plant Archive; PRD-016 Plant Lifecycle States; PRD-017 Care Routine Review; PRD-020 Seasonal and Quiet Periods; PRD-022 care-occurrence/scheduling contract.
- **Implementation status:** no implementation authorised until section 11 gates are recorded and focused delivery issues are created.
