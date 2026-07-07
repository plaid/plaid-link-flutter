#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PUBSPEC="$ROOT_DIR/pubspec.yaml"
PODSPEC="$ROOT_DIR/ios/plaid_link_flutter.podspec"
IOS_PLUGIN="$ROOT_DIR/ios/Classes/PlaidLinkFlutterPlugin.swift"
ANDROID_MANIFEST="$ROOT_DIR/android/src/main/AndroidManifest.xml"

pubspec_version=$(sed -nE 's/^version:[[:space:]]*([^[:space:]]+).*/\1/p' "$PUBSPEC")
podspec_version=$(sed -nE "s/.*s.version[[:space:]]*=[[:space:]]*'([^']+)'.*/\1/p" "$PODSPEC")
ios_bridge_version=$(sed -nE 's/.*sdkVersion:[[:space:]]*String[[:space:]]*=[[:space:]]*"([^"]+)".*/\1/p' "$IOS_PLUGIN")
android_bridge_version=$(sed -nE 's/.*android:value="([^"]+)".*/\1/p' "$ANDROID_MANIFEST")

if [[ -z "$pubspec_version" || -z "$podspec_version" || -z "$ios_bridge_version" || -z "$android_bridge_version" ]]; then
  echo "Failed to parse one or more SDK versions:"
  echo "pubspec=$pubspec_version podspec=$podspec_version ios=$ios_bridge_version android=$android_bridge_version"
  exit 1
fi

if [[ "$pubspec_version" != "$podspec_version" ||
      "$pubspec_version" != "$ios_bridge_version" ||
      "$pubspec_version" != "$android_bridge_version" ]]; then
  echo "Version mismatch:"
  echo "pubspec.yaml: $pubspec_version"
  echo "ios/plaid_link_flutter.podspec: $podspec_version"
  echo "ios PlaidFlutterPlugin.sdkVersion: $ios_bridge_version"
  echo "android manifest com.plaid.link.flutter: $android_bridge_version"
  exit 1
fi

echo "All Flutter bridge versions match: $pubspec_version"
