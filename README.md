# Plaid Link Flutter

Official Flutter plugin for Plaid Link.

This first implementation supports regular Link sessions with the same session-shaped API as the React Native SDK:

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

## Native SDKs

- iOS: LinkKit `7.0.1`, vendored at `ios/Frameworks/LinkKit.xcframework`
- Android: `com.plaid.link:sdk-core:6.0.0`

The vendored iOS framework intentionally contains only iOS device and simulator slices. The Mac Catalyst slice is not included.

## Requirements

- Flutter `3.29.3+`
- Dart `3.7+`
- iOS `15.0+`
- Android `minSdk 26+`

## Example App

The example app mirrors the React Native example visually for the regular Link session flow:

```sh
cd example
flutter run
```

Paste a `link_token`, create a Link session, then open Link. The app displays success, exit, and event callback results.

## Current Scope

Implemented:

- `createPlaidLinkSession`
- `PlaidLinkSession.open([bool fullScreen = false])`
- `PlaidLink.sdkVersion`
- Success, exit, and event payload parsing
- iOS and Android native regular Link sessions

Planned follow-ups:

- `createPlaidLayerSession`
- `createPlaidHeadlessSession`
- `syncFinanceKit`
- `PlaidEmbeddedSearchView`
