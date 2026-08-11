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

For iOS changes, also run:

```sh
(cd ios && pod lib lint plaid_link_flutter.podspec --allow-warnings --skip-import-validation --no-clean)
(cd example && flutter build ios --simulator --no-codesign)
(cd example && xcodebuild test \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:RunnerTests \
  CODE_SIGNING_ALLOWED=NO)
```

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
   `tool/validate_linkkit.sh`.
4. Run all applicable checks above and open a pull request.
5. After the pull request is approved, CI passes, and it is merged, tag the
   merge commit with the exact package version and push the tag.
6. Create the matching GitHub release from the changelog entry.
7. Run `dart pub publish --dry-run`, review the package contents, and publish
   with `dart pub publish`. Published versions cannot be replaced.
