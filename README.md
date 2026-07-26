<p align="center">
  <img src="docs/assets/freeocr-icon.png" width="168" alt="FreeOCR icon">
</p>

<h1 align="center">FreeOCR for macOS</h1>

<p align="center">
  Fast, private, fully local OCR for images and PDFs on Apple Silicon.
</p>

<p align="center">
  <a href="README.md">English</a> ·
  <a href="docs/README.zh-CN.md">简体中文</a> ·
  <a href="docs/README.ja.md">日本語</a> ·
  <a href="docs/README.ko.md">한국어</a> ·
  <a href="docs/README.de.md">Deutsch</a> ·
  <a href="docs/README.fr.md">Français</a> ·
  <a href="docs/README.ru.md">Русский</a> ·
  <a href="docs/README.es.md">Español</a>
</p>

> Current release: **1.1.5** · Requires **macOS 26.0 or later** and an
> **Apple Silicon Mac**. The app interface is available in English and
> Simplified Chinese.

FreeOCR is a native SwiftUI desktop app powered by the bundled
PP-OCRv6 medium detection and recognition models. It works offline after
installation: no account, model download, or document upload is required.

![FreeOCR showing linked highlights between a PDF and its OCR result](docs/screenshots/pdf-linked-highlight.png)

## Highlights

- OCR for PDF, PNG, JPEG, HEIC/HEIF, TIFF, BMP, GIF, and WebP files.
- Drag files from Finder or images directly from a web page.
- Linked, bidirectional highlighting between source regions and recognized text.
- Multi-page previews with zoom controls and dated, persistent history.
- Preview, Markdown, and structured JSON output.
- Copy the current output or save it with a native macOS save panel.
- Unified 50-language recognition model; no language selector is required.
- English and Simplified Chinese interface, switchable immediately in Settings.
- Local REST API with real job progress, optional LAN access, and optional
  Bearer-token authentication.
- Closing the main window keeps FreeOCR and its API running. Click the Dock icon
  to reopen the window, or choose Quit from the Dock or app menu to stop it.

## Screenshots

| Multilingual image OCR | Markdown output |
| --- | --- |
| ![Chinese and English road-sign OCR](docs/screenshots/multilingual-image-ocr.png) | ![Markdown result for a PDF](docs/screenshots/markdown-result.png) |

| Local API settings | English welcome screen |
| --- | --- |
| ![Local API settings](docs/screenshots/local-api-settings.png) | ![English welcome screen](docs/screenshots/english-welcome.png) |

## Requirements

- macOS 26.0 or later.
- Apple Silicon: M1, M2, M3, M4, or newer. Intel Macs are not supported.
- About 900 MB of disk space for the current app bundle.
- 8 GB RAM minimum; 16 GB or more is recommended for large, multi-page PDFs.

The application is large because it is self-contained. In the current build,
the two ONNX model repositories occupy about 133 MB, while the portable Python
and OCR runtime occupies about 742 MB. That runtime includes PaddleOCR,
PaddleX, ONNX Runtime, OpenCV, PDFium, FastAPI, and their transitive
dependencies.

## Installation

1. Download `FreeOCR-1.1.5-arm64.dmg` from the GitHub Releases page.
2. Open the disk image and drag `FreeOCR.app` to `Applications`.
3. Launch FreeOCR and wait for the status indicator to turn green.
4. Import or drag in an image or PDF.

The current community build is ad-hoc signed and not Apple-notarized because a
Developer ID certificate is not available for this release. On first launch,
macOS may require you to Control-click the app, choose **Open**, and confirm.
Only download release files from this repository.

## Using FreeOCR

Newly imported files appear at the top of the sidebar. Recognition can start
automatically after import, or you can disable that option in Settings and use
the **Recognize** button manually. Attempting to recognize an already completed
document asks for confirmation.

The output tabs behave consistently:

- **Preview** and **Markdown**: Copy and Save use Markdown.
- **JSON**: Copy and Save use the displayed JSON.

Recognition history is stored per user at:

```text
~/Documents/FreeOCR
```

Each saved history item contains the original file, page previews, Markdown,
JSON, and metadata. Temporary API work files are stored under
`~/Library/Application Support/FreeOCR/Cache` and old entries are pruned
automatically.

## Local API

The API listens on the current Mac only by default:

```text
http://127.0.0.1:8766
```

The port, LAN access, and optional Bearer token are configurable in Settings.
Do not enable LAN access on an untrusted network without setting a strong token.

```bash
curl http://127.0.0.1:8766/health

curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/to/document.pdf' \
  -F 'response_format=markdown'
```

Asynchronous jobs and progress reporting are also supported. See
[`API_USAGE.md`](API_USAGE.md) for the complete API guide.

## Building from source

The Git repository and source ZIP intentionally exclude model weights, the
portable Python runtime, and build products.

Prerequisites:

- macOS 26 with Xcode Command Line Tools and Swift 6.2 or later.
- An arm64 Python 3.10 bootstrap environment.
- Complete local copies of both official model repositories:
  - [PP-OCRv6 medium DET ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
  - [PP-OCRv6 medium REC ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

```bash
python3 -m venv Runtime/.venv
Runtime/.venv/bin/python -m pip install -r Runtime/requirements-lock.txt

export FREEOCR_DETECTION_MODEL_PATH="/path/to/PP-OCRv6_medium_det_onnx"
export FREEOCR_RECOGNITION_MODEL_PATH="/path/to/PP-OCRv6_medium_rec_onnx"

swift build
Runtime/.venv/bin/python -m unittest discover -s Runtime -p 'test_*.py'
./script/package_release.sh
```

The packaging script creates the self-contained app, app ZIP, source ZIP, and
compressed DMG under `release/`.

## Tested environment

Version 1.1.5 was built and tested on:

- macOS 26.5.2 (Build 25F84).
- MacBook Pro with Apple M1 Pro, 8-core CPU, and 16 GB RAM.
- Apple Swift 6.3.3.
- arm64 Python 3.10.16.
- PaddleOCR 3.7.0, PaddleX 3.7.2, and ONNX Runtime 1.23.2.

Other Apple Silicon configurations meeting the requirements should work, but
have not all been individually tested.

## Models and acknowledgements

FreeOCR bundles two official PaddlePaddle model repositories:

- [`PaddlePaddle/PP-OCRv6_medium_det_onnx`](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
- [`PaddlePaddle/PP-OCRv6_medium_rec_onnx`](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

Both model pages identify their license as Apache License 2.0. The model
weights and all bundled third-party components remain governed by their own
licenses; they are not relicensed under FreeOCR's project license. See
[`THIRD_PARTY_NOTICES.md`](THIRD_PARTY_NOTICES.md).

FreeOCR is an independent project and is not affiliated with or endorsed by
PaddlePaddle, Apple, Hugging Face, or the maintainers of its dependencies.

## License

FreeOCR's original source code is source-available under the
[PolyForm Noncommercial License 1.0.0](LICENSE). Noncommercial use,
study, research, modification, and distribution are permitted under its terms;
commercial use is not permitted.

Because it restricts commercial use, PolyForm Noncommercial is not an
OSI-approved open-source license. If you require an OSI open-source project,
this licensing choice will not meet that definition.

## Security and privacy

Documents are processed locally and FreeOCR does not include analytics or an
upload service. API exposure is controlled by you. Please report security
issues according to [`SECURITY.md`](SECURITY.md).
