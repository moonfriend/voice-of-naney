import 'dart:async';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/upload_source.dart';

/// Opens the system file dialog. Behind an interface so widgets can be tested.
abstract interface class FilePickerService {
  Future<UploadSource?> pickMedia();

  Future<UploadSource?> pickPhoto();
}

@LazySingleton(as: FilePickerService)
class SystemFilePickerService implements FilePickerService {
  @override
  Future<UploadSource?> pickMedia() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadRules.mediaMimeByExtension.keys.toList(),
      withReadStream: true,
    );
    final PlatformFile? file = result?.files.singleOrNull;
    final Stream<List<int>>? stream = file?.readStream;
    if (file == null || stream == null) {
      return null;
    }
    return UploadSource(
      name: file.name,
      mime: mimeFor(file.name, UploadRules.mediaMimeByExtension) ?? 'application/octet-stream',
      size: file.size,
      openRead: replayableReader(stream, file.size),
    );
  }

  @override
  Future<UploadSource?> pickPhoto() async {
    final FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: UploadRules.photoMimeByExtension.keys.toList(),
      withData: true,
    );
    final PlatformFile? file = result?.files.singleOrNull;
    final Uint8List? bytes = file?.bytes;
    if (file == null || bytes == null) {
      return null;
    }
    return UploadSource.bytes(
      name: file.name,
      mime: mimeFor(file.name, UploadRules.photoMimeByExtension) ?? 'application/octet-stream',
      bytes: bytes,
    );
  }
}

String? mimeFor(String fileName, Map<String, String> byExtension) {
  final int dot = fileName.lastIndexOf('.');
  return dot < 0 ? null : byExtension[fileName.substring(dot + 1).toLowerCase()];
}

/// Picked files can be streamed only once. Files up to [bufferLimit] are kept after the
/// first read so a failed upload can be retried; bigger videos must be chosen again.
Stream<List<int>> Function() replayableReader(
  Stream<List<int>> stream,
  int size, {
  int bufferLimit = 100 * UploadRules.megabyte,
}) {
  bool consumed = false;
  Uint8List? buffered;
  return () {
    if (buffered != null) {
      return Stream<List<int>>.value(buffered!);
    }
    if (consumed) {
      return Stream<List<int>>.error(StateError('file_must_be_chosen_again'));
    }
    consumed = true;
    if (size > bufferLimit) {
      return stream;
    }
    final BytesBuilder builder = BytesBuilder(copy: false);
    return stream
        .map((List<int> chunk) {
          builder.add(chunk);
          return chunk;
        })
        .transform(
          StreamTransformer<List<int>, List<int>>.fromHandlers(
            handleDone: (EventSink<List<int>> sink) {
              buffered = builder.takeBytes();
              sink.close();
            },
          ),
        );
  };
}
