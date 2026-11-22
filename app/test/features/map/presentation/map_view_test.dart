import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/media_type.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/lookups/presentation/cubit/lookups_cubit.dart';
import 'package:naney/features/map/domain/entities/map_bounds.dart';
import 'package:naney/features/map/domain/entities/map_pin.dart';
import 'package:naney/features/map/domain/entities/recording_filter.dart';
import 'package:naney/features/map/presentation/cubit/map_cubit.dart';
import 'package:naney/features/map/presentation/pages/map_page.dart';
import 'package:naney/features/recordings/domain/entities/recording_summary.dart';
import 'package:naney/features/recordings/presentation/cubit/place_recordings_cubit.dart';

import '../../../helpers/pump_localized.dart';

class _MockMapCubit extends MockCubit<MapState> implements MapCubit {}

class _MockLookupsCubit extends MockCubit<LookupsState> implements LookupsCubit {}

class _MockPlaceRecordingsCubit extends MockCubit<PlaceRecordingsState>
    implements PlaceRecordingsCubit {}

const MapPin tabriz = MapPin(
  placeId: 1,
  name: LocalizedName(en: 'Tabriz', fa: 'تبریز'),
  position: LatLng(38.08, 46.29),
  recordingCount: 3,
);
const MapPin shiraz = MapPin(
  placeId: 2,
  name: LocalizedName(en: 'Shiraz', fa: 'شیراز'),
  position: LatLng(29.6, 52.5),
  recordingCount: 5,
);

void main() {
  late _MockMapCubit mapCubit;
  late _MockLookupsCubit lookupsCubit;
  late _MockPlaceRecordingsCubit placeCubit;

  setUpAll(() {
    registerFallbackValue(const MapBounds(south: 0, west: 0, north: 1, east: 1));
    registerFallbackValue(const RecordingFilter());
  });

  setUp(() {
    mapCubit = _MockMapCubit();
    lookupsCubit = _MockLookupsCubit();
    placeCubit = _MockPlaceRecordingsCubit();
    when(() => lookupsCubit.state).thenReturn(const LookupsState(status: LookupsStatus.ready));
    when(
      () => placeCubit.state,
    ).thenReturn(const PlaceRecordingsState(status: PlaceRecordingsStatus.loading));
    when(() => placeCubit.load(any(), any())).thenAnswer((_) async {});
    when(() => mapCubit.retry()).thenAnswer((_) async {});
    when(() => mapCubit.filterChanged(any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, MapState state) async {
    when(() => mapCubit.state).thenReturn(state);
    await pumpLocalized(
      tester,
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<MapCubit>.value(value: mapCubit),
          BlocProvider<LookupsCubit>.value(value: lookupsCubit),
          BlocProvider<PlaceRecordingsCubit>.value(value: placeCubit),
        ],
        child: const MapView(mapTilerKey: ''),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }

  testWidgets('reports the initial viewport once the map is ready', (WidgetTester tester) async {
    await pump(tester, const MapState());
    verify(
      () => mapCubit.viewportChanged(any(), MapView.initialZoom),
    ).called(greaterThanOrEqualTo(1));
  });

  testWidgets('shows a badge with the recording count for each place', (WidgetTester tester) async {
    await pump(tester, const MapState(status: MapStatus.ready, pins: <MapPin>[tabriz, shiraz]));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
  });

  testWidgets('tapping a place selects it', (WidgetTester tester) async {
    await pump(tester, const MapState(status: MapStatus.ready, pins: <MapPin>[tabriz, shiraz]));
    await tester.tap(find.text('3'));
    verify(() => mapCubit.selectPlace(1)).called(1);
  });

  testWidgets('a selected place shows its recordings', (WidgetTester tester) async {
    when(() => placeCubit.state).thenReturn(
      const PlaceRecordingsState(
        status: PlaceRecordingsStatus.ready,
        recordings: <RecordingSummary>[
          RecordingSummary(
            id: '11111111-1111-4111-8111-111111111111',
            title: 'Lay lay',
            kind: RecordingKind.lullaby,
            mediaType: MediaType.audio,
            performerName: 'Naney',
          ),
        ],
      ),
    );
    await pump(
      tester,
      const MapState(status: MapStatus.ready, pins: <MapPin>[tabriz], selectedPlaceId: 1),
    );

    expect(find.text('Tabriz'), findsOneWidget);
    expect(find.text('3 recordings'), findsOneWidget);
    expect(find.text('Lay lay'), findsOneWidget);
    expect(find.text('Lullaby · Naney'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    verify(() => mapCubit.selectPlace(null)).called(1);
  });

  testWidgets('selecting a place loads its recordings with the active filter', (
    WidgetTester tester,
  ) async {
    const RecordingFilter filter = RecordingFilter(tag: 'sleep');
    whenListen(
      mapCubit,
      Stream<MapState>.fromIterable(<MapState>[
        const MapState(
          status: MapStatus.ready,
          pins: <MapPin>[tabriz],
          filter: filter,
          selectedPlaceId: 1,
        ),
      ]),
      initialState: const MapState(status: MapStatus.ready, pins: <MapPin>[tabriz], filter: filter),
    );
    await pumpLocalized(
      tester,
      MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<MapCubit>.value(value: mapCubit),
          BlocProvider<LookupsCubit>.value(value: lookupsCubit),
          BlocProvider<PlaceRecordingsCubit>.value(value: placeCubit),
        ],
        child: const MapView(mapTilerKey: ''),
      ),
    );
    await tester.pump(const Duration(milliseconds: 100));
    verify(() => placeCubit.load(1, filter)).called(1);
  });

  testWidgets('a failure shows a retry banner', (WidgetTester tester) async {
    await pump(tester, const MapState(status: MapStatus.failure, failure: NetworkFailure()));
    expect(find.text('Could not load the map. Please check your connection.'), findsOneWidget);
    await tester.tap(find.text('Retry'));
    verify(() => mapCubit.retry()).called(1);
  });

  testWidgets('the filter button shows how many filters are active', (WidgetTester tester) async {
    await pump(
      tester,
      const MapState(
        status: MapStatus.ready,
        filter: RecordingFilter(kinds: <RecordingKind>{RecordingKind.poem}, tag: 'x'),
      ),
    );
    expect(find.text('Filters (2)'), findsOneWidget);
  });

  testWidgets('applying the filter sheet updates the map filter', (WidgetTester tester) async {
    await pump(tester, const MapState(status: MapStatus.ready));
    await tester.tap(find.text('Filters'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Poem'));
    await tester.pump();
    await tester.tap(find.text('Show results'));
    await tester.pumpAndSettle();
    verify(
      () =>
          mapCubit.filterChanged(const RecordingFilter(kinds: <RecordingKind>{RecordingKind.poem})),
    ).called(1);
  });

  testWidgets('says when the map background is not configured', (WidgetTester tester) async {
    await pump(tester, const MapState());
    expect(find.text('Map background is not configured.'), findsOneWidget);
  });
}
