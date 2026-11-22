import { describe, expect, it } from 'vitest';
import { SupabaseRest } from '../../src/adapters/supabase-rest';

interface Call {
  url: string;
  method: string;
  headers: Headers;
  body: string | null;
}

function stubFetch(responder: (call: Call) => Response) {
  const calls: Call[] = [];
  const fetcher = async (input: RequestInfo | URL, init?: RequestInit): Promise<Response> => {
    const request = new Request(input, init);
    const call = {
      url: request.url,
      method: request.method,
      headers: request.headers,
      body: request.body ? await request.text() : null,
    };
    calls.push(call);
    return responder(call);
  };
  return { calls, fetcher };
}

const BASE = 'https://proj.supabase.co';

function client(fetcher: typeof fetch, secretKey = 'sb_secret_abc') {
  return new SupabaseRest({
    url: BASE,
    secretKey,
    fetcher,
    now: () => new Date('2026-11-22T12:00:00Z'),
  });
}

describe('SupabaseRest', () => {
  it('resolves a user from their access token via /auth/v1/user', async () => {
    const { calls, fetcher } = stubFetch(() => Response.json({ id: 'user-1' }));
    expect(await client(fetcher).userIdForToken('user-jwt')).toBe('user-1');
    expect(calls[0]?.url).toBe(`${BASE}/auth/v1/user`);
    expect(calls[0]?.headers.get('authorization')).toBe('Bearer user-jwt');
    expect(calls[0]?.headers.get('apikey')).toBe('sb_secret_abc');
  });

  it('returns null for a rejected token', async () => {
    const { fetcher } = stubFetch(() => new Response('{}', { status: 401 }));
    expect(await client(fetcher).userIdForToken('bad')).toBeNull();
  });

  it('throws on unexpected auth failures instead of treating them as logged out', async () => {
    const { fetcher } = stubFetch(() => new Response('boom', { status: 500 }));
    await expect(client(fetcher).userIdForToken('x')).rejects.toThrow(/500/);
  });

  it('sends only apikey for new-style secret keys (they are not JWTs)', async () => {
    const { calls, fetcher } = stubFetch(() => Response.json([]));
    await client(fetcher).findProfile('00000000-0000-4000-8000-000000000001');
    expect(calls[0]?.headers.get('apikey')).toBe('sb_secret_abc');
    expect(calls[0]?.headers.get('authorization')).toBeNull();
  });

  it('also sends the bearer header for legacy JWT service keys', async () => {
    const { calls, fetcher } = stubFetch(() => Response.json([]));
    await client(fetcher, 'eyJhbGciOi.legacy.jwt').findProfile(
      '00000000-0000-4000-8000-000000000001',
    );
    expect(calls[0]?.headers.get('authorization')).toBe('Bearer eyJhbGciOi.legacy.jwt');
  });

  it('reads a profile', async () => {
    const { calls, fetcher } = stubFetch(() => Response.json([{ role: 'admin', disabled: false }]));
    expect(await client(fetcher).findProfile('u1')).toEqual({ role: 'admin', disabled: false });
    expect(calls[0]?.url).toBe(`${BASE}/rest/v1/profiles?id=eq.u1&select=role%2Cdisabled`);
  });

  it('counts recent uploads from the Content-Range total', async () => {
    const { calls, fetcher } = stubFetch(
      () => new Response(null, { status: 200, headers: { 'content-range': '*/7' } }),
    );
    expect(await client(fetcher).countCreatedSince('u1', new Date('2026-11-21T12:00:00Z'))).toBe(7);
    expect(calls[0]?.method).toBe('HEAD');
    expect(calls[0]?.headers.get('prefer')).toBe('count=exact');
    expect(calls[0]?.url).toContain('owner=eq.u1');
    expect(calls[0]?.url).toContain('created_at=gte.2026-11-21T12%3A00%3A00.000Z');
  });

  it('inserts an upload and maps snake_case back', async () => {
    const row = {
      id: 'up1',
      object_key: 'media/a.mp3',
      owner: 'u1',
      purpose: 'media',
      mime: 'audio/mpeg',
      declared_size: 10,
      multipart_upload_id: null,
      verified_at: null,
    };
    const { calls, fetcher } = stubFetch(() => Response.json([row], { status: 201 }));
    const inserted = await client(fetcher).insert({
      id: 'up1',
      objectKey: 'media/a.mp3',
      owner: 'u1',
      purpose: 'media',
      mime: 'audio/mpeg',
      declaredSize: 10,
      multipartUploadId: null,
    });
    expect(inserted).toEqual({
      id: 'up1',
      objectKey: 'media/a.mp3',
      owner: 'u1',
      purpose: 'media',
      mime: 'audio/mpeg',
      declaredSize: 10,
      multipartUploadId: null,
      verifiedAt: null,
    });
    expect(calls[0]?.method).toBe('POST');
    expect(calls[0]?.headers.get('prefer')).toBe('return=representation');
    expect(JSON.parse(calls[0]?.body ?? '')).toEqual({
      id: 'up1',
      object_key: 'media/a.mp3',
      owner: 'u1',
      purpose: 'media',
      mime: 'audio/mpeg',
      declared_size: 10,
      multipart_upload_id: null,
    });
  });

  it('returns null when an upload is not found', async () => {
    const { fetcher } = stubFetch(() => Response.json([]));
    expect(await client(fetcher).findUpload('missing')).toBeNull();
  });

  it('marks an upload verified with the current time', async () => {
    const { calls, fetcher } = stubFetch(() => new Response(null, { status: 204 }));
    await client(fetcher).markVerified('up1');
    expect(calls[0]?.method).toBe('PATCH');
    expect(calls[0]?.url).toBe(`${BASE}/rest/v1/uploads?id=eq.up1`);
    expect(JSON.parse(calls[0]?.body ?? '')).toEqual({ verified_at: '2026-11-22T12:00:00.000Z' });
  });

  it('deletes an upload', async () => {
    const { calls, fetcher } = stubFetch(() => new Response(null, { status: 204 }));
    await client(fetcher).remove('up1');
    expect(calls[0]?.method).toBe('DELETE');
  });

  it('fails loudly on database errors', async () => {
    const { fetcher } = stubFetch(() => new Response('nope', { status: 400 }));
    await expect(client(fetcher).remove('up1')).rejects.toThrow(/400/);
  });
});
