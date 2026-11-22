import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/features/upload/data/datasources/worker_api.dart';
import 'package:naney/features/upload/data/repositories/place_lookup_repository_impl.dart';
import 'package:naney/features/upload/domain/entities/place_choice.dart';

class _Api extends Mock implements WorkerApi {}

class _Store extends Mock implements PlaceStore {}

const PlaceSearchResult tabriz = PlaceSearchResult(
  name: 'Tabriz',
  context: 'East Azerbaijan, Iran',
  osmType: 'relation',
  osmId: 123,
  kind: 'city',
  position: LatLng(38.08, 46.29),
  hasBoundary: true,
);

void main() {
  late _Api api;
  late _Store store;
  late PlaceLookupRepositoryImpl repository;

  setUp(() {
    api = _Api();
    store = _Store();
    repository = PlaceLookupRepositoryImpl(api, store);
  });

  test('maps search results', () async {
    when(() => api.searchPlaces('Tabriz')).thenAnswer(
      (_) async => <JsonMap>[
        <String, Object?>{
          'name': 'Tabriz',
          'context': 'East Azerbaijan, Iran',
          'osmType': 'relation',
          'osmId': 123,
          'kind': 'city',
          'lng': 46.29,
          'lat': 38.08,
          'hasBoundary': true,
        },
      ],
    );
    expect(await repository.search(' Tabriz '), <PlaceSearchResult>[tabriz]);
  });

  test('does not search for fewer than two characters', () async {
    expect(await repository.search(' T '), isEmpty);
    verifyZeroInteractions(api);
  });

  test('maps a boundary into an OSM place choice', () async {
    when(() => api.boundary(osmType: 'relation', osmId: 123)).thenAnswer(
      (_) async => <String, Object?>{
        'osmType': 'relation',
        'osmId': 123,
        'nameEn': 'Tabriz',
        'nameFa': 'تبریز',
        'kind': 'city',
        'geojson': <String, Object?>{
          'type': 'Polygon',
          'coordinates': <Object?>[
            <Object?>[
              <Object?>[46.2, 38.0],
              <Object?>[46.4, 38.0],
              <Object?>[46.4, 38.1],
              <Object?>[46.2, 38.0],
            ],
          ],
        },
      },
    );
    final OsmPlaceChoice? choice = await repository.boundary(tabriz);
    expect(choice?.nameFa, 'تبریز');
    expect(choice?.polygons.single.outer, hasLength(4));
  });

  test('payloads keep the OSM reference so the database reuses existing places', () {
    const OsmPlaceChoice osm = OsmPlaceChoice(
      osmType: 'relation',
      osmId: 123,
      kind: 'city',
      nameEn: 'Tabriz',
      nameFa: 'تبریز',
      polygons: <AreaPolygon>[
        AreaPolygon(outer: <LatLng>[LatLng(1, 1), LatLng(1, 2), LatLng(2, 2)]),
      ],
    );
    final Map<String, Object?> payload = placePayload(osm);
    expect(payload['osm_type'], 'relation');
    expect(payload['osm_id'], 123);
    expect(payload['kind'], 'city');
    expect((payload['geojson']! as Map<String, Object?>)['type'], 'MultiPolygon');
  });

  test('drawn areas are saved as custom places', () async {
    when(() => store.upsert(any())).thenAnswer((_) async => 5);
    const DrawnPlaceChoice drawn = DrawnPlaceChoice(
      nameEn: null,
      nameFa: 'روستاهای مراغه',
      polygons: <AreaPolygon>[
        AreaPolygon(outer: <LatLng>[LatLng(1, 1), LatLng(1, 2), LatLng(2, 2)]),
      ],
    );
    expect(await repository.save(drawn), 5);
    final Map<String, Object?> payload =
        verify(() => store.upsert(captureAny())).captured.single as Map<String, Object?>;
    expect(payload['kind'], 'custom');
    expect(payload.containsKey('osm_id'), isFalse);
    expect(payload['name_fa'], 'روستاهای مراغه');
  });
}
