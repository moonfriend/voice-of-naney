import 'package:injectable/injectable.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/geo/area_polygon.dart';
import '../../../../core/network/api_errors.dart';
import '../../domain/entities/place_choice.dart';
import '../../domain/repositories/upload_repositories.dart';
import '../datasources/worker_api.dart';

/// Saves a place through the `upsert_place` RPC (separated for testing).
abstract interface class PlaceStore {
  Future<int> upsert(Map<String, Object?> payload);
}

@LazySingleton(as: PlaceStore)
class SupabasePlaceStore implements PlaceStore {
  SupabasePlaceStore(this._client);

  final SupabaseClient _client;

  @override
  Future<int> upsert(Map<String, Object?> payload) => guardRemoteCall(() async {
    final Object? id = await _client.rpc<Object?>(
      'upsert_place',
      params: <String, Object?>{'p': payload},
    );
    return (id! as num).toInt();
  });
}

@LazySingleton(as: PlaceLookupRepository)
class PlaceLookupRepositoryImpl implements PlaceLookupRepository {
  PlaceLookupRepositoryImpl(this._api, this._store);

  final WorkerApi _api;
  final PlaceStore _store;

  @override
  Future<List<PlaceSearchResult>> search(String query) => guardApiCall(() async {
    final String trimmed = query.trim();
    if (trimmed.length < 2) {
      return const <PlaceSearchResult>[];
    }
    return (await _api.searchPlaces(trimmed)).map(placeSearchResultFromJson).toList();
  });

  @override
  Future<OsmPlaceChoice?> boundary(PlaceSearchResult result) => guardApiCall(() async {
    final JsonMap? json = await _api.boundary(osmType: result.osmType, osmId: result.osmId);
    if (json == null) {
      return null;
    }
    return OsmPlaceChoice(
      osmType: json['osmType']! as String,
      osmId: (json['osmId']! as num).toInt(),
      kind: json['kind']! as String,
      nameEn: (json['nameEn'] as String?) ?? result.name,
      nameFa: json['nameFa'] as String?,
      polygons: polygonsFromGeoJson(json['geojson']! as JsonMap),
    );
  });

  @override
  Future<int> save(PlaceChoice place) => _store.upsert(placePayload(place));
}

PlaceSearchResult placeSearchResultFromJson(JsonMap json) => PlaceSearchResult(
  name: json['name']! as String,
  context: json['context'] as String? ?? '',
  osmType: json['osmType']! as String,
  osmId: (json['osmId']! as num).toInt(),
  kind: json['kind']! as String,
  position: LatLng((json['lat']! as num).toDouble(), (json['lng']! as num).toDouble()),
  hasBoundary: json['hasBoundary'] as bool? ?? false,
);

/// The `upsert_place` payload: OSM places carry their reference so they are reused.
Map<String, Object?> placePayload(PlaceChoice place) => <String, Object?>{
  'name_en': place.nameEn,
  'name_fa': place.nameFa,
  'geojson': polygonsToGeoJson(place.polygons),
  ...switch (place) {
    OsmPlaceChoice() => <String, Object?>{
      'kind': place.kind,
      'osm_type': place.osmType,
      'osm_id': place.osmId,
    },
    DrawnPlaceChoice() => <String, Object?>{'kind': 'custom'},
  },
};
