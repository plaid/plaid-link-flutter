#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT_DIR/pubspec.yaml"
PODSPEC="$ROOT_DIR/ios/plaid_link_flutter.podspec"
IOS_PLUGIN="$ROOT_DIR/ios/plaid_link_flutter/Sources/plaid_link_flutter/PlaidLinkFlutterPlugin.swift"
VALIDATE_LINKKIT="$ROOT_DIR/tool/validate_linkkit.sh"
IOS_TEST="$ROOT_DIR/example/ios/RunnerTests/RunnerTests.swift"
IOS_PODFILE_LOCK="$ROOT_DIR/example/ios/Podfile.lock"
ANDROID_BUILD_GRADLE="$ROOT_DIR/android/build.gradle"
ANDROID_MANIFEST="$ROOT_DIR/android/src/main/AndroidManifest.xml"
README="$ROOT_DIR/README.md"
CHANGELOG="$ROOT_DIR/CHANGELOG.md"
MIGRATION_GUIDE="$ROOT_DIR/doc/migration-guide.md"

pubspec_version=$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' "$PUBSPEC")
podspec_version=$(sed -nE "s/.*s.version[[:space:]]*=[[:space:]]*'([^']+)'.*/\1/p" "$PODSPEC")
ios_bridge_version=$(sed -nE 's/.*sdkVersion:[[:space:]]*String[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$IOS_PLUGIN")
ios_test_version=$(sed -nE 's/.*XCTAssertEqual\(PlaidFlutterPlugin\.sdkVersion,[[:space:]]*"([^"]+)"\).*/\1/p' "$IOS_TEST")
ios_pod_lock_version=$(sed -nE 's/^  - plaid_link_flutter \(([^)]+)\):.*/\1/p' "$IOS_PODFILE_LOCK" | head -1)
android_gradle_version=$(sed -nE 's/^version[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$ANDROID_BUILD_GRADLE")
android_bridge_version=$(sed -nE 's/.*android:value="([^"]+)".*/\1/p' "$ANDROID_MANIFEST")
# Docs pin the published version via a caret constraint (e.g. ^1.2.3);
# strip the leading caret so it can be compared to the raw pubspec version.
readme_version=$(sed -nE 's/.*plaid_link_flutter:[[:space:]]*\^?([^[:space:]]+).*/\1/p' "$README" | head -1)
migration_version=$(sed -nE 's/.*plaid_link_flutter:[[:space:]]*\^?([^[:space:]]+).*/\1/p' "$MIGRATION_GUIDE" | head -1)
# The latest CHANGELOG entry is the first level-2 heading that starts with a digit.
changelog_version=$(sed -nE 's/^##[[:space:]]+([0-9][^[:space:]]*).*/\1/p' "$CHANGELOG" | head -1)

if [[ -z "$pubspec_version" || -z "$podspec_version" || -z "$ios_bridge_version" ||
      -z "$ios_test_version" || -z "$ios_pod_lock_version" || -z "$android_gradle_version" ||
      -z "$android_bridge_version" || -z "$readme_version" ||
      -z "$migration_version" || -z "$changelog_version" ]]; then
  echo "Failed to parse one or more SDK versions:"
  echo "pubspec=$pubspec_version podspec=$podspec_version ios=$ios_bridge_version ios_test=$ios_test_version ios_pod_lock=$ios_pod_lock_version"
  echo "android_gradle=$android_gradle_version android_manifest=$android_bridge_version"
  echo "readme=$readme_version migration=$migration_version changelog=$changelog_version"
  exit 1
fi

mismatch=0
check() {
  local label="$1"
  local value="$2"
  if [[ "$value" != "$pubspec_version" ]]; then
    echo "Version mismatch: $label = $value (expected $pubspec_version from pubspec.yaml)"
    mismatch=1
  fi
}

check "ios/plaid_link_flutter.podspec" "$podspec_version"
check "ios PlaidFlutterPlugin.sdkVersion" "$ios_bridge_version"
check "iOS bridge version test" "$ios_test_version"
check "example iOS Podfile.lock" "$ios_pod_lock_version"
check "android/build.gradle" "$android_gradle_version"
check "android manifest com.plaid.link.flutter" "$android_bridge_version"
check "README.md install snippet" "$readme_version"
check "doc/migration-guide.md install snippet" "$migration_version"
check "CHANGELOG.md latest entry" "$changelog_version"

if [[ "$mismatch" -ne 0 ]]; then
  exit 1
fi

echo "All SDK versions match: $pubspec_version"

# The native SDK versions live in the build files and are quoted again in the docs.
# Nothing else keeps those copies honest, so compare each set against its build file.
linkkit_pinned=$(sed -nE 's/^EXPECTED_VERSION="([^"]+)".*/\1/p' "$VALIDATE_LINKKIT")
linkkit_readme_vendored=$(sed -nE 's/.*vendors LinkKit `([^`]+)`.*/\1/p' "$README" | head -1)
linkkit_readme_list=$(sed -nE 's/^- iOS: LinkKit `([^`]+)`.*/\1/p' "$README" | head -1)
linkkit_migration=$(sed -nE 's/.*iOS LinkKit ([0-9][^,]*),.*/\1/p' "$MIGRATION_GUIDE" | head -1)

android_pinned=$(sed -nE 's/.*com\.plaid\.link:sdk-core:([^")]+)".*/\1/p' "$ANDROID_BUILD_GRADLE" | head -1)
android_readme=$(sed -nE 's/^- Android: `com\.plaid\.link:sdk-core:([^`]+)`.*/\1/p' "$README" | head -1)
android_migration=$(sed -nE 's/.*Android Link SDK ([0-9][^ |]*).*/\1/p' "$MIGRATION_GUIDE" | head -1)

if [[ -z "$linkkit_pinned" || -z "$linkkit_readme_vendored" || -z "$linkkit_readme_list" ||
      -z "$linkkit_migration" || -z "$android_pinned" || -z "$android_readme" ||
      -z "$android_migration" ]]; then
  echo "Failed to parse one or more native SDK versions:"
  echo "linkkit: pinned=$linkkit_pinned readme_vendored=$linkkit_readme_vendored readme_list=$linkkit_readme_list migration=$linkkit_migration"
  echo "android: pinned=$android_pinned readme=$android_readme migration=$android_migration"
  exit 1
fi

native_mismatch=0
check_native() {
  local label="$1"
  local value="$2"
  local expected="$3"
  if [[ "$value" != "$expected" ]]; then
    echo "Native version mismatch: $label = $value (expected $expected)"
    native_mismatch=1
  fi
}

check_native "README.md vendored LinkKit" "$linkkit_readme_vendored" "$linkkit_pinned"
check_native "README.md native SDK list (iOS)" "$linkkit_readme_list" "$linkkit_pinned"
check_native "doc/migration-guide.md LinkKit" "$linkkit_migration" "$linkkit_pinned"
check_native "README.md native SDK list (Android)" "$android_readme" "$android_pinned"
check_native "doc/migration-guide.md Android Link SDK" "$android_migration" "$android_pinned"

if [[ "$native_mismatch" -ne 0 ]]; then
  exit 1
fi

echo "Native SDK versions match: LinkKit $linkkit_pinned, Android $android_pinned"
