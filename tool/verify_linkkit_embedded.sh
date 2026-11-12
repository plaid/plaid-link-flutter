#!/usr/bin/env bash
# Verifies that LinkKit.framework is embedded in a built .app bundle.
#
# A Swift Package Manager package whose framework comes from a binary target can
# compile and link successfully and still not embed the framework, which fails
# only at runtime on device (swiftlang/swift-package-manager#6069). Checking the
# bundle catches that in CI instead of in someone's crash report.
set -euo pipefail

APP_PATH="${1:-}"

if [[ -z "$APP_PATH" ]]; then
  echo "Usage: $0 <path to built .app>"
  exit 1
fi

if [[ ! -d "$APP_PATH" ]]; then
  echo "No app bundle at $APP_PATH"
  exit 1
fi

FRAMEWORK="$APP_PATH/Frameworks/LinkKit.framework"

if [[ ! -d "$FRAMEWORK" ]]; then
  echo "LinkKit.framework is not embedded in $APP_PATH"
  echo "Embedded frameworks:"
  ls -1 "$APP_PATH/Frameworks" 2>/dev/null || echo "  (no Frameworks directory)"
  exit 1
fi

BINARY="$FRAMEWORK/LinkKit"

if [[ ! -f "$BINARY" ]]; then
  echo "LinkKit.framework is present but holds no binary at $BINARY"
  exit 1
fi

echo "LinkKit.framework is embedded at $FRAMEWORK"
echo "Architectures:"
lipo -archs "$BINARY"
