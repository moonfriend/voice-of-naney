import 'package:equatable/equatable.dart';

import '../../../../core/domain/recording_kind.dart';
import 'culture_choice.dart';
import 'new_recording.dart';
import 'place_choice.dart';
import 'upload_source.dart';

enum UploadStep { media, details, cultures, area, consent }

/// Rule violations shown next to the relevant step. The database enforces the same rules.
enum DraftIssue {
  mediaMissing,
  mediaUnsupported,
  mediaTooLarge,
  photoUnsupported,
  photoTooLarge,
  titleMissing,
  titleTooLong,
  kindMissing,
  yearInvalid,
  tooManyTags,
  culturesMissing,
  tooManyCultures,
  cultureInvalid,
  cultureDuplicate,
  placeMissing,
  consentMissing,
}

/// Everything an uploader has entered so far.
class UploadDraft extends Equatable {
  const UploadDraft({
    this.media,
    this.photo,
    this.title = '',
    this.description = '',
    this.kind,
    this.tags = const <String>[],
    this.performerName = '',
    this.yearRecorded,
    this.languageId,
    this.languageOther = '',
    this.languageOtherSelected = false,
    this.transcript = '',
    this.cultures = const <CultureChoice>[],
    this.originNote = '',
    this.place,
    this.consent = false,
  });

  static const int maxTitleLength = 200;
  static const int maxTags = 20;
  static const int earliestYear = 1800;

  final UploadSource? media;
  final UploadSource? photo;
  final String title;
  final String description;
  final RecordingKind? kind;
  final List<String> tags;
  final String performerName;
  final int? yearRecorded;
  final int? languageId;
  final String languageOther;

  /// The uploader picked "Other language" (the text may still be empty).
  final bool languageOtherSelected;
  final String transcript;
  final List<CultureChoice> cultures;
  final String originNote;
  final PlaceChoice? place;
  final bool consent;

  List<String> get cleanTags =>
      tags.map((String tag) => tag.trim()).where((String tag) => tag.isNotEmpty).toList();

  Set<DraftIssue> issuesFor(UploadStep step) => switch (step) {
    UploadStep.media => _mediaIssues(),
    UploadStep.details => _detailIssues(),
    UploadStep.cultures => _cultureIssues(),
    UploadStep.area => <DraftIssue>{if (place == null) DraftIssue.placeMissing},
    UploadStep.consent => <DraftIssue>{if (!consent) DraftIssue.consentMissing},
  };

  Set<DraftIssue> get issues => <DraftIssue>{
    for (final UploadStep step in UploadStep.values) ...issuesFor(step),
  };

  bool get isReady => issues.isEmpty;

  Set<DraftIssue> _mediaIssues() {
    final UploadSource? file = media;
    final UploadSource? image = photo;
    return <DraftIssue>{
      if (file == null) DraftIssue.mediaMissing,
      if (file != null && file.mediaType == null) DraftIssue.mediaUnsupported,
      if (file != null && file.mediaType != null && file.size > UploadRules.maxBytesFor(file.mime))
        DraftIssue.mediaTooLarge,
      if (image != null && !image.mime.startsWith('image/')) DraftIssue.photoUnsupported,
      if (image != null &&
          image.mime.startsWith('image/') &&
          image.size > UploadRules.photoMaxBytes)
        DraftIssue.photoTooLarge,
    };
  }

  Set<DraftIssue> _detailIssues() {
    final String trimmed = title.trim();
    final int? year = yearRecorded;
    return <DraftIssue>{
      if (trimmed.isEmpty) DraftIssue.titleMissing,
      if (trimmed.length > maxTitleLength) DraftIssue.titleTooLong,
      if (kind == null) DraftIssue.kindMissing,
      if (year != null && (year < earliestYear || year > DateTime.now().year))
        DraftIssue.yearInvalid,
      if (cleanTags.length > maxTags) DraftIssue.tooManyTags,
    };
  }

  Set<DraftIssue> _cultureIssues() {
    final List<int> listed =
        cultures.map((CultureChoice c) => c.cultureId).whereType<int>().toList();
    return <DraftIssue>{
      if (cultures.isEmpty) DraftIssue.culturesMissing,
      if (cultures.length > CultureChoice.maxPerRecording) DraftIssue.tooManyCultures,
      if (cultures.any((CultureChoice c) => !c.isValid)) DraftIssue.cultureInvalid,
      if (listed.toSet().length != listed.length) DraftIssue.cultureDuplicate,
    };
  }

  NewRecording toNewRecording({
    required int placeId,
    required String mediaUploadId,
    required String? photoUploadId,
  }) => NewRecording(
    title: title,
    kind: kind!,
    cultures: cultures,
    placeId: placeId,
    mediaUploadId: mediaUploadId,
    consent: consent,
    description: description,
    tags: cleanTags,
    transcript: transcript,
    performerName: performerName,
    yearRecorded: yearRecorded,
    languageId: languageId,
    languageOther: languageOtherSelected ? languageOther : null,
    originNote: originNote,
    photoUploadId: photoUploadId,
    durationMs: media?.durationMs,
  );

  UploadDraft copyWith({
    UploadSource? Function()? media,
    UploadSource? Function()? photo,
    String? title,
    String? description,
    RecordingKind? Function()? kind,
    List<String>? tags,
    String? performerName,
    int? Function()? yearRecorded,
    int? Function()? languageId,
    String? Function()? languageOther,
    bool? languageOtherSelected,
    String? transcript,
    List<CultureChoice>? cultures,
    String? originNote,
    PlaceChoice? Function()? place,
    bool? consent,
  }) => UploadDraft(
    media: media != null ? media() : this.media,
    photo: photo != null ? photo() : this.photo,
    title: title ?? this.title,
    description: description ?? this.description,
    kind: kind != null ? kind() : this.kind,
    tags: tags ?? this.tags,
    performerName: performerName ?? this.performerName,
    yearRecorded: yearRecorded != null ? yearRecorded() : this.yearRecorded,
    languageId: languageId != null ? languageId() : this.languageId,
    languageOther: languageOther != null ? (languageOther() ?? '') : this.languageOther,
    languageOtherSelected: languageOtherSelected ?? this.languageOtherSelected,
    transcript: transcript ?? this.transcript,
    cultures: cultures ?? this.cultures,
    originNote: originNote ?? this.originNote,
    place: place != null ? place() : this.place,
    consent: consent ?? this.consent,
  );

  @override
  List<Object?> get props => <Object?>[
    media,
    photo,
    title,
    description,
    kind,
    tags,
    performerName,
    yearRecorded,
    languageId,
    languageOther,
    languageOtherSelected,
    transcript,
    cultures,
    originNote,
    place,
    consent,
  ];
}
