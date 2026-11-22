import 'package:equatable/equatable.dart';

import '../../../../core/domain/media_type.dart';
import '../../../../core/domain/recording_kind.dart';
import '../../../../core/geo/area_polygon.dart';
import '../../../../core/i18n/localized_name.dart';

/// A culture/ethnicity attached to a recording: from the curated list or free text.
class CultureEntry extends Equatable {
  const CultureEntry({this.name, this.otherText})
    : assert((name == null) != (otherText == null), 'exactly one source');

  final LocalizedName? name;
  final String? otherText;

  @override
  List<Object?> get props => <Object?>[name, otherText];
}

/// A media file of a recording. Revision 0 is the original upload.
class MediaRevision extends Equatable {
  const MediaRevision({
    required this.revisionNo,
    required this.mediaType,
    required this.url,
    required this.mime,
    this.durationMs,
    this.note,
  });

  final int revisionNo;
  final MediaType mediaType;
  final Uri url;
  final String mime;
  final int? durationMs;
  final String? note;

  bool get isOriginal => revisionNo == 0;

  @override
  List<Object?> get props => <Object?>[revisionNo, mediaType, url, mime, durationMs, note];
}

class RecordingPlace extends Equatable {
  const RecordingPlace({required this.id, required this.name, this.area = const <AreaPolygon>[]});

  final int id;
  final LocalizedName name;
  final List<AreaPolygon> area;

  @override
  List<Object?> get props => <Object?>[id, name, area];
}

class RecordingDetail extends Equatable {
  const RecordingDetail({
    required this.id,
    required this.title,
    required this.kind,
    required this.place,
    required this.cultures,
    required this.revisions,
    required this.createdAt,
    this.tags = const <String>[],
    this.description,
    this.transcript,
    this.photoUrl,
    this.performerName,
    this.yearRecorded,
    this.language,
    this.languageOther,
    this.originNote,
  });

  final String id;
  final String title;
  final RecordingKind kind;
  final RecordingPlace place;
  final List<CultureEntry> cultures;

  /// Sorted by revision number; never empty.
  final List<MediaRevision> revisions;
  final DateTime createdAt;
  final List<String> tags;
  final String? description;
  final String? transcript;
  final Uri? photoUrl;
  final String? performerName;
  final int? yearRecorded;
  final LocalizedName? language;
  final String? languageOther;
  final String? originNote;

  /// Admins may add improved revisions; the newest one plays by default.
  MediaRevision get latestRevision => revisions.last;

  @override
  List<Object?> get props => <Object?>[
    id,
    title,
    kind,
    place,
    cultures,
    revisions,
    createdAt,
    tags,
    description,
    transcript,
    photoUrl,
    performerName,
    yearRecorded,
    language,
    languageOther,
    originNote,
  ];
}
