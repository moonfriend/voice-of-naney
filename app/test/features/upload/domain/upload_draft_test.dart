import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:naney/core/domain/recording_kind.dart';
import 'package:naney/core/geo/area_polygon.dart';
import 'package:naney/features/upload/domain/entities/culture_choice.dart';
import 'package:naney/features/upload/domain/entities/place_choice.dart';
import 'package:naney/features/upload/domain/entities/upload_draft.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';

UploadSource source(String mime, int size) => UploadSource(
  name: 'f',
  mime: mime,
  size: size,
  openRead: () => const Stream<List<int>>.empty(),
);

const DrawnPlaceChoice place = DrawnPlaceChoice(
  nameEn: 'Villages near Maragheh',
  nameFa: null,
  polygons: <AreaPolygon>[
    AreaPolygon(outer: <LatLng>[LatLng(37, 46), LatLng(37, 47), LatLng(38, 47)]),
  ],
);

UploadDraft complete() => UploadDraft(
  media: UploadSource.bytes(name: 'a.mp3', mime: 'audio/mpeg', bytes: Uint8List(10)),
  title: 'Lay lay',
  kind: RecordingKind.lullaby,
  cultures: const <CultureChoice>[CultureChoice.listed(1)],
  place: place,
  consent: true,
);

void main() {
  final int thisYear = DateTime.now().year;

  test('a complete draft has no issues', () {
    expect(complete().issues, isEmpty);
    expect(complete().isReady, isTrue);
  });

  group('media step', () {
    test('requires a file', () {
      expect(const UploadDraft().issuesFor(UploadStep.media), contains(DraftIssue.mediaMissing));
    });

    test('accepts audio up to 50 MB and video up to 500 MB', () {
      expect(
        UploadDraft(
          media: source('audio/mpeg', UploadRules.audioMaxBytes),
        ).issuesFor(UploadStep.media),
        isEmpty,
      );
      expect(
        UploadDraft(
          media: source('audio/mpeg', UploadRules.audioMaxBytes + 1),
        ).issuesFor(UploadStep.media),
        <DraftIssue>{DraftIssue.mediaTooLarge},
      );
      expect(
        UploadDraft(
          media: source('video/mp4', UploadRules.videoMaxBytes),
        ).issuesFor(UploadStep.media),
        isEmpty,
      );
      expect(
        UploadDraft(
          media: source('video/quicktime', UploadRules.videoMaxBytes),
        ).issuesFor(UploadStep.media),
        isEmpty,
      );
    });

    test('rejects other file types', () {
      expect(
        UploadDraft(media: source('application/pdf', 10)).issuesFor(UploadStep.media),
        <DraftIssue>{DraftIssue.mediaUnsupported},
      );
    });

    test('checks the optional photo', () {
      expect(
        UploadDraft(
          media: source('audio/mpeg', 1),
          photo: source('image/png', UploadRules.photoMaxBytes + 1),
        ).issuesFor(UploadStep.media),
        <DraftIssue>{DraftIssue.photoTooLarge},
      );
      expect(
        UploadDraft(
          media: source('audio/mpeg', 1),
          photo: source('audio/mpeg', 1),
        ).issuesFor(UploadStep.media),
        <DraftIssue>{DraftIssue.photoUnsupported},
      );
    });
  });

  group('details step', () {
    test('requires a title and a kind', () {
      expect(const UploadDraft(title: '   ').issuesFor(UploadStep.details), <DraftIssue>{
        DraftIssue.titleMissing,
        DraftIssue.kindMissing,
      });
    });

    test('limits title length, tags and year', () {
      final UploadDraft draft = UploadDraft(
        title: 'x' * 201,
        kind: RecordingKind.poem,
        tags: List<String>.generate(21, (int i) => 't$i'),
        yearRecorded: thisYear + 1,
      );
      expect(draft.issuesFor(UploadStep.details), <DraftIssue>{
        DraftIssue.titleTooLong,
        DraftIssue.tooManyTags,
        DraftIssue.yearInvalid,
      });
      expect(
        const UploadDraft(
          title: 'a',
          kind: RecordingKind.poem,
          yearRecorded: 1799,
        ).issuesFor(UploadStep.details),
        <DraftIssue>{DraftIssue.yearInvalid},
      );
    });
  });

  group('cultures step', () {
    test('requires one to three valid entries', () {
      expect(const UploadDraft().issuesFor(UploadStep.cultures), <DraftIssue>{
        DraftIssue.culturesMissing,
      });
      expect(
        const UploadDraft(
          cultures: <CultureChoice>[
            CultureChoice.listed(1),
            CultureChoice.listed(2),
            CultureChoice.listed(3),
            CultureChoice.listed(4),
          ],
        ).issuesFor(UploadStep.cultures),
        <DraftIssue>{DraftIssue.tooManyCultures},
      );
      expect(
        const UploadDraft(
          cultures: <CultureChoice>[CultureChoice.other('  ')],
        ).issuesFor(UploadStep.cultures),
        <DraftIssue>{DraftIssue.cultureInvalid},
      );
    });

    test('rejects the same listed culture twice', () {
      expect(
        const UploadDraft(
          cultures: <CultureChoice>[CultureChoice.listed(1), CultureChoice.listed(1)],
        ).issuesFor(UploadStep.cultures),
        <DraftIssue>{DraftIssue.cultureDuplicate},
      );
    });
  });

  test('area step requires a place', () {
    expect(const UploadDraft().issuesFor(UploadStep.area), <DraftIssue>{DraftIssue.placeMissing});
  });

  test('consent step requires explicit consent', () {
    expect(const UploadDraft().issuesFor(UploadStep.consent), <DraftIssue>{
      DraftIssue.consentMissing,
    });
    expect(const UploadDraft(consent: true).issuesFor(UploadStep.consent), isEmpty);
  });

  test('builds the create_recording payload', () {
    final UploadDraft draft = complete().copyWith(
      tags: <String>[' sleep ', '', 'night'],
      languageId: () => 2,
      languageOther: () => 'ignored because "Other" is not selected',
    );
    final Map<String, Object?> json =
        draft.toNewRecording(placeId: 7, mediaUploadId: 'm1', photoUploadId: null).toJson();
    expect(json['place_id'], 7);
    expect(json['media_upload_id'], 'm1');
    expect(json['tags'], <String>['sleep', 'night']);
    expect(json['language_id'], 2);
    expect(json['language_other'], isNull);
    expect(json['consent'], isTrue);
    expect(json['cultures'], <Object?>[
      <String, Object?>{'culture_id': 1},
    ]);
  });
}
