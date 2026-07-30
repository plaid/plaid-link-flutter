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
