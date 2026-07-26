#!/usr/bin/env bash
set -euo pipefail

MODE="${1:-run}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="FreeOCR"
BUNDLE_ID="com.scorpiodai.FreeOCR.debug"
DISPLAY_NAME="FreeOCR Debug"
APP_BUNDLE="$ROOT_DIR/dist/$DISPLAY_NAME.app"

cd "$ROOT_DIR"
pkill -x "$APP_NAME" >/dev/null 2>&1 || true
pkill -f 'freeocr_service.py' >/dev/null 2>&1 || true

swift build
"$ROOT_DIR/script/make_icon.sh"
BUILD_BINARY="$(swift build --show-bin-path)/$APP_NAME"
"$ROOT_DIR/script/stage_bundle.sh" "$BUILD_BINARY" "$APP_BUNDLE" 0
plutil -replace CFBundleIdentifier -string "$BUNDLE_ID" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleDisplayName -string "$DISPLAY_NAME" "$APP_BUNDLE/Contents/Info.plist"
plutil -replace CFBundleName -string "$DISPLAY_NAME" "$APP_BUNDLE/Contents/Info.plist"
codesign --force --deep --sign - "$APP_BUNDLE"

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  --debug|debug)
    lldb -- "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
    ;;
  --logs|logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  --telemetry|telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  --verify|verify)
    open_app
    sleep 2
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--debug|--logs|--telemetry|--verify]" >&2
    exit 2
    ;;
esac
