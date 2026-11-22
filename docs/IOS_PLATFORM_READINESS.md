# iOS platform and App Store readiness

This parent change coordinates the Feed Good iOS platform-readiness work as one review and one merge into `main`.

## Merge strategy

- This branch is the integration parent and the only branch in this stack that targets `main`.
- Feature branches for the work below are based on this branch and their pull requests target this branch.
- Child changes are integrated into this branch only after focused review and validation.
- No child PR merges directly into `main`.
- Run the complete required CI workflow against the final parent head and review the aggregate diff before merging this parent PR.
- The owner must explicitly approve the exact parent PR head before the single merge into `main`.

## Work packages and integration status

1. **Notification response routing — integrated from #52.** Scheduled care reminders carry task and plant UUIDs. The notification-center delegate handles taps and forwards the payload to a main-actor router. Today validates that the task still belongs to the referenced plant, selects Today, navigates to the plant detail, and consumes the pending route. Malformed payloads clear stale pending destinations.
2. **Notification lifecycle and tests — core coverage integrated.** Existing scheduler tests cover optional permission, denied/not-yet-determined states, rescheduling, cancellation, capacity, and concurrency. Routing tests cover payload round-tripping, malformed payloads, stale-route clearing, and route consumption. The OS-driven foreground/background/terminated-app notification lifecycle is wired through `UNUserNotificationCenterDelegate`, but is not yet exercised by a dedicated end-to-end UI test on a simulator/device; verify those three launch states during release QA.
3. **App Intents — integrated from #53.** A read-only App Shortcut opens the existing Today experience. CI explicitly verifies that Xcode emits a non-empty `Metadata.appintents/extract.actionsdata` file after building the app. App Intents remain separate from notification delivery.
4. **App Store and iOS readiness.** App Store category and listing metadata are configured in App Store Connect, not by adding speculative project build settings. Review the App Store Connect listing, privacy disclosures, age-rating inputs, accessibility, and capabilities before submission.

## Integrated child changes

- [#52 Notification response routing](https://github.com/melusi-k/Feed-Good/pull/52) — merged into this parent branch after its exact-head iOS build/unit tests, Thread Sanitizer, and review-rules checks passed.
- [#53 App Intents: open today's care](https://github.com/melusi-k/Feed-Good/pull/53) — merged into this parent branch after its exact-head iOS build/unit tests, App Intents metadata extraction, Thread Sanitizer, and review-rules checks passed.
- The seven legacy negated `#expect` assertions were rewritten without changing their tested conditions or relaxing the review-rule baseline.

## Existing implementation and boundaries

- Local care reminders use `UserNotifications` and `UNUserNotificationCenter`.
- Permission remains optional; core plant care continues to work when permission is denied.
- Do not add background modes, notification usage-description keys, entitlements, or unrelated capabilities without a demonstrated requirement.
- App Store category is configured in App Store Connect, not through an arbitrary Info.plist key in `project.yml`.
- Keep XcodeGen as the source of truth; do not edit the generated Xcode project directly.
- Preserve the iOS 18.0 deployment target unless a separately justified product decision changes it.

## Acceptance criteria

- Notification taps route to the correct plant when the app receives a valid task/plant payload; stale or mismatched references are not opened.
- Deterministic tests cover notification payload validation and routing, plus reminder permission, scheduling, cancellation/rescheduling, capacity, and concurrency.
- Release QA explicitly verifies notification taps from foreground, background, and terminated states; automated OS lifecycle UI coverage remains a follow-up.
- The App Shortcut is discoverable and its metadata extraction is verified in CI.
- App Store configuration guidance distinguishes App Store Connect settings from build-time app configuration.
- The full required checks pass on the final parent PR head.
- Only this parent PR is merged into `main`.
