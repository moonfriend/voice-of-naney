import '../../../../core/domain/media_type.dart';
import '../../../../core/domain/recording_kind.dart';
import '../../../../core/geo/area_polygon.dart';
import '../../../../core/i18n/localized_name.dart';
import '../../../../core/media/media_url_builder.dart';
import '../../domain/entities/recording_detail.dart';
import '../../domain/entities/recording_summary.dart';

typedef Json = Map<String, Object?>;

List<Json> _list(Object? value) => (value as List<Object?>? ?? const <Object?>[]).cast<Json>();

String? _blankToNull(Object? value) {
  final String? text = value as String?;
  return (text == null || text.trim().isEmpty) ? null : text;
}

RecordingSummary recordingSummaryFromJson(Json json) {
  final List<Json> media = _list(json['recording_media'])
    ..sort((Json a, Json b) => (a['revision_no']! as num).compareTo(b['revision_no']! as num));
  return RecordingSummary(
    id: json['id']! as String,
    title: json['title']! as String,
    kind: RecordingKind.fromDb(json['kind']! as String),
    mediaType:
        media.isEmpty ? MediaType.audio : MediaType.fromDb(media.last['media_type']! as String),
    performerName: _blankToNull(json['performer_name']),
    yearRecorded: (json['year_recorded'] as num?)?.toInt(),
  );
}

RecordingDetail recordingDetailFromJson(
  Json json, {
  required MediaUrlBuilder urls,
  Json? placeArea,
}) {
  final Json place = json['places']! as Json;
  final Json? language = json['languages'] as Json?;

  final List<Json> cultureRows = _list(json['recording_cultures'])
    ..sort((Json a, Json b) => (a['position']! as num).compareTo(b['position']! as num));
  final List<CultureEntry> cultures =
      cultureRows.map((Json row) {
        final Json? curated = row['cultures'] as Json?;
        return curated != null
            ? CultureEntry(name: LocalizedName.fromJson(curated))
            : CultureEntry(otherText: row['other_text']! as String);
      }).toList();

  final List<MediaRevision> revisions =
      _list(json['recording_media'])
          .map(
            (Json row) => MediaRevision(
              revisionNo: (row['revision_no']! as num).toInt(),
              mediaType: MediaType.fromDb(row['media_type']! as String),
              url: urls.urlFor(row['object_key']! as String),
              mime: row['mime']! as String,
              durationMs: (row['duration_ms'] as num?)?.toInt(),
              note: _blankToNull(row['note']),
            ),
          )
          .toList()
        ..sort((MediaRevision a, MediaRevision b) => a.revisionNo.compareTo(b.revisionNo));
  if (revisions.isEmpty) {
    throw const FormatException('Recording without media');
  }

  final String? photoKey = _blankToNull(json['photo_key']);
  return RecordingDetail(
    id: json['id']! as String,
    title: json['title']! as String,
    kind: RecordingKind.fromDb(json['kind']! as String),
    place: RecordingPlace(
      id: (place['id']! as num).toInt(),
      name: LocalizedName.fromJson(place),
      area: placeArea == null ? const <AreaPolygon>[] : polygonsFromGeoJson(placeArea),
    ),
    cultures: cultures,
    revisions: revisions,
    createdAt: DateTime.parse(json['created_at']! as String),
    tags: (json['tags'] as List<Object?>? ?? const <Object?>[]).cast<String>(),
    description: _blankToNull(json['description']),
    transcript: _blankToNull(json['transcript']),
    photoUrl: photoKey == null ? null : urls.urlFor(photoKey),
    performerName: _blankToNull(json['performer_name']),
    yearRecorded: (json['year_recorded'] as num?)?.toInt(),
    language: language == null ? null : LocalizedName.fromJson(language),
    languageOther: _blankToNull(json['language_other']),
    originNote: _blankToNull(json['origin_note']),
  );
}
