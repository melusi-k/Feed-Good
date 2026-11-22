# iOS platform and App Store readiness

This parent change coordinates the Feed Good iOS platform-readiness work as one review and one merge into `main`.

## Merge strategy

- This branch is the integration parent and the only branch in this stack that targets `main`.
- Feature branches for the work below must be based on this branch and their pull requests must target this branch.
- Merge child changes into this branch only after their focused review and validation.
- Do not merge any child PR directly into `main`.
- Before merging this parent PR, run the complete required CI workflow against the final parent head and review the aggregate diff.
- The owner must explicitly approve the exact parent PR head before the single merge into `main`.

## Work packages

1. **Notification response routing** — handle notification taps, including cold launch, and route to the relevant plant/care context.
2. **Notification lifecycle and tests** — verify permission states, scheduling, cancellation/rescheduling, capacity handling, and response routing.
3. **App Intents** — add only useful, implemented app actions; link AppIntents and verify Xcode metadata extraction in CI. App Intents are not required for local notification delivery.
4. **App Store and iOS readiness** — document listing category and metadata, privacy disclosures, age-rating inputs, accessibility/system integration, and any genuinely required capabilities.

## Existing implementation and boundaries

- Local care reminders already use `UserNotifications` and `UNUserNotificationCenter`.
- Permission remains optional; core plant care must continue to work when permission is denied.
- Do not add background modes, notification usage-description keys, entitlements, or unrelated capabilities without a demonstrated requirement.
- App Store category is configured in App Store Connect, not through an arbitrary Info.plist key in `project.yml`.
- Keep XcodeGen as the source of truth; do not edit the generated Xcode project directly.
- Preserve the iOS 18.0 deployment target unless a separately justified product decision changes it.

## Acceptance criteria

- Notification taps reliably open the correct plant/care destination from foreground, background, and terminated states.
- Notification behaviour is covered by deterministic tests, including denied and not-yet-determined permission.
- Any introduced App Intents are discoverable and their metadata extraction is verified in CI.
- App Store configuration guidance is accurate and distinguishes App Store Connect settings from build-time app configuration.
- The full required `build-and-test` check passes on the final parent PR head.
- Only this parent PR is merged into `main`.
