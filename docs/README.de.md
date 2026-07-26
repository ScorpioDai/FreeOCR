<p align="center">
  <img src="assets/freeocr-icon.png" width="168" alt="FreeOCR-Symbol">
</p>

<h1 align="center">FreeOCR für macOS</h1>

<p align="center">Schnelle, private und vollständig lokale OCR für Apple Silicon.</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <strong>Deutsch</strong> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.es.md">Español</a>
</p>

<p align="center">
  <a href="https://github.com/ScorpioDai/FreeOCR/releases/tag/v1.1.5"><img src="https://img.shields.io/badge/version-1.1.5-0A84FF?style=flat-square" alt="Version 1.1.5"></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-1C1C1E?style=flat-square" alt="macOS 26 or later">
  <img src="https://img.shields.io/badge/Apple%20Silicon-required-34C759?style=flat-square" alt="Apple Silicon required">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-PolyForm%20Noncommercial-FF3B30?style=flat-square" alt="PolyForm Noncommercial License"></a>
</p>

> Aktuelle Version: **1.1.5** · Erfordert **macOS 26.0 oder neuer** und
> einen **Mac mit Apple Silicon**. Die App-Oberfläche ist nur auf Englisch
> und vereinfachtem Chinesisch verfügbar.

FreeOCR ist eine native SwiftUI-App mit integrierten PP-OCRv6-medium-Modellen
für Texterkennung und -lokalisierung im ONNX-Format. Sie arbeitet nach der
Installation offline – ohne Konto, Modelldownload oder Dokument-Upload.

![Verknüpfte Hervorhebung zwischen PDF und OCR-Ergebnis](screenshots/pdf-linked-highlight.png)

## Funktionen

- OCR für PDF, PNG, JPEG, HEIC/HEIF, TIFF, BMP, GIF und WebP.
- Drag-and-drop aus dem Finder oder direkt von Webseiten.
- Bidirektionale Hervorhebung zwischen Quelldokument und erkanntem Text.
- Mehrseitige Vorschau, Zoom, echter Fortschritt und dauerhafter Verlauf.
- Vorschau-, Markdown- und strukturierte JSON-Ausgabe mit Kopieren/Speichern.
- Einheitliches Modell für 50 Sprachen; keine Sprachauswahl erforderlich.
- Lokale REST-API, optionaler LAN-Zugriff und Bearer-Token.
- Die rote Schaltfläche schließt nur das Fenster; App und API laufen weiter.
  Das Dock-Symbol öffnet das Fenster erneut. Beenden erfolgt über Dock/App-Menü.

## Voraussetzungen und Installation

- macOS 26.0 oder neuer.
- Apple Silicon M1/M2/M3/M4 oder neuer; Intel-Macs werden nicht unterstützt.
- Etwa 900MB Speicherplatz und mindestens 8GB RAM (16GB empfohlen).

Laden Sie `FreeOCR-1.1.5-arm64.dmg` von GitHub Releases, öffnen Sie das
Image und ziehen Sie FreeOCR nach „Programme“. Der aktuelle Build ist ad-hoc
signiert und nicht von Apple notarisiert. Beim ersten Start kann
Control-Klick → **Öffnen** erforderlich sein.

Die Größe entsteht vor allem durch die vollständige Offline-Laufzeit:
ca. 133MB Modelle und ca. 685MB Python/OCR-Umgebung mit PaddleOCR, PaddleX,
ONNX Runtime, OpenCV, PDFium, FastAPI und Abhängigkeiten.

## Daten, API und Lizenz

Der Verlauf liegt benutzerspezifisch in `~/Documents/FreeOCR`. Dokumente
werden lokal verarbeitet; die App enthält keine Analyse- oder Upload-Funktion.
Die API verwendet standardmäßig `http://127.0.0.1:8766`. Aktivieren Sie
LAN-Zugriff nur mit einem starken Bearer-Token in einem vertrauenswürdigen Netz.

Die Quellcode-Distribution enthält weder Modelle noch Python-Laufzeit:

- [PP-OCRv6 medium DET ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
- [PP-OCRv6 medium REC ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

Beide Modellseiten nennen Apache License 2.0. Siehe
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

Der ursprüngliche FreeOCR-Code steht unter der
[PolyForm Noncommercial License 1.0.0](../LICENSE); kommerzielle Nutzung ist
nicht erlaubt. Wegen dieser Einschränkung handelt es sich um eine
source-available, nicht um eine OSI-anerkannte Open-Source-Lizenz.

Getestet wurde 1.1.5 unter macOS 26.5.2 auf einem M1 Pro mit 8 CPU-Kernen
und 16GB RAM, Swift 6.3.3 und arm64 Python 3.10.16.
