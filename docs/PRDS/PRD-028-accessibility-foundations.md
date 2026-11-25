# PRD-028 — Accessibility Foundations

**Status:** Draft for product review; implementation not started  
**Stage:** Cross-cutting product quality and engineering foundation  
**Priority:** P1 — foundational quality and inclusion  
**Release:** Progressive adoption; no blanket conformance claim  
**Primary surfaces:** All user-facing iOS flows, repository documentation, pull-request review and CI

## 1. One-line goal

Make Feed Good usable and understandable by people with a broad range of abilities by establishing a transparent accessibility commitment and embedding practical accessibility requirements into product design, implementation, review, testing and release.

## 2. Users and use cases

- A person who uses VoiceOver can navigate the app, understand controls and complete core plant, care and journal tasks.
- A person who increases Dynamic Type can read and use the app without clipped, overlapping or inaccessible content.
- A person with low vision or colour-vision differences can distinguish information without relying on colour alone.
- A person with motor or dexterity limitations can reliably activate controls using appropriately sized targets and standard system interactions.
- A person who benefits from reduced motion or less visual complexity can use the app without avoidable motion or disruptive transitions.
- A contributor can understand Feed Good's accessibility commitments, identify relevant review expectations and report an accessibility barrier.
- The product owner can distinguish documented intent, automated test coverage, manual verification and independently assessed conformance.

## 3. Capability targets

| Capability | Eval / acceptance check | Baseline | Ship threshold | Owner / date |
| --- | --- | --- | --- | --- |
| Public accessibility information | Repository statement is discoverable and explains support, known limitations and feedback route | Not established | Statement reviewed and published; contact route verified | [owner] / [date] |
| Core journey accessibility | VoiceOver and Dynamic Type walkthroughs cover agreed critical journeys | Audit required | No unresolved release-blocking barriers in agreed journeys | [owner] / [date] |
| Accessible interaction | Controls expose meaningful labels, traits, values and adequate hit areas | Audit required | Applicable engineering gates pass | [owner] / [date] |
| Regression prevention | Automated checks cover stable, high-value accessibility invariants | Audit required | Checks run in the existing required CI workflow without weakening build/test gates | [owner] / [date] |
| Barrier handling | Reports can be triaged, prioritised and tracked to verification | Not established | Dedicated issue label and documented response workflow available | [owner] / [date] |
| Claim accuracy | Public claims match available evidence | Not established | No unsupported WCAG or platform-conformance claim | [owner] / [date] |

Numeric targets must be agreed after the baseline audit. A passing automated audit is not, by itself, proof of accessibility or WCAG conformance.

## 4. Behavior changes

- Publish a root-level `ACCESSIBILITY.md` repository statement. It must explain the project's accessibility intent, supported platform context, known limitations, how to report a barrier and how reports will be handled.
- Establish an `accessibility` GitHub issue label and a consistent triage path for user-reported and internally discovered barriers.
- Make accessibility impact an explicit consideration in product requirements and acceptance criteria whenever a change introduces or modifies user-facing UI, content, navigation, notifications or interaction.
- Add accessibility expectations to the pull-request template or equivalent review guidance. Reviewers should consider labels, traits, values, reading order, Dynamic Type, contrast, touch target size, keyboard/alternate input where applicable, motion and error communication.
- Maintain an iOS accessibility testing guide covering VoiceOver, Dynamic Type, colour/contrast, Reduce Motion, control sizing, focus/reading order, empty/error states and relevant device settings.
- Audit the app's critical journeys and establish a baseline. At minimum include first launch/onboarding, add/view a plant, view and complete a care task, create/read a journal entry, and settings/data portability flows.
- Add automated accessibility checks where they are reliable and maintainable. Evaluate XCTest/XCUITest accessibility audits and targeted assertions against the current Xcode and simulator environment before selecting the implementation.
- Keep automated checks deterministic and scoped. Do not add fragile snapshot-only checks, broad suppressions or CI fallbacks that conceal failures.
- Record manual simulator and physical-device verification separately from automated CI results.
- Track known barriers with severity, affected journey, assistive-technology context, workaround (if any), owner and remediation status.
- Review the statement and known limitations when meaningful accessibility behavior changes; do not allow the document to imply that every screen has been audited when it has not.

## 5. Out of scope

- Claiming or certifying WCAG 2.2 AA, Section 508 or any other standard without a defined assessment and sufficient evidence.
- A third-party accessibility overlay, SDK or dependency.
- A wholesale visual redesign or replacement of native SwiftUI controls.
- Guaranteeing support for every assistive technology, device configuration or platform version without verification.
- Treating automated accessibility audits as a substitute for human testing with assistive technologies.
- Introducing remote analytics, user tracking, accounts or collection of sensitive accessibility/health information.
- Blocking all feature work until every legacy screen is fully remediated; barriers must instead be prioritised and addressed through an explicit risk-based plan.

## 6. Surfaces

