import { HttpError } from './http';

/** Only keys the Worker itself generates can be served: no traversal, no arbitrary objects. */
const MEDIA_PATH =
  /^\/((?:media|photos)\/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.[a-z0-9]{2,4})$/;

/** Keys are random UUIDs that never get reused, so responses can be cached forever. */
const CACHE_CONTROL = 'public, max-age=31536000, immutable';

export function mediaKeyFromPath(pathname: string): string | null {
  return MEDIA_PATH.exec(pathname)?.[1] ?? null;
}

export async function serveMedia(
  request: Request,
  bucket: R2Bucket,
  key: string,
): Promise<Response> {
  if (request.method !== 'GET' && request.method !== 'HEAD') {
    throw new HttpError(405, 'method_not_allowed');
  }

  const head = await bucket.head(key);
  if (!head) {
    throw new HttpError(404, 'not_found');
  }

  const range = parseRange(request.headers.get('range'), head.size);
  if (range === 'unsatisfiable') {
    return new Response(null, {
      status: 416,
      headers: { 'content-range': `bytes */${head.size}` },
    });
  }

  const headers = new Headers();
  head.writeHttpMetadata(headers);
  headers.set('etag', head.httpEtag);
  headers.set('accept-ranges', 'bytes');
  headers.set('cache-control', CACHE_CONTROL);

  if (request.method === 'HEAD') {
    headers.set('content-length', String(head.size));
    return new Response(null, { status: 200, headers });
  }

  if (range === null) {
    const object = await bucket.get(key);
    if (!object) {
      throw new HttpError(404, 'not_found');
    }
    headers.set('content-length', String(object.size));
    return new Response(object.body, { status: 200, headers });
  }

  const object = await bucket.get(key, {
    range: { offset: range.start, length: range.end - range.start + 1 },
  });
  if (!object) {
    throw new HttpError(404, 'not_found');
  }
  headers.set('content-range', `bytes ${range.start}-${range.end}/${head.size}`);
  headers.set('content-length', String(range.end - range.start + 1));
  return new Response(object.body, { status: 206, headers });
}

interface ByteRange {
  start: number;
  end: number;
}

/** Supports a single `bytes=` range (all that browsers send for media); anything else → full body. */
function parseRange(header: string | null, size: number): ByteRange | 'unsatisfiable' | null {
  const match = header ? /^bytes=(\d*)-(\d*)$/.exec(header.trim()) : null;
  if (!match) {
    return null;
  }
  const [, startText = '', endText = ''] = match;
  if (startText === '' && endText === '') {
    return null;
  }
  if (startText === '') {
    const suffix = Number(endText);
    if (suffix === 0) {
      return 'unsatisfiable';
    }
    return { start: Math.max(0, size - suffix), end: size - 1 };
  }
  const start = Number(startText);
  const end = endText === '' ? size - 1 : Math.min(Number(endText), size - 1);
  if (start >= size || start > end) {
    return 'unsatisfiable';
  }
  return { start, end };
}
