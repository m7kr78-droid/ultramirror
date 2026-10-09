#!/bin/bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"

xcodebuild \
  -project PingTune.xcodeproj \
  -scheme PingTune \
  -configuration Release \
  -sdk iphoneos \
  -derivedDataPath "$ROOT/build" \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY="" \
  build

APP="$ROOT/build/Build/Products/Release-iphoneos/PingTune.app"
STAGE="$(mktemp -d)"
mkdir -p "$STAGE/Payload"
cp -R "$APP" "$STAGE/Payload/"
(cd "$STAGE" && zip -r "$ROOT/PingTune.ipa" Payload)
rm -rf "$STAGE"
echo "IPA: $ROOT/PingTune.ipa"
