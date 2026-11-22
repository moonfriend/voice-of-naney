import { requireUploader } from '../auth';
import { HttpError, json, readJson } from '../http';
import type { Deps, UploadRecord } from '../ports';
import { parseUploadRequest, planUpload } from './policy';

const DAY_MS = 24 * 60 * 60 * 1000;
const UUID_PATTERN = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export async function createUpload(request: Request, deps: Deps): Promise<Response> {
  const userId = await requireUploader(request, deps);
  const uploadRequest = parseUploadRequest(await readJson(request));

  const since = new Date(deps.now().getTime() - DAY_MS);
  if ((await deps.uploads.countCreatedSince(userId, since)) >= deps.maxUploadsPerDay) {
    throw new HttpError(429, 'daily_limit_reached');
  }

  const uploadId = deps.newId();
  const plan = planUpload(uploadRequest, deps.newId());
  const base = {
    id: uploadId,
    objectKey: plan.objectKey,
    owner: userId,
    purpose: uploadRequest.purpose,
    mime: uploadRequest.mime,
    declaredSize: uploadRequest.size,
  };

  if (plan.method === 'single') {
    await deps.uploads.insert({ ...base, multipartUploadId: null });
    return json(
      {
        uploadId,
        objectKey: plan.objectKey,
        method: 'single',
        url: await deps.signer.signPut(plan.objectKey, uploadRequest.mime),
        headers: { 'content-type': uploadRequest.mime },
      },
      { status: 201 },
    );
  }

  const multipart = await deps.bucket.createMultipartUpload(plan.objectKey, {
    httpMetadata: { contentType: uploadRequest.mime },
  });
  await deps.uploads.insert({ ...base, multipartUploadId: multipart.uploadId });
  const parts = await Promise.all(
    Array.from({ length: plan.partCount }, async (_, index) => ({
      partNumber: index + 1,
      url: await deps.signer.signPart(plan.objectKey, multipart.uploadId, index + 1),
    })),
  );
  return json(
    { uploadId, objectKey: plan.objectKey, method: 'multipart', partSize: plan.partSize, parts },
    { status: 201 },
  );
}

export async function completeUpload(
  request: Request,
  uploadId: string,
  deps: Deps,
): Promise<Response> {
  const userId = await requireUploader(request, deps);
  const upload = UUID_PATTERN.test(uploadId) ? await deps.uploads.find(uploadId) : null;
  // Someone else's upload is reported as missing, so ids cannot be probed.
  if (!upload || upload.owner !== userId) {
    throw new HttpError(404, 'not_found');
  }
  if (upload.verifiedAt !== null) {
    return verifiedResponse(upload);
  }

  if (upload.multipartUploadId !== null) {
    const parts = parseParts(await readJson(request));
    try {
      await deps.bucket
        .resumeMultipartUpload(upload.objectKey, upload.multipartUploadId)
        .complete(parts);
    } catch {
      throw new HttpError(422, 'multipart_incomplete');
    }
  }

  const stored = await deps.bucket.head(upload.objectKey);
  if (!stored) {
    throw new HttpError(422, 'object_missing');
  }
  if (stored.size !== upload.declaredSize || stored.httpMetadata?.contentType !== upload.mime) {
    await deps.bucket.delete(upload.objectKey);
    await deps.uploads.remove(upload.id);
    throw new HttpError(422, 'object_mismatch');
  }

  await deps.uploads.markVerified(upload.id);
  return verifiedResponse(upload);
}

function verifiedResponse(upload: UploadRecord): Response {
  return json({ uploadId: upload.id, objectKey: upload.objectKey, verified: true });
}

function parseParts(body: unknown): R2UploadedPart[] {
  const parts = (body as { parts?: unknown } | null)?.parts;
  const valid =
    Array.isArray(parts) &&
    parts.length > 0 &&
    parts.every(
      (part: unknown) =>
        typeof part === 'object' &&
        part !== null &&
        Number.isInteger((part as R2UploadedPart).partNumber) &&
        typeof (part as R2UploadedPart).etag === 'string',
    );
  if (!valid) {
    throw new HttpError(400, 'invalid_parts');
  }
  return (parts as R2UploadedPart[]).map(({ partNumber, etag }) => ({ partNumber, etag }));
}
