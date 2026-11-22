import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import '../../../../core/domain/media_type.dart';

enum UploadPurpose { media, photo }

/// A file chosen or recorded by the uploader. Read as a stream so large videos
/// never have to sit in memory all at once.
class UploadSource extends Equatable {
  const UploadSource({
    required this.name,
    required this.mime,
    required this.size,
    required this.openRead,
    this.durationMs,
  });

  factory UploadSource.bytes({
    required String name,
    required String mime,
    required Uint8List bytes,
    int? durationMs,
  }) => UploadSource(
    name: name,
    mime: mime,
    size: bytes.length,
    openRead: () => Stream<List<int>>.value(bytes),
    durationMs: durationMs,
  );

  final String name;
  final String mime;
  final int size;
  final Stream<List<int>> Function() openRead;

  /// Known for in-app recordings; files leave it empty.
  final int? durationMs;

  MediaType? get mediaType => switch (mime.split('/').first) {
    'audio' => MediaType.audio,
    'video' => MediaType.video,
    _ => null,
  };

  @override
  List<Object?> get props => <Object?>[name, mime, size, durationMs];
}

/// Upload limits and accepted types (mirrors the Worker's policy).
abstract final class UploadRules {
  static const int megabyte = 1024 * 1024;
  static const int audioMaxBytes = 50 * megabyte;
  static const int videoMaxBytes = 500 * megabyte;
  static const int photoMaxBytes = 10 * megabyte;

  static const Map<String, String> mediaMimeByExtension = <String, String>{
    'mp3': 'audio/mpeg',
    'm4a': 'audio/mp4',
    'aac': 'audio/aac',
    'wav': 'audio/wav',
    'ogg': 'audio/ogg',
    'oga': 'audio/ogg',
    // WhatsApp/Telegram voice notes (Opus in an Ogg container).
    'opus': 'audio/ogg',
    'flac': 'audio/flac',
    'webm': 'audio/webm',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'm4v': 'video/x-m4v',
  };

  static const Map<String, String> photoMimeByExtension = <String, String>{
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'png': 'image/png',
    'webp': 'image/webp',
  };

  static int maxBytesFor(String mime) => switch (mime.split('/').first) {
    'video' => videoMaxBytes,
    'image' => photoMaxBytes,
    _ => audioMaxBytes,
  };
}
