#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FRAMEWORK="$ROOT_DIR/ios/Frameworks/LinkKit.xcframework"
INFO_PLIST="$FRAMEWORK/Info.plist"
EXPECTED_VERSION="7.1.0"
EXPECTED_DEVICE_SHA="4901b49e548f7230b194bfdfcacb2ae8c8bf063dee8f05288b8c3eb25ed89275"
EXPECTED_SIMULATOR_SHA="d38cbb1ab3d2566018aeb58accdc293a303c64317e33ff90dcb0aff2364f9eaf"
EXPECTED_DEVICE_SIZE="2602512"
EXPECTED_SIMULATOR_SIZE="5126880"

if [[ ! -d "$FRAMEWORK" ]]; then
  echo "Missing LinkKit.xcframework at $FRAMEWORK"
  exit 1
fi

VERSION=$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$FRAMEWORK/ios-arm64/LinkKit.framework/Info.plist")
if [[ "$VERSION" != "$EXPECTED_VERSION" ]]; then
  echo "Expected LinkKit $EXPECTED_VERSION, found $VERSION"
  exit 1
fi

LIBRARIES=$(/usr/libexec/PlistBuddy -c 'Print :AvailableLibraries' "$INFO_PLIST")
if ! grep -q "LibraryIdentifier = ios-arm64" <<< "$LIBRARIES"; then
  echo "Missing ios-arm64 LinkKit slice"
  exit 1
fi
if ! grep -q "LibraryIdentifier = ios-arm64_x86_64-simulator" <<< "$LIBRARIES"; then
  echo "Missing ios-arm64_x86_64-simulator LinkKit slice"
  exit 1
fi
if grep -q "maccatalyst" <<< "$LIBRARIES"; then
  echo "Mac Catalyst LinkKit slice must not be present"
  exit 1
fi

echo "LinkKit $VERSION slices:"
find "$FRAMEWORK" -maxdepth 1 -mindepth 1 -type d -print | sort

device_binary="$FRAMEWORK/ios-arm64/LinkKit.framework/LinkKit"
simulator_binary="$FRAMEWORK/ios-arm64_x86_64-simulator/LinkKit.framework/LinkKit"
device_sha=$(shasum -a 256 "$device_binary" | awk '{print $1}')
simulator_sha=$(shasum -a 256 "$simulator_binary" | awk '{print $1}')
device_size=$(stat -f "%z" "$device_binary")
simulator_size=$(stat -f "%z" "$simulator_binary")

if [[ "$device_sha" != "$EXPECTED_DEVICE_SHA" || "$simulator_sha" != "$EXPECTED_SIMULATOR_SHA" ]]; then
  echo "LinkKit checksum mismatch:"
  echo "ios-arm64 expected $EXPECTED_DEVICE_SHA found $device_sha"
  echo "ios-arm64_x86_64-simulator expected $EXPECTED_SIMULATOR_SHA found $simulator_sha"
  exit 1
fi

if [[ "$device_size" != "$EXPECTED_DEVICE_SIZE" || "$simulator_size" != "$EXPECTED_SIMULATOR_SIZE" ]]; then
  echo "LinkKit binary size mismatch:"
  echo "ios-arm64 expected $EXPECTED_DEVICE_SIZE found $device_size"
  echo "ios-arm64_x86_64-simulator expected $EXPECTED_SIMULATOR_SIZE found $simulator_size"
  exit 1
fi

echo "LinkKit binary checksums:"
echo "$device_sha  $device_binary"
echo "$simulator_sha  $simulator_binary"

echo "LinkKit binary sizes:"
echo "$device_binary $device_size bytes"
echo "$simulator_binary $simulator_size bytes"
