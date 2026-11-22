import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/core/network/auth_token_interceptor.dart';
import 'package:naney/features/upload/data/datasources/worker_api.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';

/// Answers Dio requests from a function, so the real request encoding is exercised.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.respond);

  final ResponseBody Function(RequestOptions options, String? body) respond;
  final List<RequestOptions> requests = <RequestOptions>[];
  final List<String?> bodies = <String?>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final String? body =
        requestStream == null
            ? null
            : utf8.decode(await requestStream.expand((Uint8List b) => b).toList());
    bodies.add(body);
    return respond(options, body);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object body, {int status = 200}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: <String, List<String>>{
    Headers.contentTypeHeader: <String>[Headers.jsonContentType],
  },
);

(DioWorkerApi, _FakeAdapter) apiWith(
  ResponseBody Function(RequestOptions, String?) respond, {
  String? token = 'jwt',
}) {
  final _FakeAdapter adapter = _FakeAdapter(respond);
  final Dio dio =
      Dio(BaseOptions(baseUrl: 'https://naney.test'))
        ..httpClientAdapter = adapter
        ..interceptors.add(AuthTokenInterceptor(() => token));
  return (DioWorkerApi(dio), adapter);
}

void main() {
  test('creates an upload with the bearer token and parses a single ticket', () async {
    final (DioWorkerApi api, _FakeAdapter adapter) = apiWith(
      (_, __) => jsonBody(<String, Object?>{
        'uploadId': 'u1',
        'objectKey': 'media/x.mp3',
        'method': 'single',
        'url': 'https://r2/put',
        'headers': <String, Object?>{'content-type': 'audio/mpeg'},
      }, status: 201),
    );

    final UploadTicket ticket = await api.createUpload(
      purpose: UploadPurpose.media,
      mime: 'audio/mpeg',
      size: 10,
    );

    expect(
      ticket,
      const SingleUploadTicket(
        uploadId: 'u1',
        url: 'https://r2/put',
        headers: <String, String>{'content-type': 'audio/mpeg'},
      ),
    );
    expect(adapter.requests.single.path, '/api/uploads');
    expect(adapter.requests.single.headers['authorization'], 'Bearer jwt');
    expect(jsonDecode(adapter.bodies.single!), <String, Object?>{
      'purpose': 'media',
      'mime': 'audio/mpeg',
      'size': 10,
    });
  });

  test('parses a multipart ticket', () async {
    final (DioWorkerApi api, _) = apiWith(
      (_, __) => jsonBody(<String, Object?>{
        'uploadId': 'u2',
        'method': 'multipart',
        'partSize': 10,
        'parts': <Object?>[
          <String, Object?>{'partNumber': 1, 'url': 'p1'},
        ],
      }, status: 201),
    );
    expect(
      await api.createUpload(purpose: UploadPurpose.media, mime: 'video/mp4', size: 5),
      const MultipartUploadTicket(
        uploadId: 'u2',
        partSize: 10,
        parts: <PartTarget>[PartTarget(partNumber: 1, url: 'p1')],
      ),
    );
  });

  test('turns Worker error codes into ServerFailure', () async {
    final (DioWorkerApi api, _) = apiWith(
      (_, __) => jsonBody(<String, Object?>{'error': 'daily_limit_reached'}, status: 429),
    );
    await expectLater(
      api.createUpload(purpose: UploadPurpose.media, mime: 'audio/mpeg', size: 1),
      throwsA(const ServerFailure('daily_limit_reached')),
    );
  });

  test('sends multipart ETags on completion', () async {
    final (DioWorkerApi api, _FakeAdapter adapter) = apiWith(
      (_, __) => jsonBody(<String, Object?>{'verified': true}),
    );
    await api.completeUpload(
      'u2',
      parts: const <CompletedPart>[CompletedPart(partNumber: 1, etag: '"abc"')],
    );
    expect(adapter.requests.single.path, '/api/uploads/u2/complete');
    expect(jsonDecode(adapter.bodies.single!), <String, Object?>{
      'parts': <Object?>[
        <String, Object?>{'partNumber': 1, 'etag': '"abc"'},
      ],
    });
  });

  test('a missing boundary is null, not an error', () async {
    final (DioWorkerApi api, _) = apiWith(
      (_, __) => jsonBody(<String, Object?>{'error': 'no_boundary'}, status: 404),
    );
    expect(await api.boundary(osmType: 'node', osmId: 42), isNull);
  });

  test('searches places', () async {
    final (DioWorkerApi api, _FakeAdapter adapter) = apiWith(
      (_, __) => jsonBody(<String, Object?>{
        'results': <Object?>[
          <String, Object?>{'name': 'Tabriz'},
        ],
      }),
    );
    expect(await api.searchPlaces('Tabriz'), <Map<String, Object?>>[
      <String, Object?>{'name': 'Tabriz'},
    ]);
    expect(adapter.requests.single.queryParameters, <String, Object?>{'q': 'Tabriz'});
  });

  test('no token means no authorization header', () async {
    final (DioWorkerApi api, _FakeAdapter adapter) = apiWith(
      (_, __) => jsonBody(<String, Object?>{'results': <Object?>[]}),
      token: null,
    );
    await api.searchPlaces('Tabriz');
    expect(adapter.requests.single.headers.containsKey('authorization'), isFalse);
  });
}
