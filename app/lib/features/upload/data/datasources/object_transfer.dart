import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/api_errors.dart';

/// Sends bytes to a presigned storage URL. Never carries our auth token.
abstract interface class ObjectTransfer {
  /// Returns the ETag the storage assigned (needed to complete multipart uploads).
  Future<String> put(
    String url,
    Uint8List bytes, {
    Map<String, String> headers = const <String, String>{},
    void Function(int sent)? onProgress,
  });
}

@LazySingleton(as: ObjectTransfer)
class DioObjectTransfer implements ObjectTransfer {
  DioObjectTransfer(@Named('storage') this._dio);

  final Dio _dio;

  @override
  Future<String> put(
    String url,
    Uint8List bytes, {
    Map<String, String> headers = const <String, String>{},
    void Function(int sent)? onProgress,
  }) => guardApiCall(() async {
    final Response<void> response = await _dio.put<void>(
      url,
      data: Stream<List<int>>.value(bytes),
      options: Options(
        headers: <String, Object?>{...headers, Headers.contentLengthHeader: bytes.length},
      ),
      onSendProgress: onProgress == null ? null : (int sent, int _) => onProgress(sent),
    );
    return response.headers.value('etag') ?? '';
  });
}
