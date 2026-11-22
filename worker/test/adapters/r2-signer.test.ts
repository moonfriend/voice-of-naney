import { describe, expect, it } from 'vitest';
import { R2UrlSigner } from '../../src/adapters/r2-signer';

const signer = new R2UrlSigner({
  accountId: 'acc123',
  bucket: 'naney-media',
  accessKeyId: 'AKIDEXAMPLE',
  secretAccessKey: 'secret',
});

describe('R2UrlSigner', () => {
  it('presigns a PUT bound to the content type, valid for 15 minutes', async () => {
    const url = new URL(await signer.signPut('media/a.mp3', 'audio/mpeg'));
    expect(url.origin).toBe('https://acc123.r2.cloudflarestorage.com');
    expect(url.pathname).toBe('/naney-media/media/a.mp3');
    expect(url.searchParams.get('X-Amz-Expires')).toBe('900');
    expect(url.searchParams.get('X-Amz-Signature')).toMatch(/^[0-9a-f]{64}$/);
    expect(url.searchParams.get('X-Amz-SignedHeaders')).toContain('content-type');
  });

  it('presigns an UploadPart URL, valid for 6 hours', async () => {
    const url = new URL(await signer.signPart('media/b.mp4', 'mpu-1', 3));
    expect(url.pathname).toBe('/naney-media/media/b.mp4');
    expect(url.searchParams.get('partNumber')).toBe('3');
    expect(url.searchParams.get('uploadId')).toBe('mpu-1');
    expect(url.searchParams.get('X-Amz-Expires')).toBe('21600');
    expect(url.searchParams.get('X-Amz-Signature')).toMatch(/^[0-9a-f]{64}$/);
  });
});
