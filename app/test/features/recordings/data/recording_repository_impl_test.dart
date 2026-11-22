import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/media_type.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/i18n/localized_name.dart';
import 'package:naney/core/media/media_url_builder.dart';
import 'package:naney/features/map/domain/entities/recording_filter.dart';
import 'package:naney/features/recordings/data/datasources/recording_remote_data_source.dart';
import 'package:naney/features/recordings/data/repositories/recording_repository_impl.dart';
import 'package:naney/features/recordings/domain/entities/recording_detail.dart';
import 'package:naney/features/recordings/domain/entities/recording_summary.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _MockRemote extends Mock implements RecordingRemoteDataSource {}

const String recId = '11111111-1111-4111-8111-111111111111';

Map<String, Object?> detailRow() => <String, Object?>{
  'id': recId,
  'title': 'Lay lay',
  'description': 'A lullaby',
  'kind': 'lullaby',
  'tags': <Object?>['sleep'],
  'transcript': '  ',
  'photo_key': 'photos/22222222-2222-4222-8222-222222222222.jpg',
  'performer_name': 'Naney',
  'year_recorded': 1998,
  'language_other': null,
  'origin_note': 'Moved from Urmia',
  'created_at': '2026-11-22T12:00:00+00:00',
  'languages': <String, Object?>{'name_en': 'Azerbaijani', 'name_fa': 'ترکی'},
  'places': <String, Object?>{'id': 1, 'name_en': 'Tabriz', 'name_fa': 'تبریز'},
  'recording_cultures': <Object?>[
    <String, Object?>{'position': 2, 'other_text': 'Qarapapaq', 'cultures': null},
    <String, Object?>{
      'position': 1,
      'other_text': null,
      'cultures': <String, Object?>{'name_en': 'Azeri', 'name_fa': 'آذری'},
    },
  ],
  'recording_media': <Object?>[
    <String, Object?>{
      'revision_no': 1,
      'media_type': 'audio',
      'object_key': 'media/33333333-3333-4333-8333-333333333333.mp3',
      'mime': 'audio/mpeg',
      'duration_ms': 60000,
      'note': 'noise removed',
    },
    <String, Object?>{
      'revision_no': 0,
      'media_type': 'audio',
      'object_key': 'media/44444444-4444-4444-8444-444444444444.mp3',
      'mime': 'audio/mpeg',
      'duration_ms': 61000,
      'note': null,
    },
  ],
};

void main() {
  late _MockRemote remote;
  late RecordingRepositoryImpl repository;
  final MediaUrlBuilder urls = MediaUrlBuilder(Uri.parse('https://naney.test'));

  setUpAll(() => registerFallbackValue(const RecordingFilter()));

  setUp(() {
    remote = _MockRemote();
    repository = RecordingRepositoryImpl(remote, urls);
  });

  test('maps a full recording detail', () async {
    when(() => remote.fetchDetail(recId)).thenAnswer((_) async => detailRow());
    when(() => remote.fetchPlaceArea(1)).thenAnswer(
      (_) async => <String, Object?>{
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
    );

    final RecordingDetail detail = await repository.recordingDetail(recId);

    expect(detail.title, 'Lay lay');
    expect(detail.kind, RecordingKind.lullaby);
    expect(detail.transcript, isNull, reason: 'blank text is treated as missing');
    expect(
      detail.photoUrl,
      Uri.parse('https://naney.test/photos/22222222-2222-4222-8222-222222222222.jpg'),
    );
    expect(detail.language, const LocalizedName(en: 'Azerbaijani', fa: 'ترکی'));
    expect(detail.cultures, const <CultureEntry>[
      CultureEntry(name: LocalizedName(en: 'Azeri', fa: 'آذری')),
      CultureEntry(otherText: 'Qarapapaq'),
    ]);
    expect(detail.revisions.map((MediaRevision r) => r.revisionNo), <int>[0, 1]);
    expect(detail.revisions.first.isOriginal, isTrue);
    expect(detail.latestRevision.note, 'noise removed');
    expect(detail.latestRevision.url.path, '/media/33333333-3333-4333-8333-333333333333.mp3');
    expect(detail.place.area.single.outer, hasLength(4));
    expect(detail.createdAt, DateTime.utc(2026, 11, 22, 12));
  });

  test('a place without an area still loads', () async {
    when(() => remote.fetchDetail(recId)).thenAnswer((_) async => detailRow());
    when(() => remote.fetchPlaceArea(1)).thenAnswer((_) async => null);
    expect((await repository.recordingDetail(recId)).place.area, isEmpty);
  });

  test('unknown or hidden recordings are NotFoundFailure', () async {
    when(() => remote.fetchDetail(recId)).thenThrow(
      const PostgrestException(
        message: 'JSON object requested, multiple (or no) rows returned',
        code: 'PGRST116',
      ),
    );
    await expectLater(repository.recordingDetail(recId), throwsA(isA<NotFoundFailure>()));
  });

  test('malformed ids never reach the database', () async {
    await expectLater(repository.recordingDetail("1' or 1=1"), throwsA(isA<NotFoundFailure>()));
    verifyNever(() => remote.fetchDetail(any()));
  });

  test('lists recordings at a place, typed by their newest media', () async {
    when(() => remote.fetchAtPlace(1, const RecordingFilter())).thenAnswer(
      (_) async => <Map<String, Object?>>[
        <String, Object?>{
          'id': recId,
          'title': 'Lay lay',
          'kind': 'poem',
          'performer_name': '',
          'year_recorded': null,
          'recording_media': <Object?>[
            <String, Object?>{'media_type': 'audio', 'revision_no': 0},
            <String, Object?>{'media_type': 'video', 'revision_no': 1},
          ],
        },
      ],
    );
    expect(await repository.recordingsAtPlace(1, const RecordingFilter()), const <RecordingSummary>[
      RecordingSummary(
        id: recId,
        title: 'Lay lay',
        kind: RecordingKind.poem,
        mediaType: MediaType.video,
      ),
    ]);
  });
}
