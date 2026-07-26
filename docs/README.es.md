<p align="center">
  <img src="assets/freeocr-icon.png" width="168" alt="Icono de FreeOCR">
</p>

<h1 align="center">FreeOCR para macOS</h1>

<p align="center">OCR rápido, privado y totalmente local para Apple Silicon.</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <a href="README.fr.md">Français</a> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.es.md">Español</a>
</p>

> Versión actual: **1.1.5** · Requiere **macOS 26.0 o posterior** y un
> **Mac con Apple Silicon**. La interfaz de la aplicación solo está disponible
> en inglés y chino simplificado.

FreeOCR es una aplicación nativa de macOS creada con SwiftUI. Incluye los
modelos ONNX PP-OCRv6 medium de detección y reconocimiento, por lo que funciona
sin conexión después de instalarla: sin cuenta, descarga de modelos ni envío
de documentos.

![Resaltado enlazado entre un PDF y su resultado OCR](screenshots/pdf-linked-highlight.png)

## Funciones

- OCR para PDF, PNG, JPEG, HEIC/HEIF, TIFF, BMP, GIF y WebP.
- Arrastrar y soltar desde Finder o directamente desde una página web.
- Resaltado bidireccional entre las regiones originales y el texto reconocido.
- Vista multipágina, zoom, progreso real e historial persistente.
- Salida de vista previa, Markdown y JSON estructurado, con copia y guardado.
- Modelo unificado para 50 idiomas; no hace falta seleccionar idioma.
- API REST local, acceso LAN opcional y Bearer Token opcional.
- El botón rojo cierra solo la ventana; la app y la API siguen activas.
  El icono del Dock reabre la ventana y Salir desde Dock/menú termina la app.

## Requisitos e instalación

- macOS 26.0 o posterior.
- Apple Silicon M1/M2/M3/M4 o más reciente; no admite Mac Intel.
- Unos 900MB de disco y 8GB de RAM como mínimo (16GB recomendados).

Descarga `FreeOCR-1.1.5-arm64.dmg` desde GitHub Releases, ábrelo y arrastra
la app a Aplicaciones. La compilación actual usa firma ad-hoc y no está
notarizada por Apple. En el primer inicio puede ser necesario hacer
Control-clic → **Abrir**.

El tamaño se debe principalmente al entorno completo sin conexión:
aproximadamente 133MB de modelos y 742MB de Python/OCR con PaddleOCR, PaddleX,
ONNX Runtime, OpenCV, PDFium, FastAPI y sus dependencias.

## Datos, API y licencia

El historial de cada usuario se guarda en `~/Documents/FreeOCR`. Los documentos
se procesan localmente y la app no incluye analítica ni servicio de subida.
La API usa `http://127.0.0.1:8766` por defecto. Al activar acceso LAN, utiliza
un Bearer Token fuerte y una red de confianza.

La distribución de código fuente no incluye modelos ni el entorno Python:

- [PP-OCRv6 medium DET ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
- [PP-OCRv6 medium REC ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

Ambas páginas indican Apache License 2.0. Consulta
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

El código original de FreeOCR se ofrece bajo
[PolyForm Noncommercial License 1.0.0](../LICENSE); se prohíbe el uso
comercial. Por esa restricción, es una licencia source-available y no una
licencia open source aprobada por OSI.

La versión 1.1.5 se probó en macOS 26.5.2, M1 Pro de 8 núcleos, 16GB de RAM,
Swift 6.3.3 y Python 3.10.16 arm64.
