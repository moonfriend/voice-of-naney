import type { NewUpload, Profile, UploadRecord } from '../ports';
import type { UploadPurpose } from '../uploads/policy';

interface SupabaseRestOptions {
  url: string;
  /** Secret (service) key: bypasses RLS, so it is only ever used server-side. */
  secretKey: string;
  fetcher?: typeof fetch;
  now?: () => Date;
}

interface UploadRow {
  id: string;
  object_key: string;
  owner: string;
  purpose: UploadPurpose;
  mime: string;
  declared_size: number;
  multipart_upload_id: string | null;
  verified_at: string | null;
}

/** Minimal PostgREST/GoTrue client: the Worker needs five queries, not a full SDK. */
export class SupabaseRest {
  private readonly url: string;
  private readonly secretKey: string;
  private readonly fetcher: typeof fetch;
  private readonly now: () => Date;

  constructor(options: SupabaseRestOptions) {
    this.url = options.url.replace(/\/+$/, '');
    this.secretKey = options.secretKey;
    this.fetcher = options.fetcher ?? ((input, init) => fetch(input, init));
    this.now = options.now ?? (() => new Date());
  }

  async userIdForToken(accessToken: string): Promise<string | null> {
    const response = await this.fetcher(`${this.url}/auth/v1/user`, {
      headers: { apikey: this.secretKey, authorization: `Bearer ${accessToken}` },
    });
    if (response.status === 401 || response.status === 403) {
      return null;
    }
    await this.ensureOk(response, 'auth user lookup');
    const user = (await response.json()) as { id?: unknown };
    return typeof user.id === 'string' ? user.id : null;
  }

  async findProfile(userId: string): Promise<Profile | null> {
    const params = new URLSearchParams({ id: `eq.${userId}`, select: 'role,disabled' });
    const rows = await this.select<Profile>('profiles', params);
    return rows[0] ?? null;
  }

  async countCreatedSince(owner: string, since: Date): Promise<number> {
    const params = new URLSearchParams({
      owner: `eq.${owner}`,
      created_at: `gte.${since.toISOString()}`,
      select: 'id',
    });
    const response = await this.fetcher(`${this.url}/rest/v1/uploads?${params}`, {
      method: 'HEAD',
      headers: { ...this.serviceHeaders(), prefer: 'count=exact' },
    });
    await this.ensureOk(response, 'count uploads');
    const total = response.headers.get('content-range')?.split('/')[1];
    const count = Number(total);
    if (!Number.isInteger(count)) {
      throw new Error('count uploads: missing total in content-range');
    }
    return count;
  }

  async insert(upload: NewUpload): Promise<UploadRecord> {
    const response = await this.fetcher(`${this.url}/rest/v1/uploads`, {
      method: 'POST',
      headers: {
        ...this.serviceHeaders(),
        'content-type': 'application/json',
        prefer: 'return=representation',
      },
      body: JSON.stringify({
        id: upload.id,
        object_key: upload.objectKey,
        owner: upload.owner,
        purpose: upload.purpose,
        mime: upload.mime,
        declared_size: upload.declaredSize,
        multipart_upload_id: upload.multipartUploadId,
      }),
    });
    await this.ensureOk(response, 'insert upload');
    const [row] = (await response.json()) as UploadRow[];
    if (!row) {
      throw new Error('insert upload: no row returned');
    }
    return toUploadRecord(row);
  }

  async findUpload(id: string): Promise<UploadRecord | null> {
    const params = new URLSearchParams({ id: `eq.${id}`, select: '*' });
    const rows = await this.select<UploadRow>('uploads', params);
    return rows[0] ? toUploadRecord(rows[0]) : null;
  }

  async markVerified(id: string): Promise<void> {
    await this.mutate('PATCH', 'uploads', id, { verified_at: this.now().toISOString() });
  }

  async remove(id: string): Promise<void> {
    await this.mutate('DELETE', 'uploads', id);
  }

  /** New `sb_secret_…` keys are not JWTs and must not be sent as a bearer token. */
  private serviceHeaders(): Record<string, string> {
    const headers: Record<string, string> = { apikey: this.secretKey };
    if (!this.secretKey.startsWith('sb_')) {
      headers.authorization = `Bearer ${this.secretKey}`;
    }
    return headers;
  }

  private async select<T>(table: string, params: URLSearchParams): Promise<T[]> {
    const response = await this.fetcher(`${this.url}/rest/v1/${table}?${params}`, {
      headers: this.serviceHeaders(),
    });
    await this.ensureOk(response, `select ${table}`);
    return (await response.json()) as T[];
  }

  private async mutate(
    method: 'PATCH' | 'DELETE',
    table: string,
    id: string,
    body?: unknown,
  ): Promise<void> {
    const params = new URLSearchParams({ id: `eq.${id}` });
    const init: RequestInit = {
      method,
      headers: { ...this.serviceHeaders(), 'content-type': 'application/json' },
    };
    if (body !== undefined) {
      init.body = JSON.stringify(body);
    }
    const response = await this.fetcher(`${this.url}/rest/v1/${table}?${params}`, init);
    await this.ensureOk(response, `${method} ${table}`);
  }

  private async ensureOk(response: Response, operation: string): Promise<void> {
    if (!response.ok) {
      // Body may describe the failing query; status alone is enough for logs.
      await response.body?.cancel();
      throw new Error(`${operation} failed with status ${response.status}`);
    }
  }
}

function toUploadRecord(row: UploadRow): UploadRecord {
  return {
    id: row.id,
    objectKey: row.object_key,
    owner: row.owner,
    purpose: row.purpose,
    mime: row.mime,
    declaredSize: Number(row.declared_size),
    multipartUploadId: row.multipart_upload_id,
    verifiedAt: row.verified_at,
  };
}
