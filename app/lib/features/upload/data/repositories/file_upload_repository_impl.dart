import 'dart:async';
import 'dart:typed_data';

import 'package:injectable/injectable.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/upload_source.dart';
import '../../domain/repositories/upload_repositories.dart';
import '../datasources/object_transfer.dart';
import '../datasources/worker_api.dart';

typedef RetryDelay = Future<void> Function(int attempt);

Future<void> exponentialBackoff(int attempt) =>
    Future<void>.delayed(Duration(milliseconds: 500 * (1 << (attempt - 1))));

/// Uploads to R2 via presigned URLs. Large files go in parts, each retried on its own,
/// so a flaky connection does not restart a 500 MB video from zero.
@LazySingleton(as: FileUploadRepository)
class FileUploadRepositoryImpl implements FileUploadRepository {
  FileUploadRepositoryImpl(this._api, this._transfer, {@ignoreParam RetryDelay? retryDelay})
    : _retryDelay = retryDelay ?? exponentialBackoff;

  static const int maxAttemptsPerPart = 3;

  final WorkerApi _api;
  final ObjectTransfer _transfer;
  final RetryDelay _retryDelay;

  @override
  Future<String> upload(
    UploadSource source,
    UploadPurpose purpose, {
    ProgressCallback? onProgress,
  }) async {
    try {
      return await _upload(source, purpose, onProgress);
    } on Failure {
      rethrow;
    } on StateError catch (error) {
      // Thrown by the file reader when a large file cannot be re-read for a retry.
      throw error.message == 'file_must_be_chosen_again'
          ? const ServerFailure('file_must_be_chosen_again')
          : UnexpectedFailure(error);
    } catch (error) {
      throw UnexpectedFailure(error);
    }
  }

  Future<String> _upload(
    UploadSource source,
    UploadPurpose purpose,
    ProgressCallback? onProgress,
  ) async {
    final UploadTicket ticket = await _api.createUpload(
      purpose: purpose,
      mime: source.mime,
      size: source.size,
    );
    switch (ticket) {
      case SingleUploadTicket():
        final Uint8List bytes = await _readAll(source);
        await _withRetries(
          () => _transfer.put(ticket.url, bytes, headers: ticket.headers, onProgress: onProgress),
        );
        await _api.completeUpload(ticket.uploadId);
      case MultipartUploadTicket():
        final List<CompletedPart> parts = await _uploadParts(source, ticket, onProgress);
        await _api.completeUpload(ticket.uploadId, parts: parts);
    }
    return ticket.uploadId;
  }

  Future<List<CompletedPart>> _uploadParts(
    UploadSource source,
    MultipartUploadTicket ticket,
    ProgressCallback? onProgress,
  ) async {
    final List<CompletedPart> completed = <CompletedPart>[];
    int sentBefore = 0;
    await for (final Uint8List chunk in _chunks(source.openRead(), ticket.partSize)) {
      if (completed.length >= ticket.parts.length) {
        throw const UnexpectedFailure('File is larger than declared');
      }
      final PartTarget target = ticket.parts[completed.length];
      final int offset = sentBefore;
      final String etag = await _withRetries(
        () => _transfer.put(
          target.url,
          chunk,
          onProgress: onProgress == null ? null : (int sent) => onProgress(offset + sent),
        ),
      );
      completed.add(CompletedPart(partNumber: target.partNumber, etag: etag));
      sentBefore += chunk.length;
    }
    if (completed.length != ticket.parts.length) {
      throw const UnexpectedFailure('File is smaller than declared');
    }
    return completed;
  }

  Future<T> _withRetries<T>(Future<T> Function() attempt) async {
    for (int tries = 1; ; tries += 1) {
      try {
        return await attempt();
      } on NetworkFailure {
        if (tries >= maxAttemptsPerPart) {
          rethrow;
        }
        await _retryDelay(tries);
      }
    }
  }

  static Future<Uint8List> _readAll(UploadSource source) async {
    final BytesBuilder builder = BytesBuilder(copy: false);
    await for (final List<int> chunk in source.openRead()) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  /// Re-slices an arbitrary byte stream into fixed-size parts (the last may be shorter).
  static Stream<Uint8List> _chunks(Stream<List<int>> input, int partSize) async* {
    final BytesBuilder buffer = BytesBuilder(copy: false);
    await for (final List<int> data in input) {
      int offset = 0;
      while (offset < data.length) {
        final int take = (partSize - buffer.length).clamp(0, data.length - offset);
        buffer.add(data.sublist(offset, offset + take));
        offset += take;
        if (buffer.length == partSize) {
          yield buffer.takeBytes();
        }
      }
    }
    if (buffer.isNotEmpty) {
      yield buffer.takeBytes();
    }
  }
}
