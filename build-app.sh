#!/bin/zsh
# SwiftPM으로 빌드한 Universal(Apple Silicon + Intel) 실행 파일을 SkipPlayer.app 번들로 묶고,
# App Sandbox + Hardened Runtime으로 ad-hoc 서명한다.
set -euo pipefail
cd "$(dirname "$0")"

ARCHS=(--arch arm64 --arch x86_64)
swift build -c release "${ARCHS[@]}"
BIN="$(swift build -c release "${ARCHS[@]}" --show-bin-path)/SkipPlayer"

APP=SkipPlayer.app
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/SkipPlayer"
cp Info.plist "$APP/Contents/Info.plist"
cp Resources/AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"
codesign --force --options runtime --entitlements SkipPlayer.entitlements -s - "$APP"

echo "Built $PWD/$APP"
