<p align="center">
  <img src="assets/freeocr-icon.png" width="168" alt="FreeOCR アイコン">
</p>

<h1 align="center">FreeOCR for macOS</h1>

<p align="center">Apple Silicon 向けの高速・プライベート・完全ローカル OCR。</p>

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

> 現行版: **1.1.5** · **macOS 26.0 以降**、**Apple Silicon Mac** が必要です。
> アプリの UI は英語と簡体字中国語のみです。

FreeOCR は SwiftUI 製のネイティブ macOS アプリです。PP-OCRv6 medium の
検出・認識 ONNX モデルを内蔵し、アカウント、追加ダウンロード、クラウドへの
文書送信なしでオフライン動作します。

![PDF と OCR 結果の連動ハイライト](screenshots/pdf-linked-highlight.png)

## 主な機能

- PDF、PNG、JPEG、HEIC/HEIF、TIFF、BMP、GIF、WebP の OCR。
- Finder や Web ページからのドラッグ＆ドロップ。
- 原文領域と認識テキストの双方向ハイライト。
- 複数ページのプレビュー、ズーム、進捗表示、日付別の永続履歴。
- Preview、Markdown、構造化 JSON のコピーと保存。
- 50 言語統合認識モデル。言語選択は不要です。
- ローカル REST API、任意の LAN 公開、Bearer Token。
- 赤い閉じるボタンではウインドウだけを閉じ、アプリと API は継続します。
  Dock アイコンで再表示し、終了は Dock またはアプリメニューから行います。

## 動作要件とインストール

- macOS 26.0 以降。
- M1/M2/M3/M4 以降の Apple Silicon。Intel Mac は非対応。
- 約 900MB の空き容量、8GB RAM 以上（16GB 推奨）。

GitHub Releases から `FreeOCR-1.1.5-arm64.dmg` を取得し、アプリを
Applications にドラッグしてください。現行ビルドは ad-hoc 署名で Apple の
notarization 未実施です。初回は Control キーを押しながらアプリをクリックし、
「開く」の確認が必要な場合があります。

アプリが大きい主因は完全なオフライン環境です。モデルは約 133MB、
Python/OCR ランタイムは約 742MB で、PaddleOCR、PaddleX、ONNX Runtime、
OpenCV、PDFium、FastAPI と依存関係を含みます。

## データと API

履歴はユーザーごとの `~/Documents/FreeOCR` に保存されます。文書はローカル
処理され、FreeOCR に分析・アップロード機能はありません。API の初期値は
`http://127.0.0.1:8766` です。LAN 公開時は強力な Bearer Token を設定してください。

## ビルド、モデル、ライセンス

ソース配布物にはモデルと Python ランタイムを含みません。完全な公式リポジトリを
ダウンロードしてください。

- [PP-OCRv6 medium DET ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx)
- [PP-OCRv6 medium REC ONNX](https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx)

両モデルページのライセンス表記は Apache License 2.0 です。第三者情報は
[`THIRD_PARTY_NOTICES.md`](../THIRD_PARTY_NOTICES.md) を参照してください。

FreeOCR のオリジナルコードは
[PolyForm Noncommercial License 1.0.0](../LICENSE) で提供され、商用利用は禁止です。
商用制限があるため、これは OSI 認定オープンソースではなく source-available
ライセンスです。

1.1.5 は macOS 26.5.2、M1 Pro 8 コア、16GB RAM、Swift 6.3.3、
arm64 Python 3.10.16 でテストされています。
