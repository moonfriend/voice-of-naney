import 'package:equatable/equatable.dart';

import '../../../../core/domain/media_type.dart';
import '../../../../core/domain/recording_kind.dart';

/// A row in the list of recordings for one place.
class RecordingSummary extends Equatable {
  const RecordingSummary({
    required this.id,
    required this.title,
    required this.kind,
    required this.mediaType,
    this.performerName,
    this.yearRecorded,
  });

  final String id;
  final String title;
  final RecordingKind kind;
  final MediaType mediaType;
  final String? performerName;
  final int? yearRecorded;

  @override
  List<Object?> get props => <Object?>[id, title, kind, mediaType, performerName, yearRecorded];
}
