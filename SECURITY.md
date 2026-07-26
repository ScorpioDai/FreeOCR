# Security Policy

## Supported version

Security fixes currently target the latest FreeOCR release, version 1.1.5.

## Reporting a vulnerability

Please do not publish exploit details in a public issue. Use GitHub's private
vulnerability reporting feature for this repository when available, or contact
the repository owner through the profile at <https://github.com/ScorpioDai/>.

Include the FreeOCR version, macOS version, Mac model, reproduction steps, and
the smallest non-sensitive sample needed to demonstrate the issue. Do not send
private documents or OCR history.

## Local API guidance

The API binds to `127.0.0.1` by default. If you enable LAN access:

- configure a strong Bearer token;
- use only a trusted network;
- do not expose the port directly to the public internet;
- quit FreeOCR when the service is not needed.

FreeOCR does not provide TLS termination. Use a trusted reverse proxy if your
environment requires encrypted network transport.
