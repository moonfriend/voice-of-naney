import { requireUploader } from '../auth';
import { HttpError, json } from '../http';
import type { Deps } from '../ports';

/**
 * Place search (Photon) and boundaries (Nominatim), proxied so we can identify ourselves,
 * cache results and keep these public services' usage policies. Only uploaders use it.
 */

const PHOTON_URL = 'https://photon.komoot.io/api/';
const NOMINATIM_LOOKUP_URL = 'https://nominatim.openstreetmap.org/lookup';
export const GEO_USER_AGENT = 'VoiceOfNaney/0.1 (oral-heritage archive; low volume)';

export type PlaceKind = 'country' | 'province' | 'city' | 'district' | 'village';
type OsmType = 'node' | 'way' | 'relation';

const KIND_BY_OSM_VALUE: Record<string, PlaceKind> = {
  country: 'country',
  state: 'province',
  province: 'province',
  region: 'province',
  county: 'province',
  city: 'city',
  town: 'city',
  municipality: 'city',
  village: 'village',
  hamlet: 'village',
  isolated_dwelling: 'village',
  suburb: 'district',
  district: 'district',
  borough: 'district',
  quarter: 'district',
  neighbourhood: 'district',
};

export function placeKindFor(value: string | undefined, fallback?: string): PlaceKind {
  return (
    (value && KIND_BY_OSM_VALUE[value]) || (fallback && KIND_BY_OSM_VALUE[fallback]) || 'district'
  );
}

const OSM_TYPE_BY_LETTER: Record<string, OsmType> = { N: 'node', W: 'way', R: 'relation' };
const LETTER_BY_OSM_TYPE: Record<OsmType, string> = { node: 'N', way: 'W', relation: 'R' };

interface PhotonFeature {
  geometry?: { coordinates?: [number, number] };
  properties?: Record<string, unknown>;
}

export async function searchPlaces(request: Request, deps: Deps): Promise<Response> {
  await requireUploader(request, deps);
  const query = (new URL(request.url).searchParams.get('q') ?? '').trim();
  if (query.length < 2 || query.length > 200) {
    throw new HttpError(400, 'invalid_query');
  }

  const upstream = new URL(PHOTON_URL);
  upstream.searchParams.set('q', query);
  upstream.searchParams.set('limit', '8');
  const body = (await fetchUpstream(deps, upstream)) as { features?: PhotonFeature[] };

  const results = (body.features ?? []).flatMap((feature) => {
    const props = feature.properties ?? {};
    const osmType = OSM_TYPE_BY_LETTER[String(props.osm_type)];
    const [lng, lat] = feature.geometry?.coordinates ?? [];
    if (
      !osmType ||
      typeof props.osm_id !== 'number' ||
      typeof lng !== 'number' ||
      typeof lat !== 'number'
    ) {
      return [];
    }
    const name = typeof props.name === 'string' ? props.name : '';
    const context = [props.state, props.country]
      .filter((part): part is string => typeof part === 'string' && part !== '' && part !== name)
      .join(', ');
    return [
      {
        name,
        context,
        osmType,
        osmId: props.osm_id,
        kind: placeKindFor(stringOrUndefined(props.osm_value), stringOrUndefined(props.type)),
        lng,
        lat,
        hasBoundary: osmType !== 'node',
      },
    ];
  });
  return json({ results });
}

interface NominatimFeature {
  properties?: {
    osm_type?: string;
    osm_id?: number;
    addresstype?: string;
    type?: string;
    name?: string;
    namedetails?: Record<string, string>;
  };
  geometry?: { type?: string };
}

export async function placeBoundary(request: Request, deps: Deps): Promise<Response> {
  await requireUploader(request, deps);
  const params = new URL(request.url).searchParams;
  const osmType = params.get('osm_type');
  const osmIdText = params.get('osm_id') ?? '';
  if (osmType !== 'node' && osmType !== 'way' && osmType !== 'relation') {
    throw new HttpError(400, 'invalid_osm_type');
  }
  if (!/^\d{1,15}$/.test(osmIdText)) {
    throw new HttpError(400, 'invalid_osm_id');
  }
  const osmId = Number(osmIdText);

  const upstream = new URL(NOMINATIM_LOOKUP_URL);
  upstream.searchParams.set('osm_ids', `${LETTER_BY_OSM_TYPE[osmType]}${osmId}`);
  upstream.searchParams.set('format', 'geojson');
  upstream.searchParams.set('polygon_geojson', '1');
  // ~50 m simplification keeps big provinces small enough to send to a phone.
  upstream.searchParams.set('polygon_threshold', '0.0005');
  upstream.searchParams.set('namedetails', '1');
  const body = (await fetchUpstream(deps, upstream)) as { features?: NominatimFeature[] };

  const feature = body.features?.[0];
  const geometryType = feature?.geometry?.type;
  if (!feature || (geometryType !== 'Polygon' && geometryType !== 'MultiPolygon')) {
    throw new HttpError(404, 'no_boundary');
  }
  const props = feature.properties ?? {};
  const names = props.namedetails ?? {};
  return json({
    osmType,
    osmId,
    nameEn: names['name:en'] ?? props.name ?? null,
    nameFa: names['name:fa'] ?? null,
    kind: placeKindFor(props.addresstype, props.type),
    geojson: feature.geometry,
  });
}

async function fetchUpstream(deps: Deps, url: URL): Promise<unknown> {
  let response: Response;
  try {
    response = await deps.geoFetch(url.toString(), {
      headers: { 'user-agent': GEO_USER_AGENT, accept: 'application/json' },
    });
  } catch {
    throw new HttpError(502, 'geocoder_unavailable');
  }
  if (!response.ok) {
    await response.body?.cancel();
    throw new HttpError(502, 'geocoder_unavailable');
  }
  return response.json();
}

function stringOrUndefined(value: unknown): string | undefined {
  return typeof value === 'string' ? value : undefined;
}
