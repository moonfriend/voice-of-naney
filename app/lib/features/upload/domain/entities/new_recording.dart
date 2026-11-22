import 'package:equatable/equatable.dart';

import '../../../../core/domain/recording_kind.dart';
import 'culture_choice.dart';

/// Everything `create_recording` needs, once files are uploaded and the place saved.
class NewRecording extends Equatable {
  const NewRecording({
    required this.title,
    required this.kind,
    required this.cultures,
    required this.placeId,
    required this.mediaUploadId,
    required this.consent,
    this.description,
    this.tags = const <String>[],
    this.transcript,
    this.performerName,
    this.yearRecorded,
    this.languageId,
    this.languageOther,
    this.originNote,
    this.photoUploadId,
    this.durationMs,
  });

  final String title;
  final RecordingKind kind;
  final List<CultureChoice> cultures;
  final int placeId;
  final String mediaUploadId;
  final bool consent;
  final String? description;
  final List<String> tags;
  final String? transcript;
  final String? performerName;
  final int? yearRecorded;
  final int? languageId;
  final String? languageOther;
  final String? originNote;
  final String? photoUploadId;
  final int? durationMs;

  Map<String, Object?> toJson() => <String, Object?>{
    'title': title.trim(),
    'kind': kind.name,
    'cultures': cultures.map((CultureChoice c) => c.toJson()).toList(),
    'place_id': placeId,
    'media_upload_id': mediaUploadId,
    'consent': consent,
    'description': _clean(description),
    'tags': tags,
    'transcript': _clean(transcript),
    'performer_name': _clean(performerName),
    'year_recorded': yearRecorded,
    'language_id': languageId,
    'language_other': languageId == null ? _clean(languageOther) : null,
    'origin_note': _clean(originNote),
    'photo_upload_id': photoUploadId,
    'duration_ms': durationMs,
  };

  static String? _clean(String? value) {
    final String? trimmed = value?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  @override
  List<Object?> get props => <Object?>[toJson()];
}
