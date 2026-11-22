import type { UploadPurpose } from './uploads/policy';

/** Boundaries to the outside world, so handlers can be tested without network access. */

export type UserRole = 'admin' | 'uploader';

export interface Profile {
  role: UserRole;
  disabled: boolean;
}

export interface UploadRecord {
  id: string;
  objectKey: string;
  owner: string;
  purpose: UploadPurpose;
  mime: string;
  declaredSize: number;
  multipartUploadId: string | null;
  verifiedAt: string | null;
}

export type NewUpload = Omit<UploadRecord, 'verifiedAt'>;

export interface Identity {
  /** Resolves a Supabase access token to its user id, or null when invalid/expired/revoked. */
  userIdForToken(accessToken: string): Promise<string | null>;
}

export interface Profiles {
  find(userId: string): Promise<Profile | null>;
}

export interface Uploads {
  countCreatedSince(owner: string, since: Date): Promise<number>;
  insert(upload: NewUpload): Promise<UploadRecord>;
  find(id: string): Promise<UploadRecord | null>;
  markVerified(id: string): Promise<void>;
  remove(id: string): Promise<void>;
}

export interface UrlSigner {
  signPut(objectKey: string, mime: string): Promise<string>;
  signPart(objectKey: string, multipartUploadId: string, partNumber: number): Promise<string>;
}

export interface Deps {
  identity: Identity;
  profiles: Profiles;
  uploads: Uploads;
  signer: UrlSigner;
  bucket: R2Bucket;
  /** Outbound fetch for Photon/Nominatim; cached in production (see index.ts). */
  geoFetch: typeof fetch;
  allowedOrigins: readonly string[];
  maxUploadsPerDay: number;
  now: () => Date;
  newId: () => string;
}
