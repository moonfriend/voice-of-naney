import { withCors } from './cors';
import { placeBoundary, searchPlaces } from './geo/geo';
import { errorResponse, HttpError, json } from './http';
import { mediaKeyFromPath, serveMedia } from './media';
import type { Deps } from './ports';
import { completeUpload, createUpload } from './uploads/handlers';

const COMPLETE_PATTERN = /^\/api\/uploads\/([^/]+)\/complete$/;

/** Handles every request the Worker runs first (`/api/*`, `/media/*`). */
export async function handleRequest(request: Request, deps: Deps): Promise<Response> {
  if (request.method === 'OPTIONS') {
    return withCors(new Response(null, { status: 204 }), request, deps.allowedOrigins);
  }
  let response: Response;
  try {
    response = await route(request, deps);
  } catch (error) {
    if (error instanceof HttpError) {
      response = errorResponse(error);
    } else {
      console.error('unhandled error', error);
      response = json({ error: 'internal_error' }, { status: 500 });
    }
  }
  return withCors(response, request, deps.allowedOrigins);
}

async function route(request: Request, deps: Deps): Promise<Response> {
  const { pathname } = new URL(request.url);

  if (pathname === '/api/health') {
    return json({ status: 'ok' });
  }
  if (pathname.startsWith('/media/') || pathname.startsWith('/photos/')) {
    const key = mediaKeyFromPath(pathname);
    if (!key) {
      throw new HttpError(404, 'not_found');
    }
    return serveMedia(request, deps.bucket, key);
  }
  if (pathname === '/api/geo/search') {
    requireMethod(request, 'GET');
    return searchPlaces(request, deps);
  }
  if (pathname === '/api/geo/boundary') {
    requireMethod(request, 'GET');
    return placeBoundary(request, deps);
  }
  if (pathname === '/api/uploads') {
    requireMethod(request, 'POST');
    return createUpload(request, deps);
  }
  const complete = COMPLETE_PATTERN.exec(pathname);
  if (complete?.[1]) {
    requireMethod(request, 'POST');
    return completeUpload(request, complete[1], deps);
  }
  throw new HttpError(404, 'not_found');
}

function requireMethod(request: Request, method: string): void {
  if (request.method !== method) {
    throw new HttpError(405, 'method_not_allowed');
  }
}
