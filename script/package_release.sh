#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_BUNDLE="$ROOT_DIR/release/FreeOCR.app"

cd "$ROOT_DIR"
"$ROOT_DIR/script/prepare_portable_runtime.sh"
swift build -c release
"$ROOT_DIR/script/make_icon.sh"
BUILD_BINARY="$(swift build -c release --show-bin-path)/FreeOCR"
"$ROOT_DIR/script/stage_bundle.sh" "$BUILD_BINARY" "$APP_BUNDLE" 1
"$ROOT_DIR/script/package_archives.sh"
"$ROOT_DIR/script/package_dmg.sh"

echo "Release app created at: $APP_BUNDLE"
