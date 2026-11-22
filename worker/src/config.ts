import type { R2Credentials } from './adapters/r2-signer';

export interface WorkerConfig {
  supabaseUrl: string;
  supabaseSecretKey: string;
  r2: R2Credentials;
  allowedOrigins: string[];
  maxUploadsPerDay: number;
}

/** Lists missing keys by name only — values are secrets and never appear in errors or logs. */
export class ConfigError extends Error {
  constructor(
    readonly missingKeys: string[],
    detail?: string,
  ) {
    super(detail ?? `Worker is missing configuration: ${missingKeys.join(', ')}`);
    this.name = 'ConfigError';
  }
}

const REQUIRED = [
  'SUPABASE_URL',
  'SUPABASE_SECRET_KEY',
  'CLOUDFLARE_ACCOUNT_ID',
  'R2_BUCKET',
  'R2_ACCESS_KEY_ID',
  'R2_SECRET_ACCESS_KEY',
] as const;

const DEFAULT_MAX_UPLOADS_PER_DAY = 50;

export function parseConfig(source: Record<string, unknown>): WorkerConfig {
  const read = (key: string): string => {
    const value = source[key];
    return typeof value === 'string' ? value.trim() : '';
  };
  const missing = REQUIRED.filter((key) => read(key) === '');
  if (missing.length > 0) {
    throw new ConfigError([...missing]);
  }

  const limitText = read('MAX_UPLOADS_PER_DAY');
  const maxUploadsPerDay = limitText === '' ? DEFAULT_MAX_UPLOADS_PER_DAY : Number(limitText);
  if (!Number.isInteger(maxUploadsPerDay) || maxUploadsPerDay <= 0) {
    throw new ConfigError([], 'MAX_UPLOADS_PER_DAY must be a positive integer');
  }

  return {
    supabaseUrl: read('SUPABASE_URL').replace(/\/+$/, ''),
    supabaseSecretKey: read('SUPABASE_SECRET_KEY'),
    r2: {
      accountId: read('CLOUDFLARE_ACCOUNT_ID'),
      bucket: read('R2_BUCKET'),
      accessKeyId: read('R2_ACCESS_KEY_ID'),
      secretAccessKey: read('R2_SECRET_ACCESS_KEY'),
    },
    allowedOrigins: read('ALLOWED_ORIGINS')
      .split(',')
      .map((origin) => origin.trim())
      .filter((origin) => origin !== ''),
    maxUploadsPerDay,
  };
}
