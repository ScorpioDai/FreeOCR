<p align="center">
  <img src="assets/freeocr-icon.png" width="168" alt="Значок FreeOCR">
</p>

<h1 align="center">FreeOCR для macOS</h1>

<p align="center">Быстрый, приватный и полностью локальный OCR для Apple Silicon.</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.fr.md">Français</a> ·
  <strong>Русский</strong> ·
  <a href="README.es.md">Español</a>
</p>

> Текущая версия: **1.1.5** · Требуется **macOS 26.0 или новее** и
> **Mac с Apple Silicon**. Интерфейс приложения доступен только на английском
> и упрощённом китайском языках.

FreeOCR — нативное приложение macOS на SwiftUI со встроенными ONNX-моделями
PP-OCRv6 medium для поиска и распознавания текста. После установки оно работает
офлайн: без учётной записи, загрузки моделей и отправки документов.

![Связанная подсветка PDF и результата OCR](screenshots/pdf-linked-highlight.png)

## Возможности

- OCR для PDF, PNG, JPEG, HEIC/HEIF, TIFF, BMP, GIF и WebP.
- Перетаскивание из Finder или прямо с веб-страницы.
- Двусторонняя подсветка областей исходника и распознанного текста.
- Многостраничный просмотр, масштаб, реальный прогресс и постоянная история.
- Просмотр, Markdown и структурированный JSON с копированием и сохранением.
- Единая модель распознавания 50 языков; выбирать язык не требуется.
- Локальный REST API, опциональный доступ из LAN и Bearer Token.
- Красная кнопка закрывает только окно; приложение и API продолжают работать.
  Значок Dock открывает окно снова, а выход выполняется через Dock или меню.

## Требования и установка

- macOS 26.0 или новее.
- Apple Silicon M1/M2/M3/M4 или новее; Intel Mac не поддерживается.
- Около 900МБ на диске и минимум 8ГБ RAM (рекомендуется 16ГБ).

Скачайте `FreeOCR-1.1.5-arm64.dmg` из GitHub Releases, откройте образ и
перетащите приложение в Applications. Текущая сборка подписана ad-hoc и не
нотарифицирована Apple. При первом запуске может потребоваться
Control-клик → **Открыть**.

Основную часть размера занимает полноценная офлайн-среда: около 133МБ моделей
и 685МБ Python/OCR со средой PaddleOCR, PaddleX, ONNX Runtime, OpenCV, PDFium,
FastAPI и зависимостями.

## Данные, API и лицензия

История пользователя хранится в `~/Documents/FreeOCR`. Документы обрабатываются
локально; аналитики и сервиса загрузки нет. API по умолчанию доступен по адресу
`http://127.0.0.1:8766`. Для доступа из LAN задайте надёжный Bearer Token и
используйте доверенную сеть.

Исходный дистрибутив не содержит модели и Python-среду:

- [PP-OCRv6 medium DET ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
- [PP-OCRv6 medium REC ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

На обеих страницах указана Apache License 2.0. См.
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

Оригинальный код FreeOCR предоставляется по
[PolyForm Noncommercial License 1.0.0](../LICENSE); коммерческое использование
запрещено. Из-за этого ограничения лицензия является source-available, а не
одобренной OSI лицензией open source.

Версия 1.1.5 протестирована на macOS 26.5.2, M1 Pro 8 ядер, 16ГБ RAM,
Swift 6.3.3 и arm64 Python 3.10.16.
