import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/media/media_url_builder.dart';
import '../../../map/domain/entities/recording_filter.dart';
import '../../domain/entities/recording_detail.dart';
import '../../domain/entities/recording_summary.dart';
import '../../domain/repositories/recording_repository.dart';
import '../datasources/recording_remote_data_source.dart';
import '../models/recording_models.dart';

@LazySingleton(as: RecordingRepository)
class RecordingRepositoryImpl implements RecordingRepository {
  RecordingRepositoryImpl(this._remote, this._urls);

  final RecordingRemoteDataSource _remote;
  final MediaUrlBuilder _urls;

  static final RegExp _uuid = RegExp(
    r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
    caseSensitive: false,
  );

  @override
  Future<List<RecordingSummary>> recordingsAtPlace(int placeId, RecordingFilter filter) =>
      guardRemoteCall(
        () async =>
            (await _remote.fetchAtPlace(placeId, filter)).map(recordingSummaryFromJson).toList(),
      );

  @override
  Future<RecordingDetail> recordingDetail(String id) => guardRemoteCall(() async {
    // Shared links are user input: reject garbage before it reaches the database.
    if (!_uuid.hasMatch(id)) {
      throw const NotFoundFailure();
    }
    final Json row = await _remote.fetchDetail(id);
    final int placeId = ((row['places']! as Json)['id']! as num).toInt();
    final Json? area = await _remote.fetchPlaceArea(placeId);
    return recordingDetailFromJson(row, urls: _urls, placeArea: area);
  });
}
