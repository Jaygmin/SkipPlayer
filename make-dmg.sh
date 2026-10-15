#!/bin/zsh
# SkipPlayer.app을 빌드해서, Applications 바로가기와 함께 드래그 설치용 SkipPlayer.dmg로 묶는다.
set -euo pipefail
cd "$(dirname "$0")"

./build-app.sh

STAGING="$(mktemp -d)"
trap 'rm -rf "$STAGING"' EXIT
ditto SkipPlayer.app "$STAGING/SkipPlayer.app"
ln -s /Applications "$STAGING/Applications"

DMG=SkipPlayer.dmg
rm -f "$DMG"
hdiutil create -volname SkipPlayer -srcfolder "$STAGING" -format UDZO "$DMG"

echo "Built $PWD/$DMG"
