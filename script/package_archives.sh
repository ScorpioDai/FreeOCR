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
APP_ZIP="$RELEASE_DIR/FreeOCR-$VERSION-arm64.zip"
SOURCE_ZIP="$RELEASE_DIR/FreeOCR-$VERSION-source.zip"
GUIDE_COPY="$RELEASE_DIR/FreeOCR-使用与维护说明.md"
STAGING_ROOT="$ROOT_DIR/work/source-archive"
SOURCE_FOLDER="$STAGING_ROOT/FreeOCR-$VERSION-source"

rm -f "$APP_ZIP" "$SOURCE_ZIP" \
  "$GUIDE_COPY" "$RELEASE_DIR/.DS_Store"
rm -rf "$STAGING_ROOT"
mkdir -p "$SOURCE_FOLDER"

ditto -c -k --sequesterRsrc --keepParent "$APP_BUNDLE" "$APP_ZIP"

rsync -a \
  --exclude '.DS_Store' \
  --exclude '.codex/' \
  --exclude '.git/' \
  --exclude '.build/' \
  --exclude 'dist/' \
  --exclude 'release/' \
  --exclude 'work/' \
  --exclude 'Runtime/.venv/' \
  --exclude 'Runtime/python/' \
  --exclude '__pycache__/' \
  --exclude '*.pyc' \
  "$ROOT_DIR/" "$SOURCE_FOLDER/"

ditto -c -k --sequesterRsrc --keepParent "$SOURCE_FOLDER" "$SOURCE_ZIP"
ditto "$ROOT_DIR/RELEASE_GUIDE.md" "$GUIDE_COPY"
rm -rf "$STAGING_ROOT"

echo "Release archives created:"
echo "  $APP_ZIP"
echo "  $SOURCE_ZIP"
echo "  $GUIDE_COPY"
