/** An error that maps directly to an HTTP response with a stable, machine-readable code. */
export class HttpError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message?: string,
  ) {
    super(message ?? code);
    this.name = 'HttpError';
  }
}

export function json(body: unknown, init: ResponseInit = {}): Response {
  return Response.json(body, init);
}

export function errorResponse(error: HttpError): Response {
  return json({ error: error.code }, { status: error.status });
}

/** Reads a JSON body, turning malformed input into a 400 instead of a 500. */
export async function readJson(request: Request): Promise<unknown> {
  try {
    return await request.json();
  } catch {
    throw new HttpError(400, 'invalid_json');
  }
}
