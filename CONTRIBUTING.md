# Contributing to FreeOCR

Thank you for helping improve FreeOCR.

## Before opening an issue

- Check that you are using the latest release on an Apple Silicon Mac with
  macOS 26 or later.
- Search existing issues.
- Do not attach private or sensitive documents. Create the smallest synthetic
  sample that reproduces the problem.

For a bug report, include:

- FreeOCR and macOS versions;
- Mac chip and memory;
- exact reproduction steps;
- expected and actual behavior;
- relevant local logs with tokens, usernames, and document content removed.

## Development

Read the build section in [`README.md`](README.md). Run both checks before
submitting a change:

```bash
swift build
Runtime/.venv/bin/python -m unittest discover -s Runtime -p 'test_*.py'
```

Keep AppKit bridges narrow, preserve local-only document processing, and add a
targeted regression test for backend changes.

## License

By submitting a contribution, you agree that it may be distributed under the
project's [PolyForm Noncommercial License 1.0.0](LICENSE). Third-party code,
models, and generated assets must have compatible terms and clear attribution.
