import { env } from 'cloudflare:test';
import { beforeEach, describe, expect, it } from 'vitest';
import { handleRequest } from '../src/router';
import { makeDeps } from './support/fakes';

const KEY = 'media/3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11.mp3';
const BODY = '0123456789';

function get(path: string, headers: Record<string, string> = {}, method = 'GET'): Request {
  return new Request(`https://naney.test${path}`, { method, headers });
}

describe('GET /media/:key', () => {
  beforeEach(async () => {
    await env.MEDIA.put(KEY, BODY, { httpMetadata: { contentType: 'audio/mpeg' } });
  });

  it('streams the whole object with caching and range support advertised', async () => {
    const response = await handleRequest(get(`/${KEY}`), makeDeps(env.MEDIA));
    expect(response.status).toBe(200);
    expect(await response.text()).toBe(BODY);
    expect(response.headers.get('content-type')).toBe('audio/mpeg');
    expect(response.headers.get('accept-ranges')).toBe('bytes');
    expect(response.headers.get('etag')).toBeTruthy();
    expect(response.headers.get('cache-control')).toContain('immutable');
  });

  it('serves a byte range with 206 (needed for seeking in audio/video)', async () => {
    const response = await handleRequest(
      get(`/${KEY}`, { range: 'bytes=2-5' }),
      makeDeps(env.MEDIA),
    );
    expect(response.status).toBe(206);
    expect(await response.text()).toBe('2345');
    expect(response.headers.get('content-range')).toBe('bytes 2-5/10');
    expect(response.headers.get('content-length')).toBe('4');
  });

  it('serves an open-ended range', async () => {
    const response = await handleRequest(
      get(`/${KEY}`, { range: 'bytes=7-' }),
      makeDeps(env.MEDIA),
    );
    expect(response.status).toBe(206);
    expect(await response.text()).toBe('789');
    expect(response.headers.get('content-range')).toBe('bytes 7-9/10');
  });

  it('serves a suffix range', async () => {
    const response = await handleRequest(
      get(`/${KEY}`, { range: 'bytes=-3' }),
      makeDeps(env.MEDIA),
    );
    expect(response.status).toBe(206);
    expect(await response.text()).toBe('789');
  });

  it('416 for an unsatisfiable range', async () => {
    const response = await handleRequest(
      get(`/${KEY}`, { range: 'bytes=50-60' }),
      makeDeps(env.MEDIA),
    );
    expect(response.status).toBe(416);
    expect(response.headers.get('content-range')).toBe('bytes */10');
  });

  it('answers HEAD without a body', async () => {
    const response = await handleRequest(get(`/${KEY}`, {}, 'HEAD'), makeDeps(env.MEDIA));
    expect(response.status).toBe(200);
    expect(response.headers.get('content-length')).toBe('10');
    expect(await response.text()).toBe('');
  });

  it('404 for a missing object', async () => {
    const response = await handleRequest(
      get('/media/00000000-0000-4000-8000-000000000000.mp3'),
      makeDeps(env.MEDIA),
    );
    expect(response.status).toBe(404);
  });

  it.each([
    '/media/../secrets.txt',
    '/media/%2e%2e/x.mp3',
    '/media/not-a-uuid.mp3',
    '/media/3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11.mp3/extra',
    '/other/3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11.mp3',
    '/media/',
  ])('404 for a key outside the allowed pattern: %s', async (path) => {
    const response = await handleRequest(get(path), makeDeps(env.MEDIA));
    expect(response.status).toBe(404);
  });

  it('serves photos too', async () => {
    const photoKey = 'photos/3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11.jpg';
    await env.MEDIA.put(photoKey, 'jpg', { httpMetadata: { contentType: 'image/jpeg' } });
    const response = await handleRequest(get(`/${photoKey}`), makeDeps(env.MEDIA));
    expect(response.status).toBe(200);
  });

  it('405 for POST', async () => {
    const response = await handleRequest(get(`/${KEY}`, {}, 'POST'), makeDeps(env.MEDIA));
    expect(response.status).toBe(405);
  });
});
