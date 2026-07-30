# Migration Guide: `plaid_flutter` to `plaid_link_flutter`

This guide helps you migrate from the community `plaid_flutter` package to the
official Plaid Link Flutter SDK.

The largest change is the move from a global handler API to explicit session
objects. Instead of calling `PlaidLink.create(...)` and then `PlaidLink.open()`,
you create a session for the Plaid flow you want to run, retain that session in
your widget state, and call the method on that session.

## Quick Links

- [What changed](#what-changed)
- [Package and platform requirements](#package-and-platform-requirements)
- [Standard Link](#standard-link)
- [Callbacks and events](#callbacks-and-events)
- [Layer](#layer)
- [Headless Link](#headless-link)
- [Embedded Search](#embedded-search)
- [FinanceKit](#financekit)
- [OAuth and redirect handling](#oauth-and-redirect-handling)
- [Migration checklist](#migration-checklist)

## What Changed

| Area | `plaid_flutter` | `plaid_link_flutter` |
| --- | --- | --- |
| Package import | `package:plaid_flutter/plaid_flutter.dart` | `package:plaid_link_flutter/plaid_link_flutter.dart` |
| Native SDKs | iOS 6.x, Android 5.x | iOS LinkKit 7.0.5, Android Link SDK 6.1.0 |
| Primary API | Global `PlaidLink.create()` and `PlaidLink.open()` | `createPlaidLinkSession()` returns `PlaidLinkSession` |
| Callback model | Global streams: `PlaidLink.onSuccess`, `PlaidLink.onExit`, `PlaidLink.onEvent`, `PlaidLink.onLoad` | Per-session callbacks passed in the configuration |
| Link readiness | Wait for create completion or `onLoad` stream | Use `LinkTokenConfiguration.onLoad` |
| Layer | `PlaidLink.submit(...)` on the global Link object | `PlaidLayerSession.submit(...)` |
| Headless | Global create/open pattern | `createPlaidHeadlessSession(...)` and `PlaidHeadlessSession.start()` |
| Embedded | `PlaidEmbeddedView` | `PlaidEmbeddedSearchView` |
| FinanceKit | Not available | `syncFinanceKit(...)` on iOS |
| Web | Supported by the community package | Not supported in this SDK |

The official SDK intentionally mirrors the React Native session-shaped API and
the native LinkKit 7 direction. Each Plaid flow has its own session type, which
makes token-to-flow compatibility clearer and avoids routing all callbacks
through process-wide streams.

## Package And Platform Requirements

Replace the dependency:

```yaml
dependencies:
  plaid_link_flutter: ^1.0.0-beta.2
```

Then update imports:

```dart
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
```

Requirements:

- Flutter `3.29.3+`
- Dart `3.7+`
- iOS `15.0+`
- Android `minSdk 26+`

## Standard Link

### Before

The community package creates a global handler and opens it through static
methods. Callbacks are usually wired through global streams.

```dart
final successSubscription = PlaidLink.onSuccess.listen((success) {
  print(success.publicToken);
});

final exitSubscription = PlaidLink.onExit.listen((exit) {
  print(exit.error?.errorMessage);
});

final eventSubscription = PlaidLink.onEvent.listen((event) {
  print(event.name);
});

await PlaidLink.create(
  configuration: LinkTokenConfiguration(token: linkToken),
);

await PlaidLink.open();
```

### After

Create a `PlaidLinkSession`, keep it alive for as long as you need to open Link,
and pass callbacks directly to the configuration.

```dart
PlaidLinkSession? _linkSession;
bool _linkReady = false;

Future<void> createSession(String linkToken) async {
  _linkSession = await createPlaidLinkSession(
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
      onLoad: () {
        setState(() => _linkReady = true);
      },
    ),
  );
}

Future<void> openLink() async {
  await _linkSession?.open();
}
```

Use `open(true)` if you want to request fullscreen presentation:

```dart
await _linkSession?.open(true);
```

## Callbacks And Events

The old package exposes global streams:

```dart
PlaidLink.onSuccess.listen(...);
PlaidLink.onExit.listen(...);
PlaidLink.onEvent.listen(...);
PlaidLink.onLoad.listen(...);
```

The official SDK routes callbacks through the session configuration:

```dart
LinkTokenConfiguration(
  token: linkToken,
  onSuccess: handleSuccess,
  onExit: handleExit,
  onEvent: handleEvent,
  onLoad: handleLoad,
);
```

Callback names and model fields are RN-style. The most common rename is:

```dart
// Old
event.name

// New
event.eventName
```

Success and exit are terminal callbacks. After either fires, the SDK cleans up
the active non-embedded session listeners. Event callbacks are non-terminal.

The SDK supports one active non-embedded callback set at a time. Creating a new
Link, Layer, or Headless session replaces the previous non-embedded callbacks.

## Layer

Layer now has its own configuration and session type. Use a Layer-compatible
link token; a regular Link token is not interchangeable.

```dart
PlaidLayerSession? _layerSession;

Future<void> createLayerSession(String layerToken) async {
  _layerSession = await createPlaidLayerSession(
    LayerTokenConfiguration(
      token: layerToken,
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
}

Future<void> submitLayerData() async {
  await _layerSession?.submit(
    const SubmissionData(
      phoneNumber: '+15551234567',
      dateOfBirth: '1990-01-31',
      params: <String, String>{'flow': 'signup'},
    ),
  );
}

Future<void> openLayer() async {
  await _layerSession?.open();
}
```

## Headless Link

Headless uses `LinkTokenConfiguration`, but it creates a
`PlaidHeadlessSession`. Start the flow with `start()` instead of opening a Link
view.

```dart
PlaidHeadlessSession? _headlessSession;

Future<void> createHeadlessSession(String linkToken) async {
  _headlessSession = await createPlaidHeadlessSession(
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
      onLoad: () {
        _headlessSession?.start();
      },
    ),
  );
}
```

You can also call `start()` later from your own UI once the session is ready.

## Embedded Search

Replace the old embedded view with `PlaidEmbeddedSearchView`:

```dart
SizedBox(
  height: 420,
  child: PlaidEmbeddedSearchView(
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
    onLoad: () {
      print('Embedded Search loaded');
    },
  ),
);
```

Embedded Search is mobile-only in this SDK. Android currently supports one
active embedded search view at a time because the native result callback does
not expose a per-view result identifier.

## FinanceKit

FinanceKit is available on iOS only. Android returns a FinanceKit unsupported
error.

```dart
try {
  await syncFinanceKit(
    FinanceKitConfiguration(
      token: linkToken,
      requestAuthorizationIfNeeded: true,
      syncBehavior: FinanceKitSyncBehavior.live,
    ),
  );
} on FinanceKitException catch (error) {
  print(error.code);
  print(error.message);
}
```

Use `FinanceKitSyncBehavior.simulated` for simulated sync behavior.

## OAuth And Redirect Handling

The community package exposed `PlaidLink.resumeAfterTermination(...)`. The
official Flutter SDK does not expose a separate resume method. OAuth redirect
continuation is handled by the native Plaid SDKs and your app's platform
configuration.

For iOS, configure your Plaid redirect URI as a Universal Link in the Plaid
Dashboard and in your app entitlement setup. For Android, register the app
package name in the Plaid Dashboard and follow the native Android setup for the
Link SDK version used by this package.

## Close Handling

The community package exposed `PlaidLink.close()`. The official session API does
not expose a Flutter-level close method. Let the Link flow terminate through the
native UI and handle `onExit`.

## Migration Checklist

- Replace `plaid_flutter` with `plaid_link_flutter` in `pubspec.yaml`.
- Update imports to `package:plaid_link_flutter/plaid_link_flutter.dart`.
- Replace global `PlaidLink.create()` calls with a flow-specific create method.
- Store the returned session object in widget or state-management scope.
- Replace `PlaidLink.open()` with `PlaidLinkSession.open()`.
- Move global stream listeners into `onSuccess`, `onExit`, `onEvent`, and
  `onLoad` callbacks.
- Rename `LinkEvent.name` reads to `LinkEvent.eventName`.
- Use `LayerTokenConfiguration` and `PlaidLayerSession` for Layer.
- Use `createPlaidHeadlessSession()` and `PlaidHeadlessSession.start()` for
  Headless.
- Use `PlaidEmbeddedSearchView` for Embedded Search.
- Gate FinanceKit behind iOS checks in your app code.
- Confirm your backend creates the correct link token type for each flow.
- Re-test OAuth redirects using your app's production redirect URI setup.
