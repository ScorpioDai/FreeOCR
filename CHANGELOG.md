# Changelog

All notable user-facing changes are documented in this file.

## 1.1.5 — 2026-07-26

- Focused the release on the faster PP-OCRv6 medium traditional OCR pipeline.
- Bundled PP-OCRv6 medium DET and REC ONNX models for offline, ready-to-use OCR.
- Retained image, PDF, HEIC/HEIF, drag-and-drop, history, export, and local API
  support.
- Added English and Simplified Chinese interface switching.
- Added persistent, date-grouped recognition history under `~/Documents/FreeOCR`.
- Added real multi-page job progress and estimated remaining time.
- Improved bidirectional source/result highlighting and large JSON rendering.
- Changed the main window's red close button to keep the app and API running;
  clicking the Dock icon reopens the window.
- Migrated PDF rendering from PyMuPDF to pypdfium2/PDFium for distribution under
  permissive third-party terms.
- Added multilingual repository documentation and DMG packaging.
