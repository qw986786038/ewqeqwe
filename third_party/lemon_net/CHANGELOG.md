## 0.2.0

- Added single-flight token refresh and one-time 401 request replay.
- Added safe idempotent request retries with exponential backoff.
- Added pluggable business response parsing.
- Added resumable downloads, chunked upload helpers and SHA-256 verification.
- Added optional memory caching, GET deduplication and concurrency limits.
- Removed unused native plugin template directories.

## 0.1.1

- Added `downloadToDirectory` with automatic filename resolution, fallback,
  sanitization and extension inference.
- Added `LemonDownloadFileName` and `LemonDownloadResult`.

## 0.1.0

- Added Dio-based GET, POST, PUT, PATCH, DELETE, request, upload and download support.
- Added optional singleton access while retaining independent clients.
- Added composable Session, Bearer/JWT and custom Token authentication.
- Added per-request authentication selection and credential scope support.
- Added response-header Token updates and redacted request logging.
- Configured all received HTTP status codes to return as normal responses by default.