- Repository root: `ACCESSIBILITY.md`.
- `AGENTS.md`: engineering accessibility review gates and contributor expectations.
- `.github/PULL_REQUEST_TEMPLATE.md`: explicit accessibility impact and verification prompts.
- `docs/ACCESSIBILITY_TESTING.md`: iOS testing procedures, critical journeys and evidence expectations.
- GitHub issues: `accessibility` label, barrier reporting and remediation tracking.
- iOS app: SwiftUI controls, VoiceOver semantics, Dynamic Type layouts, contrast, motion and interaction affordances.
- Existing CI: targeted automated checks integrated into the established required `build-and-test` workflow only where the current toolchain supports them reliably.

## 7. Pricing

Included in the core product at no additional cost. Accessibility must not be gated behind a subscription, account, network connection or notification permission.

## 8. Safety and quality bar

- Never rely on colour, shape, position, sound or animation alone to communicate essential information.
- Interactive controls must have meaningful accessible names and appropriate traits/values; decorative imagery must not create redundant VoiceOver output.
- Preserve system text sizing and Dynamic Type. Avoid fixed text sizes and layouts that truncate essential content at larger accessibility text sizes.
- Follow the repository's existing minimum 44x44-point interactive target guidance unless a documented platform-specific exception is justified.
- Ensure focus and reading order follow the user's task, and that sheets, alerts, validation errors and dynamic updates are understandable to assistive technology.
- Respect Reduce Motion and avoid conveying essential state only through animation.
- Check contrast for text, meaningful icons and control boundaries in light and dark appearance. Do not infer contrast compliance from colour tokens alone.
- Prefer native SwiftUI controls and semantics; custom controls require explicit accessibility behavior and focused tests.
- Automated audits must be reviewed for false positives and false negatives. Any suppression must be narrow, justified and documented.
- Accessibility barriers that prevent a core journey require explicit severity and release-risk review; they must not be silently waived.
- Do not publish a compliance badge or conformance statement based solely on the presence of `ACCESSIBILITY.md`, a passing build or automated audit output.
- Preserve privacy: accessibility testing must use synthetic/test data and must not expose private journal content in logs or notifications.

## 9. Launch plan

1. Audit current app architecture, supported iOS version, CI workflow and existing accessibility rules in `AGENTS.md`.
2. Establish a baseline across agreed critical journeys using VoiceOver, Dynamic Type, light/dark appearance and Reduce Motion.
3. Agree severity definitions and the minimum set of release-blocking accessibility barriers.
4. Draft and review `ACCESSIBILITY.md`, including a working barrier-reporting route and honest statement of current verification coverage.
5. Add the `accessibility` GitHub label and update contributor/PR review guidance.
6. Create `docs/ACCESSIBILITY_TESTING.md` with reproducible simulator and device procedures.
7. Evaluate the current Xcode toolchain's accessibility audit support; add focused, deterministic automated checks to the existing CI workflow only after validating local behavior and runtime availability.
8. Remediate high-severity barriers in critical journeys through focused PRs, with regression coverage.
9. Record manual verification evidence separately and update the statement when coverage or known limitations change.
10. Reassess the baseline after implementation and decide whether a formal external conformance assessment is warranted.

## 10. Replaces

Replaces informal, scattered accessibility expectations with a documented and reviewable product/engineering practice. It strengthens the existing accessibility review gates in `AGENTS.md`; it does not replace Apple's Human Interface Guidelines, platform accessibility APIs or qualified accessibility evaluation.

## 11. Decisions and open questions

1. Which critical journeys should be classified as release-blocking for the first accessibility baseline?
2. What severity levels and response expectations should apply to accessibility issues?
3. Which contact or repository issue route should be presented in the public statement for external barrier reports?
4. Which Xcode version and simulator runtime are available in the required CI workflow, and do they support stable accessibility audit APIs?
5. Which barriers are currently present in core journeys, and which can be fixed independently without changing feature contracts?
6. Should Feed Good commission an independent accessibility review after the initial remediation cycle? No conformance claim should precede that decision and evidence.
7. How should manual testing with assistive technology be incorporated into release sign-off when physical-device access is limited?

## 12. Delivery tracking

- **Parent issue:** [#131 — PRD-028 Accessibility Foundations](https://github.com/melusi-k/Feed-Good/issues/131); use this existing issue to coordinate the foundation work.
- **Documentation delivery:** Root `ACCESSIBILITY.md`, `docs/ACCESSIBILITY_TESTING.md`, PRD register and contributor guidance.
- **Engineering delivery:** Targeted app audit, prioritized remediations and stable automated checks where supported.
- **Prerequisites:** Existing accessibility review gates in `AGENTS.md`; current CI contract requiring `build-and-test` on the exact PR head.
- **Related product areas:** PRD-001 My Plants; PRD-003 Care Reminders; PRD-004 Plant Journal; PRD-005 Today; PRD-009 Settings & Data Portability; PRD-026 First-Run Onboarding and What's New; PRD-027 User Lifecycle & Meaningful Engagement.
- **Implementation status:** Not started. This document records product intent and delivery requirements only.
- **Closure rule:** Do not close the parent issue until the accessibility statement, contributor guidance, barrier triage workflow, baseline report and agreed automation/remediation deliverables are complete and verified. Any deferred work must be explicitly recorded with severity and rationale.
