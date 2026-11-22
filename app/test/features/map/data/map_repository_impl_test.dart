import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/lookups/data/datasources/lookup_remote_data_source.dart';
import 'package:naney/features/map/data/datasources/map_remote_data_source.dart';
import 'package:naney/features/map/data/repositories/map_repository_impl.dart';
import 'package:naney/features/map/domain/entities/map_bounds.dart';
import 'package:naney/features/map/domain/entities/map_pin.dart';
import 'package:naney/features/map/domain/entities/place_area.dart';
import 'package:naney/features/map/domain/entities/recording_filter.dart';

class _MockRemote extends Mock implements MapRemoteDataSource {}

const MapBounds bounds = MapBounds(south: 37.9, west: 46.0, north: 38.3, east: 46.6);

void main() {
  late _MockRemote remote;
  late MapRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(bounds);
    registerFallbackValue(const RecordingFilter());
  });

  setUp(() {
    remote = _MockRemote();
    repository = MapRepositoryImpl(remote);
  });

  test('maps pins', () async {
    when(() => remote.fetchPins(bounds, const RecordingFilter())).thenAnswer(
      (_) async => <JsonRow>[
        <String, Object?>{
          'place_id': 1,
          'name_en': 'Tabriz',
          'name_fa': 'تبریز',
          'lng': 46.29,
          'lat': 38.08,
          'recording_count': 3,
        },
      ],
    );
    expect(await repository.pinsIn(bounds, const RecordingFilter()), const <MapPin>[
      MapPin(
        placeId: 1,
        name: LocalizedName(en: 'Tabriz', fa: 'تبریز'),
        position: LatLng(38.08, 46.29),
        recordingCount: 3,
      ),
    ]);
  });

  test('maps areas from GeoJSON', () async {
    when(() => remote.fetchAreas(bounds)).thenAnswer(
      (_) async => <JsonRow>[
        <String, Object?>{
          'place_id': 1,
          'geojson': <String, Object?>{
            'type': 'MultiPolygon',
            'coordinates': <Object?>[
              <Object?>[
                <Object?>[
                  <Object?>[46.2, 38.0],
                  <Object?>[46.4, 38.0],
                  <Object?>[46.4, 38.1],
                  <Object?>[46.2, 38.0],
                ],
              ],
            ],
          },
        },
      ],
    );
    final List<PlaceArea> areas = await repository.areasIn(bounds);
    expect(areas.single.placeId, 1);
    expect(areas.single.polygons.single.outer, hasLength(4));
  });

  test('malformed rows become UnexpectedFailure rather than crashing the UI', () async {
    when(() => remote.fetchPins(any(), any())).thenAnswer(
      (_) async => <JsonRow>[
        <String, Object?>{'place_id': 'oops'},
      ],
    );
    await expectLater(
      repository.pinsIn(bounds, const RecordingFilter()),
      throwsA(isA<UnexpectedFailure>()),
    );
  });

  group('mapPinsParams', () {
    test('sends nulls for an empty filter', () {
      expect(mapPinsParams(bounds, const RecordingFilter()), <String, Object?>{
        'p_min_lng': 46.0,
        'p_min_lat': 37.9,
        'p_max_lng': 46.6,
        'p_max_lat': 38.3,
        'p_culture_ids': null,
        'p_language_ids': null,
        'p_kinds': null,
        'p_tag': null,
      });
    });

    test('sends sorted ids, kind names and a trimmed tag', () {
      final Map<String, Object?> params = mapPinsParams(
        bounds,
        const RecordingFilter(
          cultureIds: <int>{3, 1},
          languageIds: <int>{2},
          kinds: <RecordingKind>{RecordingKind.poem},
          tag: '  sleep ',
        ),
      );
      expect(params['p_culture_ids'], <int>[1, 3]);
      expect(params['p_language_ids'], <int>[2]);
      expect(params['p_kinds'], <String>['poem']);
      expect(params['p_tag'], 'sleep');
    });
  });
}
