import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/features/upload/data/datasources/audio_recorder_service.dart';
import 'package:naney/features/upload/domain/entities/place_choice.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';
import 'package:naney/features/upload/domain/repositories/upload_repositories.dart';
import 'package:naney/features/upload/presentation/cubit/area_draw_cubit.dart';
import 'package:naney/features/upload/presentation/cubit/place_search_cubit.dart';
import 'package:naney/features/upload/presentation/cubit/recorder_cubit.dart';

class _Places extends Mock implements PlaceLookupRepository {}

class _Recorder extends Mock implements AudioRecorderService {}

const PlaceSearchResult tabriz = PlaceSearchResult(
  name: 'Tabriz',
  context: 'Iran',
  osmType: 'relation',
  osmId: 1,
  kind: 'city',
  position: LatLng(38, 46),
  hasBoundary: true,
);
const PlaceSearchResult hamlet = PlaceSearchResult(
  name: 'Hamlet',
  context: '',
  osmType: 'node',
  osmId: 2,
  kind: 'village',
  position: LatLng(38, 46),
  hasBoundary: false,
);
const OsmPlaceChoice tabrizArea = OsmPlaceChoice(
  osmType: 'relation',
  osmId: 1,
  kind: 'city',
  nameEn: 'Tabriz',
  nameFa: 'تبریز',
  polygons: <AreaPolygon>[],
);

