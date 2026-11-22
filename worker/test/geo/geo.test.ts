import { env } from 'cloudflare:test';
import { describe, expect, it } from 'vitest';
import { placeKindFor } from '../../src/geo/geo';
import { handleRequest } from '../../src/router';
import { apiRequest, makeDeps } from '../support/fakes';

const photonResponse = {
  features: [
    {
      geometry: { type: 'Point', coordinates: [46.29, 38.08] },
      properties: {
        osm_type: 'R',
        osm_id: 123456,
        osm_key: 'place',
        osm_value: 'city',
        type: 'city',
        name: 'Tabriz',
        state: 'East Azerbaijan Province',
        country: 'Iran',
        extent: [46.1, 38.15, 46.45, 37.95],
      },
    },
    {
      geometry: { type: 'Point', coordinates: [46.3, 38.07] },
      properties: {
        osm_type: 'N',
        osm_id: 42,
        osm_value: 'hamlet',
        type: 'locality',
        name: 'Some hamlet',
      },
    },
  ],
};

const nominatimResponse = {
  type: 'FeatureCollection',
  features: [
    {
      type: 'Feature',
      properties: {
        osm_type: 'relation',
        osm_id: 123456,
        category: 'boundary',
        type: 'administrative',
        addresstype: 'city',
        name: 'تبریز',
        namedetails: { name: 'تبریز', 'name:en': 'Tabriz', 'name:fa': 'تبریز' },
      },
      geometry: {
        type: 'Polygon',
        coordinates: [
          [
            [46.2, 38.0],
            [46.4, 38.0],
            [46.4, 38.15],
            [46.2, 38.0],
          ],
        ],
      },
    },
  ],
};

function geoDeps(responder: (url: URL, headers: Headers) => Response) {
  const calls: URL[] = [];
  const deps = makeDeps(env.MEDIA, {
    geoFetch: async (input: RequestInfo | URL, init?: RequestInit) => {
      const request = new Request(input, init);
      const url = new URL(request.url);
      calls.push(url);
      return responder(url, request.headers);
    },
  });
  return { deps, calls };
}

describe('GET /api/geo/search', () => {
  it('requires an uploader', async () => {
    const { deps } = geoDeps(() => Response.json(photonResponse));
    const response = await handleRequest(
      apiRequest('/api/geo/search?q=tabriz', { method: 'GET' }),
      deps,
    );
    expect(response.status).toBe(401);
  });

  it('proxies Photon with an identifying User-Agent and maps results', async () => {
    let userAgent: string | null = null;
    const { deps, calls } = geoDeps((_url, headers) => {
      userAgent = headers.get('user-agent');
      return Response.json(photonResponse);
    });
    const response = await handleRequest(
      apiRequest('/api/geo/search?q=%20Tabriz%20', { method: 'GET', token: 'token-uploader' }),
      deps,
    );

    expect(response.status).toBe(200);
    expect(calls[0]?.origin).toBe('https://photon.komoot.io');
    expect(calls[0]?.searchParams.get('q')).toBe('Tabriz');
    expect(calls[0]?.searchParams.get('limit')).toBe('8');
    expect(userAgent).toMatch(/^VoiceOfNaney\//);
    expect(await response.json()).toEqual({
      results: [
        {
          name: 'Tabriz',
          context: 'East Azerbaijan Province, Iran',
          osmType: 'relation',
          osmId: 123456,
          kind: 'city',
          lng: 46.29,
          lat: 38.08,
          hasBoundary: true,
        },
        {
          name: 'Some hamlet',
          context: '',
          osmType: 'node',
          osmId: 42,
          kind: 'village',
          lng: 46.3,
          lat: 38.07,
          hasBoundary: false,
        },
      ],
    });
  });

  it.each(['', 'a', 'x'.repeat(201)])('400 for an unusable query %#', async (q) => {
    const { deps } = geoDeps(() => Response.json(photonResponse));
    const response = await handleRequest(
      apiRequest(`/api/geo/search?q=${encodeURIComponent(q)}`, {
        method: 'GET',
        token: 'token-uploader',
      }),
      deps,
    );
    expect(response.status).toBe(400);
  });

  it('502 when the geocoder fails', async () => {
    const { deps } = geoDeps(() => new Response('down', { status: 503 }));
    const response = await handleRequest(
      apiRequest('/api/geo/search?q=tabriz', { method: 'GET', token: 'token-uploader' }),
      deps,
    );
    expect(response.status).toBe(502);
    expect(await response.json()).toEqual({ error: 'geocoder_unavailable' });
  });
});

describe('GET /api/geo/boundary', () => {
  it('returns the OSM boundary as GeoJSON with English and Persian names', async () => {
    const { deps, calls } = geoDeps(() => Response.json(nominatimResponse));
    const response = await handleRequest(
      apiRequest('/api/geo/boundary?osm_type=relation&osm_id=123456', {
        method: 'GET',
        token: 'token-uploader',
      }),
      deps,
    );

    expect(response.status).toBe(200);
    expect(calls[0]?.origin).toBe('https://nominatim.openstreetmap.org');
    expect(calls[0]?.searchParams.get('osm_ids')).toBe('R123456');
    expect(calls[0]?.searchParams.get('polygon_geojson')).toBe('1');
    expect(await response.json()).toEqual({
      osmType: 'relation',
      osmId: 123456,
      nameEn: 'Tabriz',
      nameFa: 'تبریز',
      kind: 'city',
      geojson: nominatimResponse.features[0]?.geometry,
    });
  });

  it('404 when OSM has no area for the place (the app then lets the user draw)', async () => {
    const pointOnly = {
      type: 'FeatureCollection',
      features: [
        {
          type: 'Feature',
          properties: { osm_type: 'node', osm_id: 42, addresstype: 'hamlet', name: 'Some hamlet' },
          geometry: { type: 'Point', coordinates: [46.3, 38.07] },
        },
      ],
    };
    const { deps } = geoDeps(() => Response.json(pointOnly));
    const response = await handleRequest(
      apiRequest('/api/geo/boundary?osm_type=node&osm_id=42', {
        method: 'GET',
        token: 'token-uploader',
      }),
      deps,
    );
    expect(response.status).toBe(404);
    expect(await response.json()).toEqual({ error: 'no_boundary' });
  });

  it.each([
    'osm_type=area&osm_id=1',
    'osm_type=relation&osm_id=abc',
    'osm_type=relation',
    'osm_type=relation&osm_id=-5',
  ])('400 for invalid parameters: %s', async (query) => {
    const { deps } = geoDeps(() => Response.json(nominatimResponse));
    const response = await handleRequest(
      apiRequest(`/api/geo/boundary?${query}`, { method: 'GET', token: 'token-uploader' }),
      deps,
    );
    expect(response.status).toBe(400);
  });
});

describe('placeKindFor', () => {
  it.each([
    ['country', undefined, 'country'],
    ['state', undefined, 'province'],
    ['province', undefined, 'province'],
    ['county', undefined, 'province'],
    ['city', undefined, 'city'],
    ['town', undefined, 'city'],
    ['village', undefined, 'village'],
    ['hamlet', undefined, 'village'],
    ['suburb', undefined, 'district'],
    ['district', undefined, 'district'],
    ['neighbourhood', undefined, 'district'],
    ['unknown', 'city', 'city'],
    ['unknown', undefined, 'district'],
  ])('%s (fallback %s) → %s', (value, fallback, expected) => {
    expect(placeKindFor(value, fallback)).toBe(expected);
  });
});
