import 'package:dio/dio.dart';
import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/network/api_errors.dart';
import '../../domain/entities/upload_source.dart';

typedef JsonMap = Map<String, Object?>;

class PartTarget extends Equatable {
  const PartTarget({required this.partNumber, required this.url});

  final int partNumber;
  final String url;

  @override
  List<Object?> get props => <Object?>[partNumber, url];
}

/// Where and how to send the bytes, as decided by the Worker.
sealed class UploadTicket extends Equatable {
  const UploadTicket({required this.uploadId});

  factory UploadTicket.fromJson(JsonMap json) {
    final String uploadId = json['uploadId']! as String;
    return switch (json['method']) {
      'single' => SingleUploadTicket(
        uploadId: uploadId,
        url: json['url']! as String,
        headers: (json['headers']! as Map<String, Object?>).cast<String, String>(),
      ),
      'multipart' => MultipartUploadTicket(
        uploadId: uploadId,
        partSize: (json['partSize']! as num).toInt(),
        parts:
            (json['parts']! as List<Object?>)
                .cast<JsonMap>()
                .map(
                  (JsonMap part) => PartTarget(
                    partNumber: (part['partNumber']! as num).toInt(),
                    url: part['url']! as String,
                  ),
                )
                .toList(),
      ),
      final Object? other => throw FormatException('Unknown upload method: $other'),
    };
  }

  final String uploadId;
}

class SingleUploadTicket extends UploadTicket {
  const SingleUploadTicket({required super.uploadId, required this.url, required this.headers});

  final String url;
  final Map<String, String> headers;

  @override
  List<Object?> get props => <Object?>[uploadId, url, headers];
}

class MultipartUploadTicket extends UploadTicket {
  const MultipartUploadTicket({
    required super.uploadId,
    required this.partSize,
    required this.parts,
  });

  final int partSize;
  final List<PartTarget> parts;

  @override
  List<Object?> get props => <Object?>[uploadId, partSize, parts];
}

class CompletedPart extends Equatable {
  const CompletedPart({required this.partNumber, required this.etag});

  final int partNumber;
  final String etag;

  JsonMap toJson() => <String, Object?>{'partNumber': partNumber, 'etag': etag};

  @override
  List<Object?> get props => <Object?>[partNumber, etag];
}

abstract interface class WorkerApi {
  Future<UploadTicket> createUpload({
    required UploadPurpose purpose,
    required String mime,
    required int size,
  });

  Future<void> completeUpload(
    String uploadId, {
    List<CompletedPart> parts = const <CompletedPart>[],
  });

  Future<List<JsonMap>> searchPlaces(String query);

  /// Null when OpenStreetMap has no area for the place.
  Future<JsonMap?> boundary({required String osmType, required int osmId});
}

@LazySingleton(as: WorkerApi)
class DioWorkerApi implements WorkerApi {
  DioWorkerApi(@Named('api') this._dio);

  final Dio _dio;

  @override
  Future<UploadTicket> createUpload({
    required UploadPurpose purpose,
    required String mime,
    required int size,
  }) => guardApiCall(() async {
    final Response<JsonMap> response = await _dio.post<JsonMap>(
      '/api/uploads',
      data: <String, Object?>{'purpose': purpose.name, 'mime': mime, 'size': size},
    );
    return UploadTicket.fromJson(response.data!);
  });

  @override
  Future<void> completeUpload(
    String uploadId, {
    List<CompletedPart> parts = const <CompletedPart>[],
  }) => guardApiCall(() async {
    await _dio.post<JsonMap>(
      '/api/uploads/$uploadId/complete',
      data: <String, Object?>{
        if (parts.isNotEmpty) 'parts': parts.map((CompletedPart part) => part.toJson()).toList(),
      },
    );
  });

  @override
  Future<List<JsonMap>> searchPlaces(String query) => guardApiCall(() async {
    final Response<JsonMap> response = await _dio.get<JsonMap>(
      '/api/geo/search',
      queryParameters: <String, Object?>{'q': query},
    );
    return (response.data!['results']! as List<Object?>).cast<JsonMap>();
  });

  @override
  Future<JsonMap?> boundary({required String osmType, required int osmId}) =>
      guardApiCall(() async {
        final Response<JsonMap> response = await _dio.get<JsonMap>(
          '/api/geo/boundary',
          queryParameters: <String, Object?>{'osm_type': osmType, 'osm_id': osmId},
          options: Options(validateStatus: (int? status) => status == 200 || status == 404),
        );
        return response.statusCode == 404 ? null : response.data;
      });
}
