import { SELF } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';

describe('GET /api/health', () => {
  it('reports ok', async () => {
    const response = await SELF.fetch('https://example.com/api/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: 'ok' });
  });
});
