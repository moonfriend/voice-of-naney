import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/recording_detail.dart';
import '../../domain/repositories/recording_repository.dart';

sealed class RecordingDetailState extends Equatable {
  const RecordingDetailState();

  @override
  List<Object?> get props => <Object?>[];
}

class RecordingDetailLoading extends RecordingDetailState {
  const RecordingDetailLoading();
}

class RecordingDetailLoaded extends RecordingDetailState {
  const RecordingDetailLoaded({required this.detail, required this.selectedRevisionNo});

  final RecordingDetail detail;
  final int selectedRevisionNo;

  MediaRevision get selectedRevision =>
      detail.revisions.firstWhere((MediaRevision r) => r.revisionNo == selectedRevisionNo);

  @override
  List<Object?> get props => <Object?>[detail, selectedRevisionNo];
}

/// Unknown id, or a recording an admin has hidden.
class RecordingDetailNotFound extends RecordingDetailState {
  const RecordingDetailNotFound();
}

class RecordingDetailFailed extends RecordingDetailState {
  const RecordingDetailFailed(this.failure);

  final Failure failure;

  @override
  List<Object?> get props => <Object?>[failure];
}

class RecordingDetailCubit extends Cubit<RecordingDetailState> {
  RecordingDetailCubit(this._repository) : super(const RecordingDetailLoading());

  final RecordingRepository _repository;

  Future<void> load(String id) async {
    emit(const RecordingDetailLoading());
    try {
      final RecordingDetail detail = await _repository.recordingDetail(id);
      emit(
        RecordingDetailLoaded(detail: detail, selectedRevisionNo: detail.latestRevision.revisionNo),
      );
    } on NotFoundFailure {
      emit(const RecordingDetailNotFound());
    } on Failure catch (failure) {
      emit(RecordingDetailFailed(failure));
    }
  }

  void selectRevision(int revisionNo) {
    final RecordingDetailState current = state;
    if (current is! RecordingDetailLoaded ||
        !current.detail.revisions.any((MediaRevision r) => r.revisionNo == revisionNo)) {
      return;
    }
    emit(RecordingDetailLoaded(detail: current.detail, selectedRevisionNo: revisionNo));
  }
}
