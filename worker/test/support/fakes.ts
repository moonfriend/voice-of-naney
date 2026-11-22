import type {
  Deps,
  Identity,
  NewUpload,
  Profile,
  Profiles,
  UploadRecord,
  Uploads,
  UrlSigner,
} from '../../src/ports';

export const UPLOADER_ID = '00000000-0000-0000-0000-0000000000a1';
export const OTHER_UPLOADER_ID = '00000000-0000-0000-0000-0000000000a2';
export const DISABLED_ID = '00000000-0000-0000-0000-0000000000d1';
export const NO_PROFILE_ID = '00000000-0000-0000-0000-0000000000f0';

export const TOKENS: Record<string, string> = {
  'token-uploader': UPLOADER_ID,
  'token-other': OTHER_UPLOADER_ID,
  'token-disabled': DISABLED_ID,
  'token-no-profile': NO_PROFILE_ID,
};

export class FakeIdentity implements Identity {
  async userIdForToken(accessToken: string): Promise<string | null> {
    return TOKENS[accessToken] ?? null;
  }
}

export class FakeProfiles implements Profiles {
  private readonly profiles = new Map<string, Profile>([
    [UPLOADER_ID, { role: 'uploader', disabled: false }],
    [OTHER_UPLOADER_ID, { role: 'uploader', disabled: false }],
    [DISABLED_ID, { role: 'uploader', disabled: true }],
  ]);

  async find(userId: string): Promise<Profile | null> {
    return this.profiles.get(userId) ?? null;
  }
}

export class FakeUploads implements Uploads {
  readonly rows = new Map<string, UploadRecord & { createdAt: Date }>();

  constructor(private readonly clock: () => Date) {}

  async countCreatedSince(owner: string, since: Date): Promise<number> {
    return [...this.rows.values()].filter((row) => row.owner === owner && row.createdAt >= since)
      .length;
  }

  async insert(upload: NewUpload): Promise<UploadRecord> {
    const row = { ...upload, verifiedAt: null, createdAt: this.clock() };
    this.rows.set(upload.id, row);
    return row;
  }

  async find(id: string): Promise<UploadRecord | null> {
    return this.rows.get(id) ?? null;
  }

  async markVerified(id: string): Promise<void> {
    const row = this.rows.get(id);
    if (row) {
      row.verifiedAt = this.clock().toISOString();
    }
  }

  async remove(id: string): Promise<void> {
    this.rows.delete(id);
  }
}

export class FakeSigner implements UrlSigner {
  async signPut(objectKey: string, mime: string): Promise<string> {
    return `https://r2.test/${objectKey}?signed=put&type=${encodeURIComponent(mime)}`;
  }

  async signPart(
    objectKey: string,
    multipartUploadId: string,
    partNumber: number,
  ): Promise<string> {
    return `https://r2.test/${objectKey}?uploadId=${multipartUploadId}&partNumber=${partNumber}`;
  }
}

let idCounter = 0;

export function makeDeps(
  bucket: R2Bucket,
  overrides: Partial<Deps> = {},
): Deps & { uploads: FakeUploads } {
  const now = (): Date => new Date('2026-11-22T12:00:00Z');
  const uploads = new FakeUploads(overrides.now ?? now);
  return {
    identity: new FakeIdentity(),
    profiles: new FakeProfiles(),
    signer: new FakeSigner(),
    bucket,
    allowedOrigins: ['http://localhost:8080'],
    maxUploadsPerDay: 3,
    now,
    newId: () => {
      idCounter += 1;
      return `00000000-0000-4000-8000-${idCounter.toString().padStart(12, '0')}`;
    },
    ...overrides,
    uploads,
  };
}

export function apiRequest(
  path: string,
  init: { method?: string; token?: string; body?: unknown; headers?: Record<string, string> } = {},
): Request {
  const headers = new Headers(init.headers);
  if (init.token) {
    headers.set('authorization', `Bearer ${init.token}`);
  }
  if (init.body !== undefined) {
    headers.set('content-type', 'application/json');
  }
  return new Request(`https://naney.test${path}`, {
    method: init.method ?? 'POST',
    headers,
    body: init.body === undefined ? null : JSON.stringify(init.body),
  });
}
