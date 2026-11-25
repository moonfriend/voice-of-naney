# 0002 — Uploads go straight to R2 with presigned URLs

**Status:** accepted

## Context
Uploaders send audio (up to 50 MB) and video (up to 500 MB), often from phones on weak
connections. Sending files through the Worker would be the simplest client code.

## Options
- **Proxy through the Worker:** one request, but Workers on the Free and Pro plans reject request
  bodies over 100 MB, every byte costs Worker time, and a dropped connection restarts the file.
- **Presigned URLs, direct to R2:** about three short API calls instead of one; the browser uploads
  straight to storage, in parts for large files.

## Decision
Presigned URLs. The Worker checks the user's token and role, the declared type and size, and a
daily quota, then signs a short-lived URL bound to that content type (multipart above 100 MB, each
part retried on its own). On completion the Worker reads the stored object and deletes it if its
size or type differs from the declaration. Only then can a recording point to it.

## Consequences
- 500 MB videos work on the free plan, and a flaky connection costs one part, not the whole file.
- Object keys are random UUIDs chosen by the Worker; clients never pick paths.
- Abandoned uploads leave orphan objects; cleanup is a known follow-up.
