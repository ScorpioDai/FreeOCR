#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 2 || $# -gt 3 ]]; then
  echo "usage: $0 <binary> <app-bundle> [include-runtime]" >&2
  exit 2
fi

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BINARY="$1"
APP_BUNDLE="$2"
INCLUDE_RUNTIME="${3:-0}"
DETECTION_MODEL_DIR="${FREEOCR_DETECTION_MODEL_PATH:-${FREEOCR_TRADITIONAL_DET_PATH:-$ROOT_DIR/../PaddlePaddle:PP-OCRv6_medium_det_onnx}}"
RECOGNITION_MODEL_DIR="${FREEOCR_RECOGNITION_MODEL_PATH:-${FREEOCR_TRADITIONAL_REC_PATH:-$ROOT_DIR/../PaddlePaddle:PP-OCRv6_medium_rec_onnx}}"
CONTENTS="$APP_BUNDLE/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

rm -rf "$APP_BUNDLE"
mkdir -p "$MACOS_DIR" "$RESOURCES_DIR/Runtime"
cp "$BINARY" "$MACOS_DIR/FreeOCR"
chmod +x "$MACOS_DIR/FreeOCR"
cp "$ROOT_DIR/Resources/Info.plist" "$CONTENTS/Info.plist"
cp "$ROOT_DIR/.build/AppIcon.icns" "$RESOURCES_DIR/AppIcon.icns"
cp "$ROOT_DIR/Runtime/freeocr_service.py" "$RESOURCES_DIR/Runtime/freeocr_service.py"
cp "$ROOT_DIR/Runtime/requirements-lock.txt" "$RESOURCES_DIR/Runtime/requirements-lock.txt"
mkdir -p "$RESOURCES_DIR/Legal"
ditto "$ROOT_DIR/LICENSE" "$RESOURCES_DIR/Legal/FreeOCR-LICENSE.md"
ditto "$ROOT_DIR/NOTICE" "$RESOURCES_DIR/Legal/NOTICE.txt"
ditto "$ROOT_DIR/THIRD_PARTY_NOTICES.md" "$RESOURCES_DIR/Legal/THIRD_PARTY_NOTICES.md"

if [[ "$INCLUDE_RUNTIME" == "1" ]]; then
  if [[ ! -x "$ROOT_DIR/Runtime/python/bin/python3" ]]; then
    echo "Portable Python is missing. Run ./script/prepare_portable_runtime.sh first." >&2
    exit 1
  fi
  if [[ ! -f "$DETECTION_MODEL_DIR/inference.onnx" ]]; then
    echo "PP-OCRv6 medium DET ONNX model is missing. Set FREEOCR_DETECTION_MODEL_PATH if needed." >&2
    exit 1
  fi
  if [[ ! -f "$RECOGNITION_MODEL_DIR/inference.onnx" ]]; then
    echo "PP-OCRv6 medium REC ONNX model is missing. Set FREEOCR_RECOGNITION_MODEL_PATH if needed." >&2
    exit 1
  fi
  ditto "$ROOT_DIR/Runtime/python" "$RESOURCES_DIR/Runtime/python"
  mkdir -p "$RESOURCES_DIR/Models"
  ditto "$DETECTION_MODEL_DIR" "$RESOURCES_DIR/Models/PP-OCRv6_medium_det_onnx"
  ditto "$RECOGNITION_MODEL_DIR" "$RESOURCES_DIR/Models/PP-OCRv6_medium_rec_onnx"
  APACHE_LICENSE="$(find "$ROOT_DIR/Runtime/python/lib" -path '*/paddleocr-*.dist-info/LICENSE' -type f -print -quit)"
  if [[ -n "$APACHE_LICENSE" ]]; then
    ditto "$APACHE_LICENSE" "$RESOURCES_DIR/Legal/Apache-2.0.txt"
  fi
fi

codesign --force --deep --sign - "$APP_BUNDLE"
