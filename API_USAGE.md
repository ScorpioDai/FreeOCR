# FreeOCR 1.1.5 Local API

[English](API_USAGE.md) · [简体中文](docs/API_USAGE.zh-CN.md)

The default base URL is `http://127.0.0.1:8766`. You can change the port,
enable LAN access, and set an optional Bearer token in Settings. Restart the
API service after changing any of those values.

## Status and capabilities

```bash
curl http://127.0.0.1:8766/health
curl http://127.0.0.1:8766/v1/models
curl http://127.0.0.1:8766/v1/languages
```

When a token is configured, add:

```bash
-H 'Authorization: Bearer YOUR_TOKEN'
```

The `/health` status is `starting`, `loading`, `ready`, or `failed`. Submit OCR
requests only after it becomes `ready`.

## Synchronous OCR

JSON:

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/document.pdf' \
  -F 'max_pages=100'
```

Markdown:

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/document.pdf' \
  -F 'response_format=markdown'
```

Plain text:

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr \
  -F 'file=@/path/image.heic' \
  -F 'response_format=text'
```

## Asynchronous OCR and progress

Create a job:

```bash
curl -X POST http://127.0.0.1:8766/v1/ocr/jobs \
  -F 'file=@/path/document.pdf' \
  -F 'max_pages=100'
```

Poll the job:

```bash
curl http://127.0.0.1:8766/v1/ocr/jobs/JOB_ID
```

The job payload includes `current`, `total`, `page`, `page_count`,
`elapsed_seconds`, and `estimated_remaining_seconds`. When
`status=completed`, the OCR response is available in `result`.

## JSON output

The JSON response contains:

- full-document `markdown` and `text`;
- page dimensions, preview path, and per-page text;
- page number, reading order, confidence, and normalized polygon coordinates
  for each text block.

Coordinates range from 0 to 1 with the origin at the top-left of the page.
PP-OCRv6 uses a unified multilingual recognition model, so no language
parameter is required.

## Security

The API is unauthenticated when the Bearer token setting is empty. Keep the
default localhost binding unless remote access is needed. If you enable LAN
access, configure a strong token and use a trusted network. FreeOCR does not
provide TLS and should not be exposed directly to the public internet.
