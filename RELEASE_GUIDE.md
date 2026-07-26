# FreeOCR 1.1.5 使用与维护说明

FreeOCR 1.1.5 是面向 Apple Silicon 和 macOS 26 的完全本地 OCR App，内置
PP-OCRv6 medium DET 与 REC ONNX 模型，可以离线即开即用。

## 发行内容

| 文件 | 用途 | 包含模型 |
| --- | --- | --- |
| `FreeOCR-1.1.5-arm64.dmg` | 拖入“应用程序”的压缩安装镜像 | 是 |
| `FreeOCR-1.1.5-arm64.zip` | App 的可搬运压缩包 | 是 |
| `FreeOCR-1.1.5-source.zip` | 复盘、修复和重新构建源码 | 否 |
| `FreeOCR-1.1.2-source.zip` | 旧版双引擎源码快照 | 否 |

App 内包含：

- arm64 SwiftUI 程序；
- PP-OCRv6 medium DET 与 REC 完整 ONNX 仓库文件；
- Python、PaddleOCR、PaddleX、ONNX Runtime、FastAPI、PDFium 等运行依赖；
- 本机与局域网 OCR API。

## 本地保留建议

项目目录保留当前 Git 源码，以及上表中的 DMG、arm64 ZIP 和两个源码 ZIP
即可。`FreeOCR-1.1.5-arm64.zip` 建议保留：它不仅是 DMG 之外的备用安装方式，
还完整保存了已经配置好的运行环境与模型，可用于以后核对或恢复发行包。
`.build`、`work`、`Runtime/.venv`、`Runtime/python` 和单独展开的
`release/FreeOCR.app` 都是可重新生成的中间产物，无需长期保存。

## 数据位置

OCR 历史记录保存在：

```text
~/Documents/FreeOCR
```

每条记录包含原文件、页面预览、Markdown、JSON 和记录清单。设置界面提供
“在 Finder 中显示”。删除侧边栏历史记录时，对应持久化目录也会删除。

## 源码重建

源码归档不包含模型、Python 虚拟环境或构建产物。重新构建发行包前，下载：

- <https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_det_onnx>
- <https://huggingface.co/PaddlePaddle/PP-OCRv6_medium_rec_onnx>

每个仓库都要完整下载，并至少确认存在 `inference.onnx`、
`inference.json` 和 `inference.yml`。

```bash
export FREEOCR_DETECTION_MODEL_PATH="/模型路径/PP-OCRv6_medium_det_onnx"
export FREEOCR_RECOGNITION_MODEL_PATH="/模型路径/PP-OCRv6_medium_rec_onnx"
./script/package_release.sh
```

运行环境锁定文件位于 `Runtime/requirements-lock.txt`。发行脚本会创建隔离的
传统 OCR 依赖环境，再制作可搬运 Python 运行时，避免夹带开发环境中的无关包。

## API

默认 OCR 地址：

```text
http://127.0.0.1:8766/v1/ocr
```

支持同步 OCR、异步任务进度、Markdown/文本/JSON 输出、Bearer Token 和可选
局域网访问。完整示例见 `API_USAGE.md`。

## 当前发行状态

本地发行包使用 ad-hoc 签名，适合测试和 GitHub 下载，但未经过 Apple 公证。
首次运行时用户可能需要 Control 点击 App，选择“打开”并确认。取得 Apple
Developer ID 证书后，应使用 Developer ID 筿名、启用 Hardened Runtime、完成
notarization，并在干净 Mac 账户上验证 Gatekeeper、首次启动、OCR 与 API。
