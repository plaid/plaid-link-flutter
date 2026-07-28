# Plaid Link Flutter

Official Flutter plugin for Plaid Link.

## Installation

Add the package:

```yaml
dependencies:
  plaid_link_flutter: ^1.0.0-beta.1
```

Then import it:

```dart
import 'package:plaid_link_flutter/plaid_link_flutter.dart';
```

If you are migrating from the community `plaid_flutter` package, start with the
[migration guide](doc/migration-guide.md).

For copy-paste examples, see [recipes](doc/recipes.md). For field-level model
details, see the [API reference](doc/api-reference.md).

## Platform Setup

### iOS

Set your host app deployment target to iOS 15.0 or later:

```ruby
# ios/Podfile
platform :ios, '15.0'
```

Then install pods from the example or host app:

```sh
cd ios
pod install
```

The plugin vendors LinkKit `7.0.5` at
`ios/Frameworks/LinkKit.xcframework`. The framework contains iOS device and
simulator slices only; Mac Catalyst is not shipped.

For Identity Verification flows, add `NSCameraUsageDescription` to the host
app's `Info.plist` if your Link token can require document or selfie capture.

For Embedded Search, render `PlaidEmbeddedSearchView` with a finite width and
height. It is backed by a Flutter platform view (`UIKitView`) on iOS.

### Android

Set the host app `minSdk` to 26 or later:

```kotlin
// android/app/build.gradle.kts
android {
  defaultConfig {
    minSdk = 26
  }
}
```

The plugin depends on `com.plaid.link:sdk-core:6.1.0`. Most apps do not need
additional ProGuard/R8 rules. If your release build has custom aggressive
shrinking and strips the Flutter plugin, keep the plugin package:

```proguard
-keep class com.plaid.plaid_link_flutter.** { *; }
```

For Identity Verification flows, add the camera/audio permissions required by
your configured Plaid products to the host app manifest.

For Embedded Search, render `PlaidEmbeddedSearchView` with a finite width and
height. It is backed by a Flutter platform view (`AndroidView`) on Android.
Android currently supports one active embedded search view at a time.

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

- iOS: LinkKit `7.0.5`, vendored at `ios/Frameworks/LinkKit.xcframework`
- Android: `com.plaid.link:sdk-core:6.1.0`

The vendored iOS framework intentionally contains only iOS device and simulator slices. The Mac Catalyst slice is not included.

## Requirements

- Flutter `3.29.3+`
- Dart `3.7+`
- iOS `15.0+`
- Android `minSdk 26+`

## Setup Notes

Create link tokens on your server using Plaid's `/link/token/create` endpoint,
then pass the link token into the Flutter app. 

For OAuth flows, configure your redirect URI in the Plaid Dashboard and your
native app platform settings. iOS OAuth return handling is owned by the native
SDK and your Universal Link configuration. On Android, register the app package
name and any redirect URI configuration required by your Plaid Link token.


Identity Verification flows may require camera usage strings and permissions in
the host app.

## Version Reporting

`PlaidLink.sdkVersion` returns the native Plaid Link SDK version:

- iOS: `Plaid.version` from LinkKit.
- Android: `Plaid.VERSION_NAME` from the Android Link SDK.

It does not return the Flutter package version. The Flutter bridge version is
still exposed to the native SDKs for wrapper detection through
`PlaidFlutterPlugin.sdkVersion` on iOS and the Android manifest metadata key
`com.plaid.link.flutter`.

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

- Each session owns its own callbacks, routed by a per-session id, so multiple sessions never cross-deliver each other's events. The native Link UI is single-active, though: only the most recently created session can actually be opened at a time, so the typical flow is create, then open, then a terminal result.
- Success and exit callbacks are terminal and automatically dispose the session's listeners. Event callbacks are non-terminal. Call `dispose()` on a session to abandon it if it was created but never opened (for example when the owning widget disposes).
- Embedded Search is mobile-only. Android currently supports one active embedded search view at a time because the native result callback does not expose a per-view result identifier.

## Errors And Troubleshooting

Create, open, start, and submit methods throw `PlaidLinkException`, which exposes
a typed `PlaidLinkErrorType type`, the raw `String code`, and a `message`. Switch
on `type` (with an `unknown` fallback) or read `code` directly. Common codes:

- `INVALID_TOKEN`: the token argument was empty.
- `LINK_SESSION_CREATE_ERROR`: native Link session creation failed.
- `LAYER_SESSION_CREATE_ERROR`: native Layer session creation failed.
- `HEADLESS_SESSION_CREATE_ERROR`: native Headless session creation failed.
- `PLAID_NO_ACTIVITY`: Android could not find the current `Activity`.
- `PLAID_NO_VC`: iOS could not find a presenting view controller.
- `PLAID_NO_LAYER_SESSION`: `submit` was called before creating a Layer session.
- `PLAID_NO_SESSION`: `open`/`start` was called before a session was created.
- `PLAID_OPEN_ERROR`: Android failed to open or start the native session.

`syncFinanceKit` throws `FinanceKitException` instead of exposing the raw
`PlatformException`. Known codes include `UNSUPPORTED_ANDROID`,
`UNSUPPORTED_IOS_VERSION`, `INVALID_TOKEN`, `PERMISSION_ERROR`,
`LINK_API_ERROR`, and `PERMISSION_ACCESS_ERROR`.

If `open()` appears to do nothing, confirm that session creation completed
successfully, the widget is attached to a visible `Activity` or view controller,
and the link token was created for the same flow you are trying to run.

## Real Device Guidance

Most regular Link sandbox flows work in simulators. OAuth app-switching and
FinanceKit should be verified on real devices before release.

FinanceKit requires iOS 17.4 or later. Live FinanceKit sync also requires the
Apple FinanceKit entitlement and an eligible Item. Use
`FinanceKitSyncBehavior.simulated` for development where appropriate.

Use sandbox Link tokens and Plaid test institutions for regular Link, Layer,
Headless, and Embedded Search smoke tests. Always test the final OAuth redirect
configuration that will ship: the iOS redirect URI and Universal Link domain
association, and the Android package name and app link/deep link handling.

## Current Scope

Implemented:

- `createPlaidLinkSession`
- `PlaidLinkSession.open([bool fullScreen = false])`
- `createPlaidLayerSession`
- `PlaidLayerSession.open()`
- `PlaidLayerSession.submit(SubmissionData data)`
- `createPlaidHeadlessSession`
- `PlaidHeadlessSession.start()`
- `PlaidLinkSession.dispose()` (and Layer/Headless) for callback cleanup
- `syncFinanceKit`
- `PlaidEmbeddedSearchView`
- `PlaidLink.sdkVersion`
- Success, exit, and event payload parsing
- iOS and Android native regular Link, Layer, Headless, and Embedded Search
- iOS native FinanceKit sync; Android returns a FinanceKit unsupported error
