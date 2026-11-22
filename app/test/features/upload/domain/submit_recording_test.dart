import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/features/upload/domain/entities/culture_choice.dart';
import 'package:naney/features/upload/domain/entities/new_recording.dart';
import 'package:naney/features/upload/domain/entities/place_choice.dart';
import 'package:naney/features/upload/domain/entities/upload_draft.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';
import 'package:naney/features/upload/domain/repositories/upload_repositories.dart';
import 'package:naney/features/upload/domain/usecases/submit_recording.dart';

class _Files extends Mock implements FileUploadRepository {}

class _Places extends Mock implements PlaceLookupRepository {}

class _Recordings extends Mock implements RecordingSubmissionRepository {}

final UploadSource media = UploadSource.bytes(
  name: 'a.mp3',
  mime: 'audio/mpeg',
  bytes: Uint8List(100),
);
final UploadSource photo = UploadSource.bytes(
  name: 'p.jpg',
  mime: 'image/jpeg',
  bytes: Uint8List(10),
);
const DrawnPlaceChoice place = DrawnPlaceChoice(
  nameEn: 'Area',
  nameFa: null,
  polygons: <AreaPolygon>[
    AreaPolygon(outer: <LatLng>[LatLng(1, 1), LatLng(1, 2), LatLng(2, 2)]),
  ],
);

UploadDraft draft({UploadSource? withPhoto}) => UploadDraft(
  media: media,
  photo: withPhoto,
  title: 'Lay lay',
  kind: RecordingKind.lullaby,
  cultures: const <CultureChoice>[CultureChoice.listed(1)],
  place: place,
  consent: true,
);

void main() {
  late _Files files;
  late _Places places;
  late _Recordings recordings;
  late SubmitRecording submit;
  late List<SubmissionCheckpoint> checkpoints;
  late List<SubmissionProgress> progress;

  setUpAll(() {
    registerFallbackValue(media);
    registerFallbackValue(UploadPurpose.media);
    registerFallbackValue(place);
    registerFallbackValue(
      const NewRecording(
        title: 't',
        kind: RecordingKind.poem,
        cultures: <CultureChoice>[],
        placeId: 1,
        mediaUploadId: 'x',
        consent: true,
      ),
    );
  });

  setUp(() {
    files = _Files();
    places = _Places();
    recordings = _Recordings();
    submit = SubmitRecording(files, places, recordings);
    checkpoints = <SubmissionCheckpoint>[];
    progress = <SubmissionProgress>[];
    when(
      () => files.upload(media, UploadPurpose.media, onProgress: any(named: 'onProgress')),
    ).thenAnswer((Invocation invocation) async {
      (invocation.namedArguments[#onProgress] as ProgressCallback?)?.call(50);
      return 'media-1';
    });
    when(
      () => files.upload(photo, UploadPurpose.photo, onProgress: any(named: 'onProgress')),
    ).thenAnswer((_) async => 'photo-1');
    when(() => places.save(place)).thenAnswer((_) async => 9);
    when(() => recordings.create(any())).thenAnswer((_) async => 'rec-1');
  });

  Future<String> run(
    UploadDraft d, [
    SubmissionCheckpoint checkpoint = const SubmissionCheckpoint(),
  ]) => submit(d, checkpoint: checkpoint, onCheckpoint: checkpoints.add, onProgress: progress.add);

  test('uploads, saves the place, then creates the recording', () async {
    expect(await run(draft(withPhoto: photo)), 'rec-1');

    final NewRecording created =
        verify(() => recordings.create(captureAny())).captured.single as NewRecording;
    expect(created.mediaUploadId, 'media-1');
    expect(created.photoUploadId, 'photo-1');
    expect(created.placeId, 9);
    expect(
      checkpoints.last,
      const SubmissionCheckpoint(mediaUploadId: 'media-1', photoUploadId: 'photo-1', placeId: 9),
    );
    expect(
      progress,
      contains(
        const SubmissionProgress(SubmissionStage.uploadingMedia, sentBytes: 50, totalBytes: 100),
      ),
    );
    expect(progress.last.stage, SubmissionStage.savingRecording);
  });

  test('works without a photo', () async {
    await run(draft());
    verifyNever(
      () => files.upload(any(), UploadPurpose.photo, onProgress: any(named: 'onProgress')),
    );
  });

  test('a retry resumes after the last completed step', () async {
    when(() => recordings.create(any())).thenThrow(const NetworkFailure());
    await expectLater(run(draft()), throwsA(isA<NetworkFailure>()));
    final SubmissionCheckpoint saved = checkpoints.last;
    expect(saved, const SubmissionCheckpoint(mediaUploadId: 'media-1', placeId: 9));

    when(() => recordings.create(any())).thenAnswer((_) async => 'rec-2');
    expect(await run(draft(), saved), 'rec-2');
    verify(() => files.upload(any(), any(), onProgress: any(named: 'onProgress'))).called(1);
    verify(() => places.save(any())).called(1);
  });

  test('refuses an incomplete draft', () async {
    await expectLater(run(const UploadDraft()), throwsStateError);
    verifyZeroInteractions(files);
  });
}
