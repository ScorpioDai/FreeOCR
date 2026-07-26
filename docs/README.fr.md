<p align="center">
  <img src="assets/freeocr-icon.png" width="168" alt="Icône FreeOCR">
</p>

<h1 align="center">FreeOCR pour macOS</h1>

<p align="center">OCR rapide, privé et entièrement local pour Apple Silicon.</p>

<p align="center">
  <a href="../README.md">English</a> ·
  <a href="README.zh-CN.md">简体中文</a> ·
  <a href="README.ja.md">日本語</a> ·
  <a href="README.ko.md">한국어</a> ·
  <a href="README.de.md">Deutsch</a> ·
  <strong>Français</strong> ·
  <a href="README.ru.md">Русский</a> ·
  <a href="README.es.md">Español</a>
</p>

<p align="center">
  <a href="https://github.com/ScorpioDai/FreeOCR/releases/tag/v1.1.5"><img src="https://img.shields.io/badge/version-1.1.5-0A84FF?style=flat-square" alt="Version 1.1.5"></a>
  <img src="https://img.shields.io/badge/macOS-26%2B-1C1C1E?style=flat-square" alt="macOS 26 or later">
  <img src="https://img.shields.io/badge/Apple%20Silicon-required-34C759?style=flat-square" alt="Apple Silicon required">
  <a href="../LICENSE"><img src="https://img.shields.io/badge/license-PolyForm%20Noncommercial-FF3B30?style=flat-square" alt="PolyForm Noncommercial License"></a>
</p>

> Version actuelle : **1.1.5** · Nécessite **macOS 26.0 ou ultérieur** et
> un **Mac Apple Silicon**. L'interface de l'application est uniquement
> disponible en anglais et en chinois simplifié.

FreeOCR est une application macOS native en SwiftUI. Elle intègre les modèles
ONNX PP-OCRv6 medium de détection et de reconnaissance. Elle fonctionne hors
ligne après installation, sans compte, téléchargement de modèle ni envoi de
document.

![Surlignage lié entre un PDF et son résultat OCR](screenshots/pdf-linked-highlight.png)

## Fonctionnalités

- OCR de PDF, PNG, JPEG, HEIC/HEIF, TIFF, BMP, GIF et WebP.
- Glisser-déposer depuis le Finder ou directement depuis une page web.
- Surlignage bidirectionnel entre les zones source et le texte reconnu.
- Aperçu multipage, zoom, progression réelle et historique persistant.
- Sorties Aperçu, Markdown et JSON structuré, copiables et enregistrables.
- Modèle unifié pour 50 langues ; aucun choix de langue n'est nécessaire.
- API REST locale, accès LAN optionnel et jeton Bearer optionnel.
- Le bouton rouge ferme seulement la fenêtre : l'app et l'API continuent.
  L'icône du Dock rouvre la fenêtre ; quittez via le Dock ou le menu de l'app.

## Configuration et installation

- macOS 26.0 ou ultérieur.
- Apple Silicon M1/M2/M3/M4 ou plus récent ; Mac Intel non pris en charge.
- Environ 900Mo d'espace disque et 8Go de RAM minimum (16Go recommandés).

Téléchargez `FreeOCR-1.1.5-arm64.dmg` depuis GitHub Releases, ouvrez-le et
glissez l'app dans Applications. La version actuelle utilise une signature
ad-hoc et n'est pas notariée par Apple. Au premier lancement, un
Control-clic → **Ouvrir** peut être nécessaire.

La taille vient principalement de l'environnement hors ligne complet :
environ 133Mo de modèles et 685Mo d'environnement Python/OCR incluant
PaddleOCR, PaddleX, ONNX Runtime, OpenCV, PDFium, FastAPI et leurs dépendances.

## Données, API et licence

L'historique est stocké pour chaque utilisateur dans `~/Documents/FreeOCR`.
Les documents sont traités localement et l'app ne contient ni télémétrie ni
service d'envoi. L'API écoute par défaut sur `http://127.0.0.1:8766`.
En cas d'accès LAN, utilisez un jeton Bearer fort sur un réseau de confiance.

La distribution source n'inclut ni modèles ni environnement Python :

- [PP-OCRv6 medium DET ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
- [PP-OCRv6 medium REC ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

Les deux pages indiquent Apache License 2.0. Consultez
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md).

Le code original de FreeOCR est disponible sous
[PolyForm Noncommercial License 1.0.0](../LICENSE) ; l'utilisation commerciale
est interdite. Cette restriction en fait une licence source-available et non
une licence open source approuvée par l'OSI.

La version 1.1.5 a été testée sous macOS 26.5.2 sur M1 Pro 8 cœurs et 16Go
de RAM, avec Swift 6.3.3 et Python 3.10.16 arm64.
