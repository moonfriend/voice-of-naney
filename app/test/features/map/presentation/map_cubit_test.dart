import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/map/domain/entities/map_bounds.dart';
import 'package:naney/features/map/domain/entities/map_pin.dart';
import 'package:naney/features/map/domain/entities/place_area.dart';
import 'package:naney/features/map/domain/entities/recording_filter.dart';
import 'package:naney/features/map/domain/repositories/map_repository.dart';
import 'package:naney/features/map/presentation/cubit/map_cubit.dart';

class _MockRepo extends Mock implements MapRepository {}

const MapBounds iran = MapBounds(south: 25, west: 44, north: 40, east: 63);
const MapBounds tabriz = MapBounds(south: 37.9, west: 46.0, north: 38.3, east: 46.6);
const MapPin tabrizPin = MapPin(
  placeId: 1,
  name: LocalizedName(en: 'Tabriz', fa: 'تبریز'),
  position: LatLng(38.08, 46.29),
  recordingCount: 2,
);
const PlaceArea tabrizArea = PlaceArea(
  placeId: 1,
  polygons: <AreaPolygon>[
    AreaPolygon(outer: <LatLng>[LatLng(38, 46.2), LatLng(38, 46.4), LatLng(38.1, 46.4)]),
  ],
);
const PlaceArea unrelatedArea = PlaceArea(placeId: 99, polygons: <AreaPolygon>[]);
const RecordingFilter poemsOnly = RecordingFilter(tag: 'night');

void main() {
  late _MockRepo repo;

  setUpAll(() {
    registerFallbackValue(iran);
    registerFallbackValue(const RecordingFilter());
  });

  setUp(() {
    repo = _MockRepo();
    when(() => repo.pinsIn(any(), any())).thenAnswer((_) async => <MapPin>[tabrizPin]);
    when(() => repo.areasIn(any())).thenAnswer((_) async => <PlaceArea>[tabrizArea, unrelatedArea]);
  });

  MapCubit build() => MapCubit(repo, debounce: Duration.zero);

  blocTest<MapCubit, MapState>(
    'loads pins (but no outlines) when zoomed out',
    build: build,
    act: (MapCubit cubit) => cubit.viewportChanged(iran, 5),
    wait: const Duration(milliseconds: 20),
    expect:
        () => <MapState>[
          const MapState(status: MapStatus.loading),
          const MapState(status: MapStatus.ready, pins: <MapPin>[tabrizPin]),
        ],
    verify: (_) => verifyNever(() => repo.areasIn(any())),
  );

  blocTest<MapCubit, MapState>(
    'also loads outlines when zoomed in, keeping only areas that have pins',
    build: build,
    act: (MapCubit cubit) => cubit.viewportChanged(tabriz, MapCubit.areaZoomThreshold),
    wait: const Duration(milliseconds: 20),
    expect:
        () => <MapState>[
          const MapState(status: MapStatus.loading),
          const MapState(
            status: MapStatus.ready,
            pins: <MapPin>[tabrizPin],
            areas: <PlaceArea>[tabrizArea],
          ),
        ],
  );

  test('debounces rapid viewport changes into one request', () async {
    final MapCubit cubit = MapCubit(repo, debounce: const Duration(milliseconds: 30));
    cubit
      ..viewportChanged(iran, 5)
      ..viewportChanged(iran, 5.5)
      ..viewportChanged(tabriz, 6);
    await Future<void>.delayed(const Duration(milliseconds: 80));
    verify(() => repo.pinsIn(tabriz, const RecordingFilter())).called(1);
    verifyNoMoreInteractions(repo);
    await cubit.close();
  });

  blocTest<MapCubit, MapState>(
    'reloads immediately with a new filter and clears the selection',
    build: build,
    seed:
        () =>
            const MapState(status: MapStatus.ready, pins: <MapPin>[tabrizPin], selectedPlaceId: 1),
    act: (MapCubit cubit) async {
      cubit.viewportChanged(iran, 5);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await cubit.filterChanged(poemsOnly);
    },
    skip: 2,
    expect:
        () => <MapState>[
          const MapState(status: MapStatus.ready, pins: <MapPin>[tabrizPin], filter: poemsOnly),
          const MapState(status: MapStatus.loading, pins: <MapPin>[tabrizPin], filter: poemsOnly),
          const MapState(status: MapStatus.ready, pins: <MapPin>[tabrizPin], filter: poemsOnly),
        ],
    verify: (_) => verify(() => repo.pinsIn(iran, poemsOnly)).called(1),
  );

  blocTest<MapCubit, MapState>(
    'reports failures and recovers on retry',
    build: () {
      int calls = 0;
      when(() => repo.pinsIn(any(), any())).thenAnswer((_) async {
        calls += 1;
        if (calls == 1) {
          throw const NetworkFailure();
        }
        return <MapPin>[tabrizPin];
      });
      return build();
    },
    act: (MapCubit cubit) async {
      cubit.viewportChanged(iran, 5);
      await Future<void>.delayed(const Duration(milliseconds: 10));
      await cubit.retry();
    },
    expect:
        () => <MapState>[
          const MapState(status: MapStatus.loading),
          const MapState(status: MapStatus.failure, failure: NetworkFailure()),
          const MapState(status: MapStatus.loading),
          const MapState(status: MapStatus.ready, pins: <MapPin>[tabrizPin]),
        ],
  );

  test('ignores a slow, outdated response that arrives after a newer one', () async {
    final Completer<List<MapPin>> slow = Completer<List<MapPin>>();
    when(() => repo.pinsIn(iran, any())).thenAnswer((_) => slow.future);
    when(() => repo.pinsIn(tabriz, any())).thenAnswer((_) async => <MapPin>[tabrizPin]);
    final MapCubit cubit = build();

    cubit.viewportChanged(iran, 5);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    cubit.viewportChanged(tabriz, 6);
    await Future<void>.delayed(const Duration(milliseconds: 5));
    slow.complete(<MapPin>[]);
    await Future<void>.delayed(const Duration(milliseconds: 5));

    expect(cubit.state.pins, <MapPin>[tabrizPin]);
    await cubit.close();
  });

  blocTest<MapCubit, MapState>(
    'selects and deselects a place',
    build: build,
    act:
        (MapCubit cubit) =>
            cubit
              ..selectPlace(1)
              ..selectPlace(null),
    expect: () => <MapState>[const MapState(selectedPlaceId: 1), const MapState()],
  );

  test('does nothing before the first viewport is known', () async {
    final MapCubit cubit = build();
    await cubit.retry();
    verifyZeroInteractions(repo);
    await cubit.close();
  });
}
