import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/features/upload/domain/entities/culture_choice.dart';
import 'package:naney/features/upload/domain/entities/place_choice.dart';
import 'package:naney/features/upload/domain/entities/upload_draft.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';
import 'package:naney/features/upload/domain/usecases/submit_recording.dart';
import 'package:naney/features/upload/presentation/cubit/upload_form_cubit.dart';

class _MockSubmit extends Mock implements SubmitRecording {}

final UploadSource media = UploadSource.bytes(
  name: 'a.mp3',
  mime: 'audio/mpeg',
  bytes: Uint8List(4),
);
const DrawnPlaceChoice place = DrawnPlaceChoice(
  nameEn: 'Area',
  nameFa: null,
  polygons: <AreaPolygon>[
    AreaPolygon(outer: <LatLng>[LatLng(1, 1), LatLng(1, 2), LatLng(2, 2)]),
  ],
);

final UploadDraft readyDraft = UploadDraft(
  media: media,
  title: 'Lay lay',
  kind: RecordingKind.lullaby,
  cultures: const <CultureChoice>[CultureChoice.listed(1)],
  place: place,
  consent: true,
);

void main() {
  late _MockSubmit submit;

  setUpAll(() {
    registerFallbackValue(const UploadDraft());
    registerFallbackValue(const SubmissionCheckpoint());
  });
  setUp(() => submit = _MockSubmit());

  UploadFormCubit build() => UploadFormCubit(submit);

  blocTest<UploadFormCubit, UploadFormState>(
    'does not advance past an incomplete step and shows its issues',
    build: build,
    act: (UploadFormCubit cubit) => cubit.next(),
    expect: () => <UploadFormState>[const UploadFormState(showIssues: true)],
  );

  blocTest<UploadFormCubit, UploadFormState>(
    'advances once the step is complete and hides issues again',
    build: build,
    act:
        (UploadFormCubit cubit) =>
            cubit
              ..edit((UploadDraft d) => d.copyWith(media: () => media))
              ..next(),
    expect:
        () => <UploadFormState>[
          UploadFormState(draft: UploadDraft(media: media)),
          UploadFormState(draft: UploadDraft(media: media), step: UploadStep.details),
        ],
  );

  blocTest<UploadFormCubit, UploadFormState>(
    'goes back without validation',
    build: build,
    seed: () => const UploadFormState(step: UploadStep.cultures, showIssues: true),
    act: (UploadFormCubit cubit) => cubit.back(),
    expect: () => <UploadFormState>[const UploadFormState(step: UploadStep.details)],
  );

  group('cultures', () {
    blocTest<UploadFormCubit, UploadFormState>(
      'adds up to three and ignores a fourth',
      build: build,
      act:
          (UploadFormCubit cubit) =>
              cubit
                ..addCulture(const CultureChoice.listed(1))
                ..addCulture(const CultureChoice.other('Qarapapaq'))
                ..addCulture(const CultureChoice.listed(2))
                ..addCulture(const CultureChoice.listed(3)),
      verify:
          (UploadFormCubit cubit) => expect(cubit.state.draft.cultures, const <CultureChoice>[
            CultureChoice.listed(1),
            CultureChoice.other('Qarapapaq'),
            CultureChoice.listed(2),
          ]),
    );

    blocTest<UploadFormCubit, UploadFormState>(
      'replaces and removes entries',
      build: build,
      seed:
          () => const UploadFormState(
            draft: UploadDraft(
              cultures: <CultureChoice>[CultureChoice.listed(1), CultureChoice.listed(2)],
            ),
          ),
      act:
          (UploadFormCubit cubit) =>
              cubit
                ..replaceCulture(1, const CultureChoice.other('Mixed'))
                ..removeCulture(0),
      verify:
          (UploadFormCubit cubit) => expect(cubit.state.draft.cultures, const <CultureChoice>[
            CultureChoice.other('Mixed'),
          ]),
    );
  });

  blocTest<UploadFormCubit, UploadFormState>(
    'refuses to submit without consent',
    build: build,
    seed:
        () => UploadFormState(draft: readyDraft.copyWith(consent: false), step: UploadStep.consent),
    act: (UploadFormCubit cubit) => cubit.submit(),
    expect:
        () => <UploadFormState>[
          UploadFormState(
            draft: readyDraft.copyWith(consent: false),
            step: UploadStep.consent,
            showIssues: true,
          ),
        ],
    verify: (_) => verifyZeroInteractions(submit),
  );

  blocTest<UploadFormCubit, UploadFormState>(
    'submits, reports progress, and finishes with the new id',
    build: () {
      when(
        () => submit(
          any(),
          checkpoint: any(named: 'checkpoint'),
          onCheckpoint: any(named: 'onCheckpoint'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((Invocation invocation) async {
        (invocation.namedArguments[#onProgress] as void Function(SubmissionProgress))(
          const SubmissionProgress(SubmissionStage.uploadingMedia, sentBytes: 2, totalBytes: 4),
        );
        return 'rec-1';
      });
      return build();
    },
    seed: () => UploadFormState(draft: readyDraft, step: UploadStep.consent),
    act: (UploadFormCubit cubit) => cubit.submit(),
    expect:
        () => <UploadFormState>[
          UploadFormState(
            draft: readyDraft,
            step: UploadStep.consent,
            submission: const Submitting(),
          ),
          UploadFormState(
            draft: readyDraft,
            step: UploadStep.consent,
            submission: const Submitting(
              SubmissionProgress(SubmissionStage.uploadingMedia, sentBytes: 2, totalBytes: 4),
            ),
          ),
          UploadFormState(
            draft: readyDraft,
            step: UploadStep.consent,
            submission: const Submitted('rec-1'),
          ),
        ],
  );

  blocTest<UploadFormCubit, UploadFormState>(
    'keeps the checkpoint after a failure and resumes from it',
    build: () {
      int calls = 0;
      when(
        () => submit(
          any(),
          checkpoint: any(named: 'checkpoint'),
          onCheckpoint: any(named: 'onCheckpoint'),
          onProgress: any(named: 'onProgress'),
        ),
      ).thenAnswer((Invocation invocation) async {
        calls += 1;
        if (calls == 1) {
          (invocation.namedArguments[#onCheckpoint] as void Function(SubmissionCheckpoint))(
            const SubmissionCheckpoint(mediaUploadId: 'm1'),
          );
          throw const NetworkFailure();
        }
        expect(
          invocation.namedArguments[#checkpoint],
          const SubmissionCheckpoint(mediaUploadId: 'm1'),
        );
        return 'rec-2';
      });
      return build();
    },
    seed: () => UploadFormState(draft: readyDraft, step: UploadStep.consent),
    act: (UploadFormCubit cubit) async {
      await cubit.submit();
      await cubit.submit();
    },
    // Skips "submitting" and "submitting + checkpoint recorded".
    skip: 2,
    expect:
        () => <UploadFormState>[
          UploadFormState(
            draft: readyDraft,
            step: UploadStep.consent,
            submission: const SubmissionFailed(NetworkFailure()),
            checkpoint: const SubmissionCheckpoint(mediaUploadId: 'm1'),
          ),
          UploadFormState(
            draft: readyDraft,
            step: UploadStep.consent,
            submission: const Submitting(),
            checkpoint: const SubmissionCheckpoint(mediaUploadId: 'm1'),
          ),
          UploadFormState(
            draft: readyDraft,
            step: UploadStep.consent,
            submission: const Submitted('rec-2'),
            checkpoint: const SubmissionCheckpoint(mediaUploadId: 'm1'),
          ),
        ],
  );

  blocTest<UploadFormCubit, UploadFormState>(
    'changing the media file invalidates its earlier upload',
    build: build,
    seed:
        () => UploadFormState(
          draft: readyDraft,
          checkpoint: const SubmissionCheckpoint(
            mediaUploadId: 'm1',
            photoUploadId: 'p1',
            placeId: 3,
          ),
        ),
    act:
        (UploadFormCubit cubit) => cubit.edit(
          (UploadDraft d) => d.copyWith(
            media: () => UploadSource.bytes(name: 'b.mp3', mime: 'audio/mpeg', bytes: Uint8List(8)),
          ),
        ),
    verify:
        (UploadFormCubit cubit) => expect(
          cubit.state.checkpoint,
          const SubmissionCheckpoint(photoUploadId: 'p1', placeId: 3),
        ),
  );

  blocTest<UploadFormCubit, UploadFormState>(
    'changing the area invalidates the saved place',
    build: build,
    seed:
        () => UploadFormState(
          draft: readyDraft,
          checkpoint: const SubmissionCheckpoint(mediaUploadId: 'm1', placeId: 3),
        ),
    act: (UploadFormCubit cubit) => cubit.edit((UploadDraft d) => d.copyWith(place: () => null)),
    verify:
        (UploadFormCubit cubit) =>
            expect(cubit.state.checkpoint, const SubmissionCheckpoint(mediaUploadId: 'm1')),
  );
}
