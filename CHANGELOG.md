## 1.3.0

Updates both native SDKs and adds a FinanceKit availability check.

**Behavior change:** a FinanceKit sync that finishes without Apple sharing any accounts now
throws `FinanceKitException` with `FinanceKitErrorType.noAccounts`, where it previously
completed successfully. Code that treats a resolved `syncFinanceKit` future as "accounts were
synced" needs to handle that error.

### Dart

- Added `financeKitStatus()`, which reports whether FinanceKit can be used on this device
  without prompting the user, so UI can be gated before calling `syncFinanceKit`. Android and
  iOS below 17.4 report `FinanceKitStatus.unavailable` rather than throwing.
- Added `FinanceKitErrorType` values for the failures LinkKit 7.4.0 distinguishes:
  `permissionNotRequested`, `dataUnavailable`, `noAccounts`, `syncFailed`, `channelClosed`, and
  `syncTimedOut`. These previously arrived as `unknown`.
- Added `FinanceKitException.syncErrorType` and `.syncErrorCode`, carrying the server-reported
  detail behind `FinanceKitErrorType.syncFailed`.
- Added `LinkViewName.institutionLoginInstructions` for the `INSTITUTION_LOGIN_INSTRUCTIONS`
  view that both platforms now report.

### iOS

Ships [LinkKit 7.4.0](https://github.com/plaid/plaid-link-ios/releases/tag/7.4.0), which also
picks up [7.3.0](https://github.com/plaid/plaid-link-ios/releases/tag/7.3.0) and
[7.3.1](https://github.com/plaid/plaid-link-ios/releases/tag/7.3.1). **This raises the build
requirement to Xcode 16.1 or later.**

- FinanceKit syncs the server ends with no shared accounts now fail with `noAccounts`, and other
  server-reported failures fail with `syncFailed`, carrying the error type, code, and message.
- A sync closed by the server, or one that goes an hour without completing, now fails with
  `channelClosed` or `syncTimedOut`. Previously the completion handler was never called.
- User-initiated syncs get an iOS background task once the permission prompt is answered, so they
  can run for about 30 seconds after the user leaves the app, and fail with `syncTimedOut` if iOS
  is about to suspend the app first.
- Devices, regions, and OS versions without Wallet data now report `dataUnavailable` instead of a
  permission error or crash, including iPad running an iPhone app in compatibility mode.
- A sync with `requestAuthorizationIfNeeded: false` on a device where the user was never asked now
  fails with `permissionNotRequested`.
- Leaving Apple's permission sheet without choosing no longer counts as a denial; Link asks again.
- Added the `INSTITUTION_LOGIN_INSTRUCTIONS` view name.

### Android

Ships [Plaid Link Android SDK 6.4.0](https://github.com/plaid/plaid-link-android/releases/tag/v6.4.0):

- Added the `SELECT_DENYLISTED_INSTITUTION`, `SELECT_FALLBACK_ROUTING_INSTITUTION`, and
  `SELECT_REMEMBER_ME_DUPLICATE_INSTITUTION` event names and the `INSTITUTION_LOGIN_INSTRUCTIONS`
  view name. Earlier versions delivered these as `UNKNOWN` with the raw name.
- Removed the AppCompat dependency, so Compose-only apps no longer need `androidx.appcompat`.
- Removed the unused `READ_BASIC_PHONE_STATE` permission from the SDK manifest.

## 1.2.1

Updates both native SDKs. No Dart API changes; upgrading requires no code changes.

Both releases fix defects on the return from a financial institution's OAuth login, so this is
worth picking up if you support OAuth institutions.

### iOS

Ships [LinkKit 7.2.3](https://github.com/plaid/plaid-link-ios/releases/tag/7.2.3):

- Fixed a crash (`EXC_BAD_ACCESS`) that could occur shortly after the app returned to the foreground while Link was open, such as after OAuth.
- Fixed the Layer background gradient covering only part of the screen when Link's view changes size after it loads, such as on iPhone Duo or after rotation.
- Security updates.

### Android

Ships [Plaid Link Android SDK 6.3.1](https://github.com/plaid/plaid-link-android/releases/tag/v6.3.1):

- Fixed a race condition that manifested as a blank white screen after returning from a financial institution's OAuth login.

## 1.2.0

Updates both native SDKs. No Dart API changes; upgrading requires no code changes.

### iOS

Ships [LinkKit 7.2.2](https://github.com/plaid/plaid-link-ios/releases/tag/7.2.2), which also picks up
[7.2.1](https://github.com/plaid/plaid-link-ios/releases/tag/7.2.1):

- Fixed Link opening at the width the window had when the session was created, when presented with a view controller or a custom presentation handler. Unfolding an iPhone Duo or resizing an iPad multitasking window before opening Link left it in a column at the old width.
- Fixed a crash affecting Layer customers.

### Android

Ships [Plaid Link Android SDK 6.3.0](https://github.com/plaid/plaid-link-android/releases/tag/v6.3.0):

- Added automatic session handoff for Embedded Link, matching the behavior iOS gained in LinkKit 7.2.0.
- Fixed password-manager autofill on the Link credentials screen when the password manager requires unlock or confirmation before filling.

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
