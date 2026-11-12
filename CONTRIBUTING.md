# Contributing

Thanks for helping improve the Plaid Link Flutter SDK. This repository contains
the Dart API, native iOS and Android integrations, a vendored LinkKit framework,
and the example app used to validate releases.

## Development setup

Install Flutter 3.29.3 or later with Dart 3.7 or later, then fetch package and
example dependencies:

```sh
flutter pub get
cd example
flutter pub get
```

Android development requires Java 17 and the Android SDK configured by the
example project. iOS development requires macOS, Xcode 16.1 or later, and
CocoaPods.

## Local checks

Run the focused Dart and Flutter checks before opening a pull request:

```sh
bash tool/check_versions.sh
bash tool/validate_linkkit.sh
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test --coverage
(cd example && flutter analyze && flutter test)
dart doc
dart pub publish --dry-run
```

For Android changes, also run:

```sh
(cd example && flutter build apk --debug)
(cd example/android && ./gradlew :plaid_link_flutter:testDebugUnitTest)
```

For iOS changes, run the checks against **both** integrations, because the
plugin supports Swift Package Manager and CocoaPods and CI covers each
separately. Switch integrations with `flutter config`:

> **Clone this repository into a directory named `plaid_link_flutter` to build
> the example with Swift Package Manager.** The example depends on the plugin by
> relative path; Flutter names the SwiftPM symlink for a path dependency after
> the plugin's root directory, and SwiftPM derives a path dependency's identity
> from its directory name. The repository's own name, `plaid-link-flutter`,
> therefore fails to resolve with `identity 'plaid-link-flutter' doesn't match
> override's identity (directory name) 'plaid_link_flutter'`. This affects only
> the bundled example; consumers installing from pub.dev are unaffected, and the
> `iOS (Swift Package Manager)` CI job checks out into a correctly named
> directory for the same reason.


```sh
# CocoaPods
flutter config --no-enable-swift-package-manager
(cd ios && pod lib lint plaid_link_flutter.podspec --allow-warnings --skip-import-validation --no-clean)
(cd example && flutter build ios --simulator --no-codesign)
bash tool/verify_linkkit_embedded.sh example/build/ios/iphonesimulator/Runner.app

# Swift Package Manager (needs Flutter 3.44+)
flutter config --enable-swift-package-manager
(cd example && flutter build ios --simulator --no-codesign)
bash tool/verify_linkkit_embedded.sh example/build/ios/iphonesimulator/Runner.app

(cd example && xcodebuild test \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RunnerTests \
  CODE_SIGNING_ALLOWED=NO)
```

`tool/verify_linkkit_embedded.sh` is not redundant with a successful build: a
binary target can compile and link and still leave the framework unembedded,
which fails only at runtime on a physical device
([swift-package-manager#6069](https://github.com/apple/swift-package-manager/issues/6069)).

## iOS integration layout

The iOS plugin follows Flutter's Swift Package Manager layout, which CocoaPods
reads from the same place so there is only ever one copy of the source:

```
ios/
├── plaid_link_flutter.podspec        # points into the directory below
└── plaid_link_flutter/
    ├── Package.swift
    ├── LinkKit.xcframework           # vendored, shared by both integrations
    └── Sources/plaid_link_flutter/
        ├── PlaidLinkFlutterPlugin.swift
        └── Resources/PrivacyInfo.xcprivacy
```

`Package.swift` reaches the framework with a local `.binaryTarget`, so Swift
Package Manager and CocoaPods consumers get the byte-identical binary that
`tool/validate_linkkit.sh` checksums.

The XCFramework must stay **inside** `ios/plaid_link_flutter/`. Flutter symlinks
the package into the app's ephemeral `Packages` directory and SwiftPM resolves
binary target paths relative to that symlink, so a path reaching outside the
package directory fails to resolve during an app build with "does not contain a
binary artifact".

LinkKit is vendored rather than fetched because upstream `plaid-link-ios`
dropped CocoaPods support at 7.0.0 — 6.5.1 is the last version published to
CocoaPods — so vendoring is the only way to ship LinkKit 7.x to CocoaPods
users. Once CocoaPods support is dropped here, replace the local
`.binaryTarget` with a package dependency on
[plaid-link-ios-spm](https://github.com/plaid/plaid-link-ios-spm) and delete the
vendored framework. Note that its 7.x tags are bare versions with no `v` prefix
(`7.4.0`), unlike the older `v6.5.8`. Dropping CocoaPods also means raising the
`flutter` constraint in `pubspec.yaml` to `3.44+`, which is a breaking change
for consumers below that.

## Pull requests

- Keep public APIs backward compatible unless a breaking change is explicitly
  approved and documented.
- Update `README.md`, `CHANGELOG.md`, or the files under `doc/` when behavior,
  setup, supported versions, or migration guidance changes.
- Include Android and iOS testing notes when native behavior changes.
- Add or update tests for behavior changes and bug fixes.
- Do not commit generated documentation, coverage output, build artifacts,
  credentials, tokens, personally identifiable information, or local editor
  and system files.

## Release process

1. Update the package version in `pubspec.yaml` and every synchronized native,
   documentation, test, and example surface checked by
   `tool/check_versions.sh`.
2. Add release notes to `CHANGELOG.md`. When native SDK versions change, link
   to their releases and summarize their release notes.
3. For a LinkKit update, replace the vendored XCFramework from the official
   iOS SDK release and update the version, slice sizes, and checksums in
   `tool/validate_linkkit.sh`. Both the CocoaPods and Swift Package Manager
   paths read that one vendored copy, so there is a single version to change.
4. Run all applicable checks above and open a pull request.
5. After the pull request is approved, CI passes, and it is merged, tag the
   merge commit with the exact package version and push the tag.
6. Create the matching GitHub release from the changelog entry.
7. Run `dart pub publish --dry-run`, review the package contents, and publish
   with `dart pub publish`. Published versions cannot be replaced.
