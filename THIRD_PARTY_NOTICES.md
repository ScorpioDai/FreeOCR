# Third-Party Notices

FreeOCR 1.1.5 includes third-party models, libraries, and runtimes. These
components remain under their respective licenses and are not relicensed under
the PolyForm Noncommercial License that covers FreeOCR's original code.

This document is an attribution and navigation aid, not legal advice. The
license files distributed in the component packages are authoritative.

## Bundled OCR models

| Component | Source | License identified by publisher |
| --- | --- | --- |
| PP-OCRv6 medium DET ONNX | <https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx> | Apache License 2.0 |
| PP-OCRv6 medium REC ONNX | <https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx> | Apache License 2.0 |

Copyright and attribution for these models belong to their respective authors
and contributors.

## Primary bundled runtime components

| Component | Project | License |
| --- | --- | --- |
| Python | <https://www.python.org/> | Python Software Foundation License |
| PaddleOCR | <https://github.com/PaddlePaddle/PaddleOCR> | Apache License 2.0 |
| PaddleX | <https://github.com/PaddlePaddle/PaddleX> | Apache License 2.0 |
| ONNX Runtime | <https://github.com/microsoft/onnxruntime> | MIT |
| OpenCV / opencv-python | <https://github.com/opencv/opencv-python> | Apache License 2.0, plus component licenses |
| pypdfium2 | <https://github.com/pypdfium2-team/pypdfium2> | Apache-2.0 or BSD-3-Clause |
| PDFium and bundled PDFium dependencies | <https://pdfium.googlesource.com/pdfium/> | BSD-style and bundled third-party licenses |
| FastAPI | <https://github.com/fastapi/fastapi> | MIT |
| Uvicorn | <https://github.com/Kludex/uvicorn> | BSD-3-Clause |
| python-multipart | <https://github.com/Kludex/python-multipart> | Apache License 2.0 |
| Pillow | <https://github.com/python-pillow/Pillow> | HPND |

The complete locked list of direct Python requirements is maintained in
[`Runtime/requirements-lock.txt`](Runtime/requirements-lock.txt). Those
packages bring additional transitive dependencies. Their package metadata and
license files are retained inside the portable Python distribution embedded in
the release App.

In particular, pypdfium2 wheel builds include PDFium's license and the
build-specific licenses for PDFium's bundled dependencies. Distributors of
modified packages or independently rebuilt binaries are responsible for
preserving all applicable notices.

## Apple frameworks

FreeOCR uses system frameworks supplied with macOS, including SwiftUI, AppKit,
PDF-related system services, Uniform Type Identifiers, and OSLog. Their use is
governed by Apple's applicable software license agreements.

## Replacement of PyMuPDF

FreeOCR does not bundle PyMuPDF. Before public release preparation, the PDF
renderer was migrated to pypdfium2/PDFium to avoid distributing the
AGPL-or-commercial PyMuPDF package under an incompatible project licensing
assumption.
