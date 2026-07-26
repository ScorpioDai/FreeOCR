#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELEASE_DIR="$ROOT_DIR/release"
APP_BUNDLE="$RELEASE_DIR/FreeOCR.app"
INFO_PLIST="$APP_BUNDLE/Contents/Info.plist"

if [[ ! -d "$APP_BUNDLE" || ! -f "$INFO_PLIST" ]]; then
  echo "Release app is missing. Run ./script/package_release.sh first." >&2
  exit 1
fi

VERSION="$(plutil -extract CFBundleShortVersionString raw "$INFO_PLIST")"
DMG_PATH="$RELEASE_DIR/FreeOCR-$VERSION-arm64.dmg"
STAGING_ROOT="$ROOT_DIR/work/dmg-staging"
STAGING_DIR="$STAGING_ROOT/FreeOCR"

rm -f "$DMG_PATH"
rm -rf "$STAGING_ROOT"
mkdir -p "$STAGING_DIR"

ditto "$APP_BUNDLE" "$STAGING_DIR/FreeOCR.app"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create \
  -volname "FreeOCR $VERSION" \
  -srcfolder "$STAGING_DIR" \
  -ov \
  -format UDZO \
  -imagekey zlib-level=9 \
  "$DMG_PATH"

rm -rf "$STAGING_ROOT"

echo "Release disk image created:"
echo "  $DMG_PATH"