void main() {
  setUpAll(() => registerFallbackValue(tabriz));

  group('PlaceSearchCubit', () {
    late _Places places;
    setUp(() => places = _Places());

    blocTest<PlaceSearchCubit, PlaceSearchState>(
      'debounces typing into one search',
      build: () {
        when(() => places.search('Tabriz')).thenAnswer((_) async => <PlaceSearchResult>[tabriz]);
        return PlaceSearchCubit(places, debounce: const Duration(milliseconds: 20));
      },
      act:
          (PlaceSearchCubit cubit) =>
              cubit
                ..queryChanged('Tab')
                ..queryChanged('Tabr')
                ..queryChanged('Tabriz'),
      wait: const Duration(milliseconds: 60),
      expect:
          () => <PlaceSearchState>[
            const PlaceSearchState(status: SearchStatus.searching),
            const PlaceSearchState(
              status: SearchStatus.ready,
              results: <PlaceSearchResult>[tabriz],
            ),
          ],
      verify: (_) => verify(() => places.search(any())).called(1),
    );

    blocTest<PlaceSearchCubit, PlaceSearchState>(
      'clears results for very short queries',
      build: () => PlaceSearchCubit(places, debounce: Duration.zero),
      seed:
          () => const PlaceSearchState(
            status: SearchStatus.ready,
            results: <PlaceSearchResult>[tabriz],
          ),
      act: (PlaceSearchCubit cubit) => cubit.queryChanged('T'),
      expect: () => <PlaceSearchState>[const PlaceSearchState()],
    );

    blocTest<PlaceSearchCubit, PlaceSearchState>(
      'fetches the boundary of a chosen place',
      build: () {
        when(() => places.boundary(tabriz)).thenAnswer((_) async => tabrizArea);
        return PlaceSearchCubit(places);
      },
      act: (PlaceSearchCubit cubit) => cubit.choose(tabriz),
      expect:
          () => <PlaceSearchState>[
            const PlaceSearchState(selected: tabriz, boundaryStatus: BoundaryStatus.loading),
            const PlaceSearchState(
              selected: tabriz,
              boundaryStatus: BoundaryStatus.found,
              boundary: tabrizArea,
            ),
          ],
    );

    blocTest<PlaceSearchCubit, PlaceSearchState>(
      'places without an OSM area go straight to "missing" (so the user can draw)',
      build: () => PlaceSearchCubit(places),
      act: (PlaceSearchCubit cubit) => cubit.choose(hamlet),
      expect:
          () => <PlaceSearchState>[
            const PlaceSearchState(selected: hamlet, boundaryStatus: BoundaryStatus.missing),
          ],
      verify: (_) => verifyNever(() => places.boundary(any())),
    );

    blocTest<PlaceSearchCubit, PlaceSearchState>(
      'reports boundary failures',
      build: () {
        when(() => places.boundary(tabriz)).thenThrow(const NetworkFailure());
        return PlaceSearchCubit(places);
      },
      act: (PlaceSearchCubit cubit) => cubit.choose(tabriz),
      skip: 1,
      expect:
          () => <PlaceSearchState>[
            const PlaceSearchState(selected: tabriz, boundaryStatus: BoundaryStatus.failure),
          ],
    );
  });

  group('AreaDrawCubit', () {
    test('needs three points for an area and supports undo', () {
      final AreaDrawCubit cubit =
          AreaDrawCubit()
            ..addPoint(const LatLng(1, 1))
            ..addPoint(const LatLng(1, 2));
      expect(cubit.toPolygon(), isNull);
      cubit.addPoint(const LatLng(2, 2));
      expect(cubit.toPolygon()?.outer, hasLength(3));
      cubit.undo();
      expect(cubit.isComplete, isFalse);
      cubit.clear();
      expect(cubit.state.points, isEmpty);
    });

    test('a drawn place needs a name', () {
      final AreaDrawCubit cubit =
          AreaDrawCubit()
            ..addPoint(const LatLng(1, 1))
            ..addPoint(const LatLng(1, 2))
            ..addPoint(const LatLng(2, 2));
      expect(cubit.toPlace(), isNull);
      cubit.setNames(nameFa: ' روستاهای مراغه ');
      expect(cubit.toPlace()?.nameFa, 'روستاهای مراغه');
      expect(cubit.toPlace()?.nameEn, isNull);
    });
  });

  group('RecorderCubit', () {
    late _Recorder recorder;
    late DateTime now;
    final UploadSource recording = UploadSource.bytes(
      name: 'recording.webm',
      mime: 'audio/webm',
      bytes: Uint8List(3),
      durationMs: 2000,
    );

    setUp(() {
      recorder = _Recorder();
      now = DateTime(2026);
      when(() => recorder.requestPermission()).thenAnswer((_) async => true);
      when(() => recorder.start()).thenAnswer((_) async {});
      when(() => recorder.dispose()).thenAnswer((_) async {});
      when(() => recorder.cancel()).thenAnswer((_) async {});
    });

    RecorderCubit build() =>
        RecorderCubit(recorder, tick: const Duration(milliseconds: 5), clock: () => now);

    blocTest<RecorderCubit, RecorderState>(
      'records and returns the file with its duration',
      build: () {
        when(() => recorder.stop(durationMs: 2000)).thenAnswer((_) async => recording);
        return build();
      },
      act: (RecorderCubit cubit) async {
        await cubit.start();
        now = now.add(const Duration(seconds: 2));
        await cubit.stop();
      },
      expect:
          () => <RecorderState>[
            const RecorderRecording(Duration.zero),
            RecorderFinished(recording),
          ],
    );

    blocTest<RecorderCubit, RecorderState>(
      'explains a denied microphone permission',
      build: () {
        when(() => recorder.requestPermission()).thenAnswer((_) async => false);
        return build();
      },
      act: (RecorderCubit cubit) => cubit.start(),
      expect: () => <RecorderState>[const RecorderPermissionDenied()],
      verify: (_) => verifyNever(() => recorder.start()),
    );

    blocTest<RecorderCubit, RecorderState>(
      'discarding a running recording cancels it',
      build: build,
      act: (RecorderCubit cubit) async {
        await cubit.start();
        await cubit.discard();
      },
      expect: () => <RecorderState>[const RecorderRecording(Duration.zero), const RecorderIdle()],
      verify: (_) => verify(() => recorder.cancel()).called(1),
    );

    blocTest<RecorderCubit, RecorderState>(
      'an empty recording is a failure',
      build: () {
        when(
          () => recorder.stop(durationMs: any(named: 'durationMs')),
        ).thenAnswer((_) async => null);
        return build();
      },
      act: (RecorderCubit cubit) async {
        await cubit.start();
        await cubit.stop();
      },
      expect: () => <RecorderState>[const RecorderRecording(Duration.zero), const RecorderFailed()],
    );
  });
}
