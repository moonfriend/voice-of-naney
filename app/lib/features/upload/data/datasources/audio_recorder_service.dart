import 'package:cross_file/cross_file.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:record/record.dart';

import '../../domain/entities/upload_source.dart';

/// Microphone recording, hidden behind an interface so the UI logic can be tested.
abstract interface class AudioRecorderService {
  Future<bool> requestPermission();

  Future<void> start();

  /// Stops and returns the recording, or null if nothing was recorded.
  Future<UploadSource?> stop({required int durationMs});

  Future<void> cancel();

  Future<void> dispose();
}

@Injectable(as: AudioRecorderService)
class RecordPackageAudioRecorder implements AudioRecorderService {
  RecordPackageAudioRecorder() : _recorder = AudioRecorder();

  final AudioRecorder _recorder;
  String _mime = 'audio/mp4';
  String _extension = 'm4a';

  @override
  Future<bool> requestPermission() => _recorder.hasPermission();

  @override
  Future<void> start() async {
    // Chrome/Firefox record Opus in WebM; Safari and the mobile apps use AAC in MP4.
    final bool webOpus = kIsWeb && await _recorder.isEncoderSupported(AudioEncoder.opus);
    final AudioEncoder encoder = webOpus ? AudioEncoder.opus : AudioEncoder.aacLc;
    _mime = webOpus ? 'audio/webm' : 'audio/mp4';
    _extension = webOpus ? 'webm' : 'm4a';
    // On web the path is ignored and a blob URL is returned by stop().
    await _recorder.start(RecordConfig(encoder: encoder), path: kIsWeb ? '' : await _tempPath());
  }

  @override
  Future<UploadSource?> stop({required int durationMs}) async {
    final String? location = await _recorder.stop();
    if (location == null) {
      return null;
    }
    final Uint8List bytes = await XFile(location).readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }
    return UploadSource.bytes(
      name: 'recording.$_extension',
      mime: _mime,
      bytes: bytes,
      durationMs: durationMs,
    );
  }

  @override
  Future<void> cancel() => _recorder.cancel();

  @override
  Future<void> dispose() => _recorder.dispose();

  Future<String> _tempPath() async =>
      // Mobile builds (post-MVP) will switch this to path_provider's temp directory.
      'naney_recording_${DateTime.now().millisecondsSinceEpoch}.$_extension';
}
