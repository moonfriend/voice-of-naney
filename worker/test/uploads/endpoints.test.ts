import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';
import { handleRequest } from '../../src/router';
import { MULTIPART_PART_SIZE, SINGLE_PUT_MAX_BYTES } from '../../src/uploads/policy';
import { apiRequest, makeDeps, UPLOADER_ID } from '../support/fakes';

type Deps = ReturnType<typeof makeDeps>;

const audio = { purpose: 'media', mime: 'audio/mpeg', size: 11 };

async function createUpload(deps: Deps, body: unknown = audio, token = 'token-uploader') {
  const response = await handleRequest(apiRequest('/api/uploads', { token, body }), deps);
  return { response, body: (await response.json()) as Record<string, unknown> };
}

describe('POST /api/uploads — authentication & authorisation', () => {
  let deps: Deps;
  beforeEach(() => {
    deps = makeDeps(env.MEDIA);
  });

  it('401 without a bearer token', async () => {
    const response = await handleRequest(apiRequest('/api/uploads', { body: audio }), deps);
    expect(response.status).toBe(401);
    expect(await response.json()).toEqual({ error: 'unauthenticated' });
  });

  it('401 with an invalid token', async () => {
    const { response } = await createUpload(deps, audio, 'token-forged');
    expect(response.status).toBe(401);
  });

  it('403 for a disabled user', async () => {
    const { response, body } = await createUpload(deps, audio, 'token-disabled');
    expect(response.status).toBe(403);
    expect(body).toEqual({ error: 'forbidden' });
  });

  it('403 for a user without a profile', async () => {
    const { response } = await createUpload(deps, audio, 'token-no-profile');
    expect(response.status).toBe(403);
  });

  it('400 for malformed JSON', async () => {
    const request = new Request('https://naney.test/api/uploads', {
      method: 'POST',
      headers: { authorization: 'Bearer token-uploader', 'content-type': 'application/json' },
      body: '{not json',
    });
    const response = await handleRequest(request, deps);
    expect(response.status).toBe(400);
    expect(await response.json()).toEqual({ error: 'invalid_json' });
  });

  it('400 for a disallowed type, without recording anything', async () => {
    const { response, body } = await createUpload(deps, { ...audio, mime: 'text/html' });
    expect(response.status).toBe(400);
    expect(body).toEqual({ error: 'unsupported_type' });
    expect(deps.uploads.rows.size).toBe(0);
  });

  it('405 for GET', async () => {
    const response = await handleRequest(
      apiRequest('/api/uploads', { method: 'GET', token: 'token-uploader' }),
      deps,
    );
    expect(response.status).toBe(405);
  });
});

describe('POST /api/uploads — planning', () => {
  let deps: Deps;
  beforeEach(() => {
    deps = makeDeps(env.MEDIA);
  });

  it('returns a single presigned PUT for small files and records the upload', async () => {
    const { response, body } = await createUpload(deps);
    expect(response.status).toBe(201);
    expect(body.method).toBe('single');
    expect(body.objectKey).toMatch(/^media\/[0-9a-f-]{36}\.mp3$/);
    expect(body.url).toBe(`https://r2.test/${body.objectKey}?signed=put&type=audio%2Fmpeg`);
    expect(body.headers).toEqual({ 'content-type': 'audio/mpeg' });

    const row = deps.uploads.rows.get(body.uploadId as string);
    expect(row).toMatchObject({
      owner: UPLOADER_ID,
      purpose: 'media',
      mime: 'audio/mpeg',
      declaredSize: 11,
      multipartUploadId: null,
      verifiedAt: null,
    });
  });

  it('returns multipart part URLs for large videos', async () => {
    const size = SINGLE_PUT_MAX_BYTES + 5;
    const { response, body } = await createUpload(deps, {
      purpose: 'media',
      mime: 'video/mp4',
      size,
    });
    expect(response.status).toBe(201);
    expect(body.method).toBe('multipart');
    expect(body.partSize).toBe(MULTIPART_PART_SIZE);
    const parts = body.parts as { partNumber: number; url: string }[];
    expect(parts).toHaveLength(Math.ceil(size / MULTIPART_PART_SIZE));
    expect(parts[0]?.partNumber).toBe(1);
    expect(parts.at(-1)?.partNumber).toBe(parts.length);

    const row = deps.uploads.rows.get(body.uploadId as string);
    expect(row?.multipartUploadId).toBeTruthy();
    expect(parts[0]?.url).toContain(`uploadId=${row?.multipartUploadId}`);
  });

  it('429 once the daily limit is reached', async () => {
    for (let i = 0; i < deps.maxUploadsPerDay; i += 1) {
      expect((await createUpload(deps)).response.status).toBe(201);
    }
    const { response, body } = await createUpload(deps);
    expect(response.status).toBe(429);
    expect(body).toEqual({ error: 'daily_limit_reached' });
  });
});

