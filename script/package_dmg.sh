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
VOLUME_NAME="FreeOCR $VERSION Installer"
DMG_PATH="$RELEASE_DIR/FreeOCR-$VERSION-arm64.dmg"
WORK_ROOT="$ROOT_DIR/work/dmg-build"
RW_DMG="$WORK_ROOT/FreeOCR-read-write.dmg"
COMPRESSED_DMG="$WORK_ROOT/FreeOCR-compressed.dmg"
BACKGROUND_PNG="$WORK_ROOT/installer-background.png"
MOUNT_POINT=""

cleanup() {
  if [[ -n "$MOUNT_POINT" ]] && mount | grep -Fq "on $MOUNT_POINT "; then
    hdiutil detach "$MOUNT_POINT" >/dev/null 2>&1 || true
  fi
  rm -rf "$WORK_ROOT"
}
trap cleanup EXIT

rm -rf "$WORK_ROOT"
mkdir -p "$WORK_ROOT"

/usr/bin/swift "$ROOT_DIR/script/make_dmg_background.swift" "$BACKGROUND_PNG"

APP_SIZE_MB="$(du -sm "$APP_BUNDLE" | awk '{print $1}')"
IMAGE_SIZE_MB="$((APP_SIZE_MB + 512))"

hdiutil create \
  -size "${IMAGE_SIZE_MB}m" \
  -fs APFS \
  -volname "$VOLUME_NAME" \
  -ov \
  "$RW_DMG" >/dev/null

ATTACH_OUTPUT="$(hdiutil attach -readwrite -noverify -noautoopen "$RW_DMG")"
MOUNT_POINT="$(printf '%s\n' "$ATTACH_OUTPUT" | tail -n 1 | awk -F '\t' '{print $NF}')"

if [[ ! -d "$MOUNT_POINT" ]]; then
  echo "Could not resolve the writable DMG mount point." >&2
  exit 1
fi

ditto "$APP_BUNDLE" "$MOUNT_POINT/FreeOCR.app"
ln -s /Applications "$MOUNT_POINT/Applications"
mkdir -p "$MOUNT_POINT/.background"
ditto "$BACKGROUND_PNG" "$MOUNT_POINT/.background/installer-background.png"

/usr/bin/osascript "$ROOT_DIR/script/configure_dmg.applescript" "$VOLUME_NAME"
/usr/bin/SetFile -a V "$MOUNT_POINT/.background"
sync

hdiutil detach "$MOUNT_POINT" >/dev/null
MOUNT_POINT=""

hdiutil convert \
  "$RW_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -o "$COMPRESSED_DMG" >/dev/null

hdiutil verify "$COMPRESSED_DMG" >/dev/null
mv -f "$COMPRESSED_DMG" "$DMG_PATH"

echo "Release disk image created:"
echo "  $DMG_PATH"
