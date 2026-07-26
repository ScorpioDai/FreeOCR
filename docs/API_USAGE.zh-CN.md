# FreeOCR 1.1.5 本地 API

[English](../API_USAGE.md) · [简体中文](API_USAGE.zh-CN.md)

默认地址为 `http://127.0.0.1:8766`。可在设置中修改端口、开启局域网访问，
并配置可选 Bearer Token；修改后需要重新启动 API 服务。

## 状态与能力

```bash
curl http://127.0.0.1:8766/health
curl http://127.0.0.1:8766/v1/models
curl http://127.0.0.1:8766/v1/languages
```

如果设置了 Token，请添加：

```bash
-H 'Authorization: Bearer YOUR_TOKEN'
```

`/health` 的 `status` 为 `starting`、`loading`、`ready` 或 `failed`。
只有 `ready` 后才能提交识别。

## 同步 OCR

JSON：

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/document.pdf' \
  -F 'max_pages=100'
```

Markdown：

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/document.pdf' \
  -F 'response_format=markdown'
```

纯文本：

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/image.heic' \
  -F 'response_format=text'
```

## 异步 OCR 与进度

创建任务：

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr/jobs \
  -F 'file=@/path/document.pdf' \
  -F 'max_pages=100'
```

查询任务：

```bash
curl http://127.0.0.1:8766/v1/ocr/jobs/JOB_ID
```

任务返回 `current`、`total`、`page`、`page_count`、`elapsed_seconds` 和
`estimated_remaining_seconds`。完成后 `status=completed`，结果位于 `result`。

## JSON 输出

JSON 包含：

- 全文 `markdown` 与 `text`；
- 每页尺寸、预览路径和文字；
- 每个文本块的页码、顺序、置信度和归一化多边形坐标。

坐标范围为 0–1，原点位于页面左上角。PP-OCRv6 使用统一多语言识别模型，
不需要传递语言参数。

## 安全

Bearer Token 留空时 API 不鉴权。不需要远程访问时应保持默认仅本机监听。
开启局域网访问时，请设置强 Token 并仅在可信网络使用。FreeOCR 不提供 TLS，
不应把端口直接暴露到公网。
