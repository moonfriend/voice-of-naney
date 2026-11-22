import { describe, expect, it } from 'vitest';
import { ConfigError, parseConfig } from '../src/config';

const complete = {
  SUPABASE_URL: 'https://proj.supabase.co/',
  SUPABASE_SECRET_KEY: 'sb_secret_x',
  CLOUDFLARE_ACCOUNT_ID: 'acc',
  R2_BUCKET: 'naney-media',
  R2_ACCESS_KEY_ID: 'id',
  R2_SECRET_ACCESS_KEY: 'secret',
  ALLOWED_ORIGINS: 'http://localhost:8080, http://127.0.0.1:8080',
  MAX_UPLOADS_PER_DAY: '30',
};

describe('parseConfig', () => {
  it('parses a complete environment', () => {
    expect(parseConfig(complete)).toEqual({
      supabaseUrl: 'https://proj.supabase.co',
      supabaseSecretKey: 'sb_secret_x',
      r2: { accountId: 'acc', bucket: 'naney-media', accessKeyId: 'id', secretAccessKey: 'secret' },
      allowedOrigins: ['http://localhost:8080', 'http://127.0.0.1:8080'],
      maxUploadsPerDay: 30,
    });
  });

  it('names every missing value without revealing any', () => {
    expect(() => parseConfig({ SUPABASE_URL: 'https://x.co' })).toThrowError(
      new ConfigError([
        'SUPABASE_SECRET_KEY',
        'CLOUDFLARE_ACCOUNT_ID',
        'R2_BUCKET',
        'R2_ACCESS_KEY_ID',
        'R2_SECRET_ACCESS_KEY',
      ]),
    );
  });

  it('defaults optional values', () => {
    const config = parseConfig({ ...complete, ALLOWED_ORIGINS: '', MAX_UPLOADS_PER_DAY: '' });
    expect(config.allowedOrigins).toEqual([]);
    expect(config.maxUploadsPerDay).toBe(50);
  });

  it('rejects a non-numeric upload limit', () => {
    expect(() => parseConfig({ ...complete, MAX_UPLOADS_PER_DAY: 'lots' })).toThrow(ConfigError);
  });
});
