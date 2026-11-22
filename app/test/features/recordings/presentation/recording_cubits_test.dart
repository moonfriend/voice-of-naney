import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/media_type.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/features/map/domain/entities/recording_filter.dart';
import 'package:naney/features/recordings/domain/entities/recording_detail.dart';
import 'package:naney/features/recordings/domain/entities/recording_summary.dart';
import 'package:naney/features/recordings/domain/repositories/recording_repository.dart';
import 'package:naney/features/recordings/presentation/cubit/place_recordings_cubit.dart';
import 'package:naney/features/recordings/presentation/cubit/recording_detail_cubit.dart';

class _MockRepo extends Mock implements RecordingRepository {}

const String recId = '11111111-1111-4111-8111-111111111111';

final RecordingDetail detail = RecordingDetail(
  id: recId,
  title: 'Lay lay',
  kind: RecordingKind.lullaby,
  place: const RecordingPlace(id: 1, name: LocalizedName(en: 'Tabriz', fa: 'تبریز')),
  cultures: const <CultureEntry>[CultureEntry(otherText: 'Qarapapaq')],
  revisions: <MediaRevision>[
    MediaRevision(
      revisionNo: 0,
      mediaType: MediaType.audio,
      url: Uri.parse('https://x/media/a.mp3'),
      mime: 'audio/mpeg',
    ),
    MediaRevision(
      revisionNo: 1,
      mediaType: MediaType.audio,
      url: Uri.parse('https://x/media/b.mp3'),
      mime: 'audio/mpeg',
    ),
  ],
  createdAt: DateTime.utc(2026, 11, 22),
);

const RecordingSummary summary = RecordingSummary(
  id: recId,
  title: 'Lay lay',
  kind: RecordingKind.lullaby,
  mediaType: MediaType.audio,
);

void main() {
  late _MockRepo repo;

  setUpAll(() => registerFallbackValue(const RecordingFilter()));
  setUp(() => repo = _MockRepo());

  group('RecordingDetailCubit', () {
    blocTest<RecordingDetailCubit, RecordingDetailState>(
      'loads and selects the newest revision',
      build: () {
        when(() => repo.recordingDetail(recId)).thenAnswer((_) async => detail);
        return RecordingDetailCubit(repo);
      },
      act: (RecordingDetailCubit cubit) => cubit.load(recId),
      expect:
          () => <RecordingDetailState>[
            const RecordingDetailLoading(),
            RecordingDetailLoaded(detail: detail, selectedRevisionNo: 1),
          ],
    );

    blocTest<RecordingDetailCubit, RecordingDetailState>(
      'switches to the original',
      build: () => RecordingDetailCubit(repo),
      seed: () => RecordingDetailLoaded(detail: detail, selectedRevisionNo: 1),
      act: (RecordingDetailCubit cubit) => cubit.selectRevision(0),
      expect:
          () => <RecordingDetailState>[
            RecordingDetailLoaded(detail: detail, selectedRevisionNo: 0),
          ],
    );

    blocTest<RecordingDetailCubit, RecordingDetailState>(
      'ignores unknown revision numbers',
      build: () => RecordingDetailCubit(repo),
      seed: () => RecordingDetailLoaded(detail: detail, selectedRevisionNo: 1),
      act: (RecordingDetailCubit cubit) => cubit.selectRevision(7),
      expect: () => <RecordingDetailState>[],
    );

    blocTest<RecordingDetailCubit, RecordingDetailState>(
      'reports not found separately from other failures',
      build: () {
        when(() => repo.recordingDetail(recId)).thenThrow(const NotFoundFailure());
        return RecordingDetailCubit(repo);
      },
      act: (RecordingDetailCubit cubit) => cubit.load(recId),
      expect:
          () => <RecordingDetailState>[
            const RecordingDetailLoading(),
            const RecordingDetailNotFound(),
          ],
    );

    blocTest<RecordingDetailCubit, RecordingDetailState>(
      'reports network failures',
      build: () {
        when(() => repo.recordingDetail(recId)).thenThrow(const NetworkFailure());
        return RecordingDetailCubit(repo);
      },
      act: (RecordingDetailCubit cubit) => cubit.load(recId),
      expect:
          () => <RecordingDetailState>[
            const RecordingDetailLoading(),
            const RecordingDetailFailed(NetworkFailure()),
          ],
    );
  });

  group('PlaceRecordingsCubit', () {
    blocTest<PlaceRecordingsCubit, PlaceRecordingsState>(
      'loads the recordings of a place with the active filter',
      build: () {
        when(
          () => repo.recordingsAtPlace(1, const RecordingFilter(tag: 'x')),
        ).thenAnswer((_) async => <RecordingSummary>[summary]);
        return PlaceRecordingsCubit(repo);
      },
      act: (PlaceRecordingsCubit cubit) => cubit.load(1, const RecordingFilter(tag: 'x')),
      expect:
          () => <PlaceRecordingsState>[
            const PlaceRecordingsState(status: PlaceRecordingsStatus.loading),
            const PlaceRecordingsState(
              status: PlaceRecordingsStatus.ready,
              recordings: <RecordingSummary>[summary],
            ),
          ],
    );

    blocTest<PlaceRecordingsCubit, PlaceRecordingsState>(
      'reports failures',
      build: () {
        when(() => repo.recordingsAtPlace(any(), any())).thenThrow(const NetworkFailure());
        return PlaceRecordingsCubit(repo);
      },
      act: (PlaceRecordingsCubit cubit) => cubit.load(1, const RecordingFilter()),
      expect:
          () => <PlaceRecordingsState>[
            const PlaceRecordingsState(status: PlaceRecordingsStatus.loading),
            const PlaceRecordingsState(status: PlaceRecordingsStatus.failure),
          ],
    );
  });
}
