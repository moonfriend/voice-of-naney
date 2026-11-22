import { R2UrlSigner } from './adapters/r2-signer';
import { SupabaseRest } from './adapters/supabase-rest';
import { ConfigError, parseConfig } from './config';
import { json } from './http';
import type { Deps } from './ports';
import { handleRequest } from './router';

/** Secrets are pushed with `scripts/push-worker-secrets.sh`; they are not in wrangler.jsonc. */
type WorkerEnv = Env & Record<string, unknown>;

export default {
  async fetch(request: Request, env: WorkerEnv): Promise<Response> {
    if (new URL(request.url).pathname === '/api/health') {
      return json({ status: 'ok' });
    }
    let deps: Deps;
    try {
      deps = buildDeps(env);
    } catch (error) {
      if (error instanceof ConfigError) {
        console.error(error.message);
        return json({ error: 'service_unavailable' }, { status: 503 });
      }
      throw error;
    }
    return handleRequest(request, deps);
  },
} satisfies ExportedHandler<WorkerEnv>;

function buildDeps(env: WorkerEnv): Deps {
  const config = parseConfig(env);
  const supabase = new SupabaseRest({
    url: config.supabaseUrl,
    secretKey: config.supabaseSecretKey,
  });
  return {
    identity: supabase,
    profiles: { find: (userId) => supabase.findProfile(userId) },
    uploads: {
      countCreatedSince: (owner, since) => supabase.countCreatedSince(owner, since),
      insert: (upload) => supabase.insert(upload),
      find: (id) => supabase.findUpload(id),
      markVerified: (id) => supabase.markVerified(id),
      remove: (id) => supabase.remove(id),
    },
    signer: new R2UrlSigner(config.r2),
    bucket: env.MEDIA,
    geoFetch: cachedFetch,
    allowedOrigins: config.allowedOrigins,
    maxUploadsPerDay: config.maxUploadsPerDay,
    now: () => new Date(),
    newId: () => crypto.randomUUID(),
  };
}

const GEO_CACHE_SECONDS = 7 * 24 * 60 * 60;

/** Place names and boundaries rarely change; caching keeps us well inside Nominatim's policy. */
async function cachedFetch(input: RequestInfo | URL, init?: RequestInit): Promise<Response> {
  const request = new Request(input, init);
  const cache = caches.default;
  const cached = await cache.match(request);
  if (cached) {
    return cached;
  }
  const response = await fetch(request);
  if (response.ok) {
    const cacheable = new Response(response.clone().body, response);
    cacheable.headers.set('cache-control', `public, max-age=${GEO_CACHE_SECONDS}`);
    await cache.put(request, cacheable);
  }
  return response;
}
