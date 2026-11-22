import { HttpError } from '../http';

export type UploadPurpose = 'media' | 'photo';

export interface UploadRequest {
  purpose: UploadPurpose;
  mime: string;
  size: number;
  extension: string;
}

export type UploadPlan =
  | { objectKey: string; method: 'single' }
  | { objectKey: string; method: 'multipart'; partSize: number; partCount: number };

const MB = 1024 * 1024;

/** Above this, uploads are split into parts so a dropped connection only costs one part. */
export const SINGLE_PUT_MAX_BYTES = 100 * MB;
export const MULTIPART_PART_SIZE = 10 * MB;

interface MimeRule {
  extension: string;
  maxBytes: number;
}

const AUDIO_MAX = 50 * MB;
const VIDEO_MAX = 500 * MB;
const PHOTO_MAX = 10 * MB;

const ALLOWED: Record<UploadPurpose, Record<string, MimeRule>> = {
  media: {
    'audio/mpeg': { extension: 'mp3', maxBytes: AUDIO_MAX },
    'audio/mp4': { extension: 'm4a', maxBytes: AUDIO_MAX },
    'audio/x-m4a': { extension: 'm4a', maxBytes: AUDIO_MAX },
    'audio/aac': { extension: 'aac', maxBytes: AUDIO_MAX },
    'audio/wav': { extension: 'wav', maxBytes: AUDIO_MAX },
    'audio/x-wav': { extension: 'wav', maxBytes: AUDIO_MAX },
    'audio/ogg': { extension: 'ogg', maxBytes: AUDIO_MAX },
    'audio/webm': { extension: 'webm', maxBytes: AUDIO_MAX },
    'audio/flac': { extension: 'flac', maxBytes: AUDIO_MAX },
    'audio/x-flac': { extension: 'flac', maxBytes: AUDIO_MAX },
    'video/mp4': { extension: 'mp4', maxBytes: VIDEO_MAX },
    'video/webm': { extension: 'webm', maxBytes: VIDEO_MAX },
    // iPhone camera videos; most use H.264 and play in current browsers.
    'video/quicktime': { extension: 'mov', maxBytes: VIDEO_MAX },
    'video/x-m4v': { extension: 'm4v', maxBytes: VIDEO_MAX },
  },
  photo: {
    'image/jpeg': { extension: 'jpg', maxBytes: PHOTO_MAX },
    'image/png': { extension: 'png', maxBytes: PHOTO_MAX },
    'image/webp': { extension: 'webp', maxBytes: PHOTO_MAX },
  },
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null && !Array.isArray(value);
}

function isPurpose(value: unknown): value is UploadPurpose {
  return value === 'media' || value === 'photo';
}

/** Validates what the client *declares*; the stored object is checked again on completion. */
export function parseUploadRequest(body: unknown): UploadRequest {
  if (!isRecord(body)) {
    throw new HttpError(400, 'invalid_body');
  }
  const { purpose, mime, size } = body;
  if (!isPurpose(purpose)) {
    throw new HttpError(400, 'invalid_purpose');
  }
  const normalisedMime =
    typeof mime === 'string' ? (mime.split(';')[0] ?? '').trim().toLowerCase() : '';
  const rule = ALLOWED[purpose][normalisedMime];
  if (rule === undefined) {
    throw new HttpError(400, 'unsupported_type');
  }
  if (typeof size !== 'number' || !Number.isInteger(size) || size <= 0) {
    throw new HttpError(400, 'invalid_size');
  }
  if (size > rule.maxBytes) {
    throw new HttpError(400, 'too_large');
  }
  return { purpose, mime: normalisedMime, size, extension: rule.extension };
}

export function planUpload(request: UploadRequest, id: string): UploadPlan {
  const folder = request.purpose === 'media' ? 'media' : 'photos';
  const objectKey = `${folder}/${id}.${request.extension}`;
  if (request.size <= SINGLE_PUT_MAX_BYTES) {
    return { objectKey, method: 'single' };
  }
  return {
    objectKey,
    method: 'multipart',
    partSize: MULTIPART_PART_SIZE,
    partCount: Math.ceil(request.size / MULTIPART_PART_SIZE),
  };
}
