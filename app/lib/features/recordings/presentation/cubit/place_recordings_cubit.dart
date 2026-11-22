import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../map/domain/entities/recording_filter.dart';
import '../../domain/entities/recording_summary.dart';
import '../../domain/repositories/recording_repository.dart';

enum PlaceRecordingsStatus { loading, ready, failure }

class PlaceRecordingsState extends Equatable {
  const PlaceRecordingsState({required this.status, this.recordings = const <RecordingSummary>[]});

  final PlaceRecordingsStatus status;
  final List<RecordingSummary> recordings;

  @override
  List<Object?> get props => <Object?>[status, recordings];
}

class PlaceRecordingsCubit extends Cubit<PlaceRecordingsState> {
  PlaceRecordingsCubit(this._repository)
    : super(const PlaceRecordingsState(status: PlaceRecordingsStatus.loading));

  final RecordingRepository _repository;

  Future<void> load(int placeId, RecordingFilter filter) async {
    emit(const PlaceRecordingsState(status: PlaceRecordingsStatus.loading));
    try {
      final List<RecordingSummary> recordings = await _repository.recordingsAtPlace(
        placeId,
        filter,
      );
      emit(PlaceRecordingsState(status: PlaceRecordingsStatus.ready, recordings: recordings));
    } on Failure {
      emit(const PlaceRecordingsState(status: PlaceRecordingsStatus.failure));
    }
  }
}