describe('POST /api/uploads/:id/complete', () => {
  let deps: Deps;
  beforeEach(() => {
    deps = makeDeps(env.MEDIA);
  });

  async function complete(uploadId: string, token = 'token-uploader', body: unknown = {}) {
    const response = await handleRequest(
      apiRequest(`/api/uploads/${uploadId}/complete`, { token, body }),
      deps,
    );
    return { response, body: (await response.json()) as Record<string, unknown> };
  }

  it('verifies a stored object whose size and type match', async () => {
    const created = await createUpload(deps);
    await env.MEDIA.put(created.body.objectKey as string, 'hello world', {
      httpMetadata: { contentType: 'audio/mpeg' },
    });

    const { response, body } = await complete(created.body.uploadId as string);

    expect(response.status).toBe(200);
    expect(body).toEqual({
      uploadId: created.body.uploadId,
      objectKey: created.body.objectKey,
      verified: true,
    });
    expect(deps.uploads.rows.get(created.body.uploadId as string)?.verifiedAt).not.toBeNull();
  });

  it('is idempotent once verified', async () => {
    const created = await createUpload(deps);
    await env.MEDIA.put(created.body.objectKey as string, 'hello world', {
      httpMetadata: { contentType: 'audio/mpeg' },
    });
    await complete(created.body.uploadId as string);
    const { response } = await complete(created.body.uploadId as string);
    expect(response.status).toBe(200);
  });

  it('422 when nothing was uploaded', async () => {
    const created = await createUpload(deps);
    const { response, body } = await complete(created.body.uploadId as string);
    expect(response.status).toBe(422);
    expect(body).toEqual({ error: 'object_missing' });
  });

  it('422 and deletes the object when the size differs from the declaration', async () => {
    const created = await createUpload(deps);
    const key = created.body.objectKey as string;
    await env.MEDIA.put(key, 'a much longer body than declared', {
      httpMetadata: { contentType: 'audio/mpeg' },
    });

    const { response, body } = await complete(created.body.uploadId as string);

    expect(response.status).toBe(422);
    expect(body).toEqual({ error: 'object_mismatch' });
    expect(await env.MEDIA.head(key)).toBeNull();
    expect(deps.uploads.rows.has(created.body.uploadId as string)).toBe(false);
  });

  it('422 when the stored content type differs', async () => {
    const created = await createUpload(deps);
    await env.MEDIA.put(created.body.objectKey as string, 'hello world', {
      httpMetadata: { contentType: 'text/html' },
    });
    const { response } = await complete(created.body.uploadId as string);
    expect(response.status).toBe(422);
  });

  it("404 for someone else's upload", async () => {
    const created = await createUpload(deps);
    const { response } = await complete(created.body.uploadId as string, 'token-other');
    expect(response.status).toBe(404);
  });

  it('404 for an unknown or malformed id', async () => {
    expect((await complete('00000000-0000-4000-8000-ffffffffffff')).response.status).toBe(404);
    expect((await complete('not-a-uuid')).response.status).toBe(404);
  });

  it('completes a multipart upload from the part ETags', async () => {
    const size = SINGLE_PUT_MAX_BYTES + 5;
    const created = await createUpload(deps, { purpose: 'media', mime: 'video/mp4', size });
    const row = deps.uploads.rows.get(created.body.uploadId as string);
    if (!row?.multipartUploadId) throw new Error('expected multipart');
    // Shrink the declaration so the test can upload a tiny single part.
    row.declaredSize = 5;
    const multipart = env.MEDIA.resumeMultipartUpload(row.objectKey, row.multipartUploadId);
    const part = await multipart.uploadPart(1, 'abcde');

    const { response } = await complete(created.body.uploadId as string, 'token-uploader', {
      parts: [{ partNumber: 1, etag: part.etag }],
    });

    expect(response.status).toBe(200);
    expect((await env.MEDIA.head(row.objectKey))?.size).toBe(5);
  });

  it('400 when a multipart completion has no parts', async () => {
    const created = await createUpload(deps, {
      purpose: 'media',
      mime: 'video/mp4',
      size: SINGLE_PUT_MAX_BYTES + 5,
    });
    const { response, body } = await complete(created.body.uploadId as string);
    expect(response.status).toBe(400);
    expect(body).toEqual({ error: 'invalid_parts' });
  });
});

describe('CORS', () => {
  it('answers preflight for an allowed origin', async () => {
    const deps = makeDeps(env.MEDIA);
    const response = await handleRequest(
      apiRequest('/api/uploads', {
        method: 'OPTIONS',
        headers: { origin: 'http://localhost:8080' },
      }),
      deps,
    );
    expect(response.status).toBe(204);
    expect(response.headers.get('access-control-allow-origin')).toBe('http://localhost:8080');
    expect(response.headers.get('access-control-allow-headers')).toContain('authorization');
  });

  it('adds no CORS headers for other origins', async () => {
    const deps = makeDeps(env.MEDIA);
    const response = await handleRequest(
      apiRequest('/api/uploads', {
        method: 'OPTIONS',
        headers: { origin: 'https://evil.example' },
      }),
      deps,
    );
    expect(response.headers.get('access-control-allow-origin')).toBeNull();
  });
});
