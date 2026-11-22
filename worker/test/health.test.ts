import { SELF } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';

describe('Worker entry point', () => {
  it('reports health even before secrets are configured', async () => {
    const response = await SELF.fetch('https://example.com/api/health');
    expect(response.status).toBe(200);
    expect(await response.json()).toEqual({ status: 'ok' });
  });

  it('refuses API calls with 503 when secrets are missing, revealing nothing', async () => {
    const response = await SELF.fetch('https://example.com/api/uploads', { method: 'POST' });
    expect(response.status).toBe(503);
    expect(await response.json()).toEqual({ error: 'service_unavailable' });
  });
});
