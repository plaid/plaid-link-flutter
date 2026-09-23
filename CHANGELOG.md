## 1.1.0

Updates both native SDKs. No Dart API changes; upgrading requires no code changes.

### iOS

Ships [LinkKit 7.2.0](https://github.com/plaid/plaid-link-ios/releases/tag/7.2.0):

- Added automatic session handoff for Embedded Link.
- Deliver the Embedded Link start-failure `onExit` callback on the main thread.
- Limited WebView inspection to Sandbox. Production Link sessions can no longer be attached to with Safari Web Inspector.
- Security updates.

### Android

Ships [Plaid Link Android SDK 6.2.2](https://github.com/plaid/plaid-link-android/releases/tag/v6.2.2), which also picks up
[6.2.1](https://github.com/plaid/plaid-link-android/releases/tag/v6.2.1) since 1.0.0 shipped 6.2.0:

- Fixed a static-initialization crash in `LinkAccountVerificationStatus` and other public sealed classes when an activity is restored after the app's process was killed.
- `OnLoadCallback` now triggers for sessions whose WebView is not eager-started.
- Fixed a white screen when connecting a second OAuth institution in the same Link session. Returning from an OAuth redirect now resumes Link correctly for multiple institutions.
- Security improvements.

## 1.0.0

First stable release of the official Plaid Link Flutter SDK.

### iOS

Ships [LinkKit 7.1.0](https://github.com/plaid/plaid-link-ios/releases/tag/7.1.0):

- Fixed Link dismissing early during multi-item Link.
- Improved logging for Headless sessions.
- Return an error when a Headless token is reused.
- Improved the error message when a non-Link token is used to create a `PlaidLinkSession`.
- Fixed a FinanceKit crash.

### Android

Ships [Plaid Link Android SDK 6.2.0](https://github.com/plaid/plaid-link-android/releases/tag/v6.2.0):

- Fixed bugs affecting the `income_verification` product.
- Lowered the minimum supported Android version from API 26 (Android 8.0) to API 25 (Android 7.1).
- Narrowed the SDK's consumer ProGuard rules from `-keep` to `-keepnames`, allowing R8 to shrink and optimize SDK code while preserving readable stack traces.
- Removed the unused OkHttp `logging-interceptor` dependency.

## 1.0.0-beta.2

### Fixed

- Deliver the terminal `HANDOFF` event through `onEvent` after `onSuccess` for regular Link, Layer, and Headless sessions.
- Keep session listeners and native session state alive until `HANDOFF`, with a short fallback timeout when the event does not arrive.
- Prevent early or stale `HANDOFF` events from tearing down the active session or suppressing a pending success callback.

### Native SDKs

- iOS: LinkKit `7.0.5`.
- Android: Plaid Link SDK `6.1.0`.

## 1.0.0-beta.1

Initial public beta release of the official Plaid Link Flutter SDK.

### Added

- React Native-style session API for regular Link:
  - `createPlaidLinkSession`
  - `PlaidLinkSession.open`
- Plaid Layer support:
  - `createPlaidLayerSession`
  - `PlaidLayerSession.open`
  - `PlaidLayerSession.submit`
- Headless Link support:
  - `createPlaidHeadlessSession`
  - `PlaidHeadlessSession.start`
- Embedded Search support through `PlaidEmbeddedSearchView`.
- iOS FinanceKit sync support through `syncFinanceKit`.
- RN-compatible success, exit, event, error, institution, account, Layer submission, and FinanceKit model types.
- Example app covering regular Link, Layer, Headless, Embedded Search, and FinanceKit flows.
- Migration guide from the community `plaid_flutter` package.
- Developer documentation with setup notes, recipes, lifecycle behavior, error handling, and API reference.

### Native SDKs

- iOS: LinkKit `7.0.5`.
- Android: Plaid Link SDK `6.1.0`.

### Beta limitations

- This is a prerelease beta and should be validated in sandbox and test apps before production rollout.
- Mobile-only support; web and desktop are not supported.
- FinanceKit is iOS-only. Android returns an unsupported-platform error.
- FinanceKit live sync requires iOS 17.4 or later, Apple entitlement approval, and an eligible Item.
- Android Embedded Search supports one active embedded search view at a time.
- Native SDK/backend Flutter wrapper detection is tracked separately and should be confirmed before stable release.
