import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/datasources/audio_recorder_service.dart';
import '../../domain/entities/upload_source.dart';

sealed class RecorderState extends Equatable {
  const RecorderState();

  @override
  List<Object?> get props => <Object?>[];
}

class RecorderIdle extends RecorderState {
  const RecorderIdle();
}

class RecorderRecording extends RecorderState {
  const RecorderRecording(this.elapsed);

  final Duration elapsed;

  @override
  List<Object?> get props => <Object?>[elapsed];
}

class RecorderFinished extends RecorderState {
  const RecorderFinished(this.recording);

  final UploadSource recording;

  @override
  List<Object?> get props => <Object?>[recording];
}

class RecorderPermissionDenied extends RecorderState {
  const RecorderPermissionDenied();
}

class RecorderFailed extends RecorderState {
  const RecorderFailed();
}

/// Records a voice directly in the browser (or app) as an alternative to picking a file.
class RecorderCubit extends Cubit<RecorderState> {
  RecorderCubit(
    this._service, {
    Duration tick = const Duration(seconds: 1),
    DateTime Function() clock = DateTime.now,
  }) : _tick = tick,
       _clock = clock,
       super(const RecorderIdle());

  /// Keeps recordings within the 50 MB audio limit with a wide margin.
  static const Duration maxDuration = Duration(minutes: 30);

  final AudioRecorderService _service;
  final Duration _tick;
  final DateTime Function() _clock;
  Timer? _timer;
  DateTime? _startedAt;

  Future<void> start() async {
    if (state is RecorderRecording) {
      return;
    }
    try {
      if (!await _service.requestPermission()) {
        emit(const RecorderPermissionDenied());
        return;
      }
      await _service.start();
    } on Object {
      emit(const RecorderFailed());
      return;
    }
    _startedAt = _clock();
    emit(const RecorderRecording(Duration.zero));
    _timer = Timer.periodic(_tick, (_) {
      final Duration elapsed = _clock().difference(_startedAt!);
      if (elapsed >= maxDuration) {
        unawaited(stop());
      } else if (!isClosed) {
        emit(RecorderRecording(elapsed));
      }
    });
  }

  Future<void> stop() async {
    if (state is! RecorderRecording) {
      return;
    }
    _timer?.cancel();
    final int durationMs = _clock().difference(_startedAt!).inMilliseconds;
    try {
      final UploadSource? recording = await _service.stop(durationMs: durationMs);
      emit(recording == null ? const RecorderFailed() : RecorderFinished(recording));
    } on Object {
      emit(const RecorderFailed());
    }
  }

  Future<void> discard() async {
    _timer?.cancel();
    if (state is RecorderRecording) {
      await _service.cancel();
    }
    emit(const RecorderIdle());
  }

  @override
  Future<void> close() async {
    _timer?.cancel();
    await _service.dispose();
    return super.close();
  }
}
