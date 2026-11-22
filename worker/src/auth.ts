import { HttpError } from './http';
import type { Deps } from './ports';

/**
 * Returns the caller's user id if they may upload.
 *
 * The token is checked with Supabase Auth itself (not just its signature), so revoked
 * sessions and deleted users are rejected immediately. Uploads are rare, so the extra
 * round-trip is an acceptable price for that.
 */
export async function requireUploader(request: Request, deps: Deps): Promise<string> {
  const header = request.headers.get('authorization') ?? '';
  const match = /^Bearer\s+(\S+)$/i.exec(header);
  const token = match?.[1];
  if (!token) {
    throw new HttpError(401, 'unauthenticated');
  }
  const userId = await deps.identity.userIdForToken(token);
  if (!userId) {
    throw new HttpError(401, 'unauthenticated');
  }
  const profile = await deps.profiles.find(userId);
  if (!profile || profile.disabled) {
    throw new HttpError(403, 'forbidden');
  }
  return userId;
}
