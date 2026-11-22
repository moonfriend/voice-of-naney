const ALLOWED_METHODS = 'GET, HEAD, POST, OPTIONS';
const ALLOWED_HEADERS = 'authorization, content-type, range';
const EXPOSED_HEADERS = 'content-length, content-range, accept-ranges, etag';

/** Only needed in development, where the app (:8080) and Worker (:8787) are different origins. */
export function withCors(
  response: Response,
  request: Request,
  allowedOrigins: readonly string[],
): Response {
  const origin = request.headers.get('origin');
  if (!origin || !allowedOrigins.includes(origin)) {
    return response;
  }
  const headers = new Headers(response.headers);
  headers.set('access-control-allow-origin', origin);
  headers.set('access-control-allow-methods', ALLOWED_METHODS);
  headers.set('access-control-allow-headers', ALLOWED_HEADERS);
  headers.set('access-control-expose-headers', EXPOSED_HEADERS);
  headers.set('access-control-max-age', '86400');
  headers.append('vary', 'origin');
  return new Response(response.body, {
    status: response.status,
    statusText: response.statusText,
    headers,
  });
}
