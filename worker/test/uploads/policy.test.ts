import { describe, expect, it } from 'vitest';
import { HttpError } from '../../src/http';
import {
  MULTIPART_PART_SIZE,
  parseUploadRequest,
  planUpload,
  SINGLE_PUT_MAX_BYTES,
} from '../../src/uploads/policy';

const MB = 1024 * 1024;

function expectBadRequest(body: unknown, code: string): void {
  try {
    parseUploadRequest(body);
    expect.unreachable('should have thrown');
  } catch (error) {
    expect(error).toBeInstanceOf(HttpError);
    expect((error as HttpError).status).toBe(400);
    expect((error as HttpError).code).toBe(code);
  }
}

describe('parseUploadRequest', () => {
  it('accepts an mp3 for media', () => {
    expect(parseUploadRequest({ purpose: 'media', mime: 'audio/mpeg', size: 5 * MB })).toEqual({
      purpose: 'media',
      mime: 'audio/mpeg',
      size: 5 * MB,
      extension: 'mp3',
    });
  });

  it('normalises mime parameters and case (browser recordings send codecs)', () => {
    expect(
      parseUploadRequest({ purpose: 'media', mime: 'Audio/WebM;codecs=opus', size: 10 }).mime,
    ).toBe('audio/webm');
  });

  it.each([
    ['audio/mp4', 'm4a'],
    ['audio/x-m4a', 'm4a'],
    ['audio/aac', 'aac'],
    ['audio/wav', 'wav'],
    ['audio/x-wav', 'wav'],
    ['audio/ogg', 'ogg'],
    ['audio/webm', 'webm'],
    ['video/mp4', 'mp4'],
    ['video/webm', 'webm'],
    ['video/quicktime', 'mov'],
    ['video/x-m4v', 'm4v'],
  ])('accepts %s for media', (mime, extension) => {
    expect(parseUploadRequest({ purpose: 'media', mime, size: 10 }).extension).toBe(extension);
  });

  it.each([
    ['image/jpeg', 'jpg'],
    ['image/png', 'png'],
    ['image/webp', 'webp'],
  ])('accepts %s for photos', (mime, extension) => {
    expect(parseUploadRequest({ purpose: 'photo', mime, size: 10 }).extension).toBe(extension);
  });

  it('rejects a non-object body', () => expectBadRequest('nope', 'invalid_body'));
  it('rejects an unknown purpose', () =>
    expectBadRequest({ purpose: 'avatar', mime: 'image/png', size: 1 }, 'invalid_purpose'));
  it('rejects a disallowed mime type', () =>
    expectBadRequest({ purpose: 'media', mime: 'application/pdf', size: 1 }, 'unsupported_type'));
  it('rejects an image used as media', () =>
    expectBadRequest({ purpose: 'media', mime: 'image/png', size: 1 }, 'unsupported_type'));
  it('rejects audio used as a photo', () =>
    expectBadRequest({ purpose: 'photo', mime: 'audio/mpeg', size: 1 }, 'unsupported_type'));
  it.each([0, -1, 1.5, '10', null])('rejects size %s', (size) =>
    expectBadRequest({ purpose: 'media', mime: 'audio/mpeg', size }, 'invalid_size'),
  );

  it('allows audio up to 50 MB and rejects more', () => {
    expect(parseUploadRequest({ purpose: 'media', mime: 'audio/mpeg', size: 50 * MB }).size).toBe(
      50 * MB,
    );
    expectBadRequest({ purpose: 'media', mime: 'audio/mpeg', size: 50 * MB + 1 }, 'too_large');
  });

  it('applies the video limit to .mov files (iPhone recordings)', () => {
    expect(
      parseUploadRequest({ purpose: 'media', mime: 'video/quicktime', size: 500 * MB }).size,
    ).toBe(500 * MB);
    expectBadRequest(
      { purpose: 'media', mime: 'video/quicktime', size: 500 * MB + 1 },
      'too_large',
    );
  });

  it('allows video up to 500 MB and rejects more', () => {
    expect(parseUploadRequest({ purpose: 'media', mime: 'video/mp4', size: 500 * MB }).size).toBe(
      500 * MB,
    );
    expectBadRequest({ purpose: 'media', mime: 'video/mp4', size: 500 * MB + 1 }, 'too_large');
  });

  it('allows photos up to 10 MB and rejects more', () => {
    expectBadRequest({ purpose: 'photo', mime: 'image/jpeg', size: 10 * MB + 1 }, 'too_large');
  });
});

describe('planUpload', () => {
  const uuid = '3f0e7f0e-1b7e-4c47-9a9e-0b5d1c2a6f11';

  it('uses a single PUT up to the threshold', () => {
    const plan = planUpload(
      { purpose: 'media', mime: 'audio/mpeg', size: SINGLE_PUT_MAX_BYTES, extension: 'mp3' },
      uuid,
    );
    expect(plan).toEqual({ objectKey: `media/${uuid}.mp3`, method: 'single' });
  });

  it('uses multipart above the threshold with fixed-size parts', () => {
    const size = SINGLE_PUT_MAX_BYTES + 1;
    const plan = planUpload({ purpose: 'media', mime: 'video/mp4', size, extension: 'mp4' }, uuid);
    expect(plan).toEqual({
      objectKey: `media/${uuid}.mp4`,
      method: 'multipart',
      partSize: MULTIPART_PART_SIZE,
      partCount: Math.ceil(size / MULTIPART_PART_SIZE),
    });
  });

  it('stores photos under photos/', () => {
    const plan = planUpload(
      { purpose: 'photo', mime: 'image/png', size: 10, extension: 'png' },
      uuid,
    );
    expect(plan.objectKey).toBe(`photos/${uuid}.png`);
  });
});
