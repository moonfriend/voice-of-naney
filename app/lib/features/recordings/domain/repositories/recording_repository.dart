import '../../../map/domain/entities/recording_filter.dart';
import '../entities/recording_detail.dart';
import '../entities/recording_summary.dart';

abstract interface class RecordingRepository {
  Future<List<RecordingSummary>> recordingsAtPlace(int placeId, RecordingFilter filter);

  /// Throws `NotFoundFailure` for unknown or hidden recordings.
  Future<RecordingDetail> recordingDetail(String id);
}
