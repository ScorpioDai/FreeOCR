#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BOOTSTRAP_PYTHON="${FREEOCR_BOOTSTRAP_PYTHON:-$ROOT_DIR/Runtime/.venv/bin/python}"
LOCK_FILE="$ROOT_DIR/Runtime/requirements-lock.txt"
BUILD_VENV="$ROOT_DIR/work/runtime-build-venv"
PORTABLE="$ROOT_DIR/Runtime/python"
LOCK_HASH="$(shasum -a 256 "$LOCK_FILE" | awk '{print $1}')"
BUILD_MARKER="$BUILD_VENV/.freeocr-requirements-sha256"
PORTABLE_MARKER="$PORTABLE/.freeocr-requirements-sha256"

if [[ ! -x "$BOOTSTRAP_PYTHON" ]]; then
  echo "Bootstrap Python is missing. Set FREEOCR_BOOTSTRAP_PYTHON if needed." >&2
  exit 1
fi

if [[ -x "$PORTABLE/bin/python3" ]] && \
   [[ -f "$PORTABLE_MARKER" ]] && \
   [[ "$(cat "$PORTABLE_MARKER")" == "$LOCK_HASH" ]] && \
   "$PORTABLE/bin/python3" -c 'import fastapi, pypdfium2, PIL, paddleocr, onnxruntime' >/dev/null 2>&1; then
  echo "Portable PP-OCRv6 runtime already prepared"
  exit 0
fi

if [[ ! -x "$BUILD_VENV/bin/python" ]] || \
   [[ ! -f "$BUILD_MARKER" ]] || \
   [[ "$(cat "$BUILD_MARKER")" != "$LOCK_HASH" ]]; then
  rm -rf "$BUILD_VENV"
  mkdir -p "$ROOT_DIR/work"
  "$BOOTSTRAP_PYTHON" -m venv "$BUILD_VENV"
  "$BUILD_VENV/bin/python" -m pip install --disable-pip-version-check --upgrade pip
  "$BUILD_VENV/bin/python" -m pip install --disable-pip-version-check -r "$LOCK_FILE"
  printf '%s\n' "$LOCK_HASH" > "$BUILD_MARKER"
fi

BASE_PREFIX="$("$BUILD_VENV/bin/python" -c 'import sys; print(sys.base_prefix)')"
PYTHON_VERSION="$("$BUILD_VENV/bin/python" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
SITE_PACKAGES="$BUILD_VENV/lib/python$PYTHON_VERSION/site-packages"
PORTABLE_SITE_PACKAGES="$PORTABLE/lib/python$PYTHON_VERSION/site-packages"

rm -rf "$PORTABLE"
ditto "$BASE_PREFIX" "$PORTABLE"
rm -rf "$PORTABLE_SITE_PACKAGES"
mkdir -p "$PORTABLE_SITE_PACKAGES"
ditto "$SITE_PACKAGES" "$PORTABLE_SITE_PACKAGES"
printf '%s\n' "$LOCK_HASH" > "$PORTABLE_MARKER"

"$PORTABLE/bin/python3" -c 'import fastapi, pypdfium2, PIL, paddleocr, onnxruntime; print("Portable PP-OCRv6 runtime ready")'
