# Plaid Link Flutter

Official Flutter plugin for Plaid Link.

## Installation

Add the package:

```yaml
dependencies:
  plaid_link_flutter: ^0.0.1
```

Then import it:

```dart
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
```

If you are migrating from the community `plaid_flutter` package, start with the
[migration guide](doc/migration-guide.md).

## Quick Start

This implementation supports the React Native SDK's session-shaped Link API:

```dart
final session = await createPlaidLinkSession(
  LinkTokenConfiguration(
    token: linkToken,
    onSuccess: (success) {
      print(success.publicToken);
    },
    onExit: (exit) {
      print(exit.error?.errorMessage);
    },
    onEvent: (event) {
      print(event.eventName);
    },
  ),
);

await session.open();
```

Layer, Headless, Embedded Search, and FinanceKit use the same public names:

```dart
final layerSession = await createPlaidLayerSession(
  LayerTokenConfiguration(
    token: layerToken,
    onSuccess: (_) {},
  ),
);

await layerSession.open();
await layerSession.submit(const SubmissionData(phoneNumber: '+15551234567'));

final headlessSession = await createPlaidHeadlessSession(
  LinkTokenConfiguration(
    token: linkToken,
    onSuccess: (_) {},
    onExit: (_) {},
    onEvent: (_) {},
  ),
);

await headlessSession.start();

await syncFinanceKit(FinanceKitConfiguration(token: linkToken));
```

## Native SDKs

- iOS: LinkKit `7.0.1`, vendored at `ios/Frameworks/LinkKit.xcframework`
- Android: `com.plaid.link:sdk-core:6.0.0`

The vendored iOS framework intentionally contains only iOS device and simulator slices. The Mac Catalyst slice is not included.

## Requirements

- Flutter `3.29.3+`
- Dart `3.7+`
- iOS `15.0+`
- Android `minSdk 26+`

## Setup Notes

Create link tokens on your server using Plaid's `/link/token/create` endpoint,
then pass the link token into the Flutter app. Client-side public key
configuration is not supported.

For OAuth flows, configure your redirect URI in the Plaid Dashboard and your
native app platform settings. The Flutter API does not expose a separate
`resumeAfterTermination` method.

Identity Verification flows may require camera usage strings and permissions in
the host app.

## Example App

The example app mirrors the React Native example visually and includes screens
for regular Link, Layer, Headless, Embedded Search, and FinanceKit:

```sh
cd example
flutter run
```

Paste a `link_token`, create a session, then open or start the selected flow.
The app displays success, exit, and event callback results.

## Behavior Notes

- The SDK supports one active non-embedded session callback set at a time. Creating a Link, Layer, or Headless session replaces callbacks from the previous non-embedded session.
- Success and exit callbacks are terminal and clean up listeners. Event callbacks are non-terminal.
- Embedded Search is mobile-only. Android currently supports one active embedded search view at a time because the native result callback does not expose a per-view result identifier.

## Current Scope

Implemented:

- `createPlaidLinkSession`
- `PlaidLinkSession.open([bool fullScreen = false])`
- `createPlaidLayerSession`
- `PlaidLayerSession.open()`
- `PlaidLayerSession.submit(SubmissionData data)`
- `createPlaidHeadlessSession`
- `PlaidHeadlessSession.start()`
- `syncFinanceKit`
- `PlaidEmbeddedSearchView`
- `PlaidLink.sdkVersion`
- Success, exit, and event payload parsing
- iOS and Android native regular Link, Layer, Headless, and Embedded Search
- iOS native FinanceKit sync; Android returns a FinanceKit unsupported error
