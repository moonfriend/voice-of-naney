import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/features/upload/data/datasources/object_transfer.dart';
import 'package:naney/features/upload/data/datasources/worker_api.dart';
import 'package:naney/features/upload/data/repositories/file_upload_repository_impl.dart';
import 'package:naney/features/upload/domain/entities/upload_source.dart';

class _Api extends Mock implements WorkerApi {}

class _Transfer extends Mock implements ObjectTransfer {}

/// A source that delivers its bytes in awkward chunk sizes, like a real file stream.
UploadSource chunkedSource(int size, {String mime = 'video/mp4', int chunk = 3}) {
  final Uint8List bytes = Uint8List.fromList(List<int>.generate(size, (int i) => i % 256));
  return UploadSource(
    name: 'v.mp4',
    mime: mime,
    size: size,
    openRead: () async* {
      for (int offset = 0; offset < size; offset += chunk) {
        yield bytes.sublist(offset, (offset + chunk).clamp(0, size));
      }
    },
  );
}

void main() {
  late _Api api;
  late _Transfer transfer;
  late FileUploadRepositoryImpl repository;
  final List<int> retryAttempts = <int>[];

  setUpAll(() {
    registerFallbackValue(UploadPurpose.media);
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    api = _Api();
    transfer = _Transfer();
    retryAttempts.clear();
    repository = FileUploadRepositoryImpl(
      api,
      transfer,
      retryDelay: (int attempt) async => retryAttempts.add(attempt),
    );
    when(() => api.completeUpload(any(), parts: any(named: 'parts'))).thenAnswer((_) async {});
  });

  test('small files go up in one PUT with the signed content type', () async {
    when(
      () => api.createUpload(purpose: UploadPurpose.media, mime: 'audio/mpeg', size: 10),
    ).thenAnswer(
      (_) async => const SingleUploadTicket(
        uploadId: 'u1',
        url: 'https://r2/put',
        headers: <String, String>{'content-type': 'audio/mpeg'},
      ),
    );
    when(
      () => transfer.put(
        any(),
        any(),
        headers: any(named: 'headers'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenAnswer((_) async => 'etag');

    final String id = await repository.upload(
      chunkedSource(10, mime: 'audio/mpeg'),
      UploadPurpose.media,
    );

    expect(id, 'u1');
    final List<Object?> captured =
        verify(
          () => transfer.put(
            'https://r2/put',
            captureAny(),
            headers: captureAny(named: 'headers'),
            onProgress: any(named: 'onProgress'),
          ),
        ).captured;
    expect((captured[0]! as Uint8List).length, 10);
    expect(captured[1], <String, String>{'content-type': 'audio/mpeg'});
    verify(() => api.completeUpload('u1')).called(1);
  });

  test('large files are split into exact parts and completed with their ETags', () async {
    when(
      () => api.createUpload(
        purpose: any(named: 'purpose'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const MultipartUploadTicket(
        uploadId: 'u2',
        partSize: 4,
        parts: <PartTarget>[
          PartTarget(partNumber: 1, url: 'p1'),
          PartTarget(partNumber: 2, url: 'p2'),
          PartTarget(partNumber: 3, url: 'p3'),
        ],
      ),
    );
    final Map<String, int> sizes = <String, int>{};
    when(() => transfer.put(any(), any(), onProgress: any(named: 'onProgress'))).thenAnswer((
      Invocation call,
    ) async {
      final String url = call.positionalArguments[0] as String;
      sizes[url] = (call.positionalArguments[1] as Uint8List).length;
      return 'etag-$url';
    });

    await repository.upload(chunkedSource(10), UploadPurpose.media);

    expect(sizes, <String, int>{'p1': 4, 'p2': 4, 'p3': 2});
    final List<CompletedPart> parts =
        verify(() => api.completeUpload('u2', parts: captureAny(named: 'parts'))).captured.single
            as List<CompletedPart>;
    expect(parts, const <CompletedPart>[
      CompletedPart(partNumber: 1, etag: 'etag-p1'),
      CompletedPart(partNumber: 2, etag: 'etag-p2'),
      CompletedPart(partNumber: 3, etag: 'etag-p3'),
    ]);
  });

  test('a failed part is retried on its own', () async {
    when(
      () => api.createUpload(
        purpose: any(named: 'purpose'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const MultipartUploadTicket(
        uploadId: 'u3',
        partSize: 5,
        parts: <PartTarget>[
          PartTarget(partNumber: 1, url: 'p1'),
          PartTarget(partNumber: 2, url: 'p2'),
        ],
      ),
    );
    int p2Calls = 0;
    when(() => transfer.put(any(), any(), onProgress: any(named: 'onProgress'))).thenAnswer((
      Invocation call,
    ) async {
      if (call.positionalArguments[0] == 'p2' && p2Calls++ < 2) {
        throw const NetworkFailure();
      }
      return 'etag';
    });

    await repository.upload(chunkedSource(10), UploadPurpose.media);

    expect(p2Calls, 3);
    expect(retryAttempts, <int>[1, 2]);
    verify(() => transfer.put('p1', any(), onProgress: any(named: 'onProgress'))).called(1);
  });

  test('gives up after three attempts', () async {
    when(
      () => api.createUpload(
        purpose: any(named: 'purpose'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const SingleUploadTicket(uploadId: 'u4', url: 'x', headers: <String, String>{}),
    );
    when(
      () => transfer.put(
        any(),
        any(),
        headers: any(named: 'headers'),
        onProgress: any(named: 'onProgress'),
      ),
    ).thenThrow(const NetworkFailure());

    await expectLater(
      repository.upload(chunkedSource(3), UploadPurpose.media),
      throwsA(isA<NetworkFailure>()),
    );
    verify(
      () => transfer.put(
        any(),
        any(),
        headers: any(named: 'headers'),
        onProgress: any(named: 'onProgress'),
      ),
    ).called(3);
    verifyNever(() => api.completeUpload(any(), parts: any(named: 'parts')));
  });

  test('reports progress across parts as total bytes sent', () async {
    when(
      () => api.createUpload(
        purpose: any(named: 'purpose'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const MultipartUploadTicket(
        uploadId: 'u5',
        partSize: 5,
        parts: <PartTarget>[
          PartTarget(partNumber: 1, url: 'p1'),
          PartTarget(partNumber: 2, url: 'p2'),
        ],
      ),
    );
    when(() => transfer.put(any(), any(), onProgress: any(named: 'onProgress'))).thenAnswer((
      Invocation call,
    ) async {
      final void Function(int)? progress = call.namedArguments[#onProgress] as void Function(int)?;
      progress?.call((call.positionalArguments[1] as Uint8List).length);
      return 'etag';
    });
    final List<int> progress = <int>[];

    await repository.upload(chunkedSource(10), UploadPurpose.media, onProgress: progress.add);

    expect(progress, <int>[5, 10]);
  });

  test('a file that does not match its declared size fails', () async {
    when(
      () => api.createUpload(
        purpose: any(named: 'purpose'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const MultipartUploadTicket(
        uploadId: 'u6',
        partSize: 5,
        parts: <PartTarget>[
          PartTarget(partNumber: 1, url: 'p1'),
          PartTarget(partNumber: 2, url: 'p2'),
        ],
      ),
    );
    when(
      () => transfer.put(any(), any(), onProgress: any(named: 'onProgress')),
    ).thenAnswer((_) async => 'etag');

    await expectLater(
      repository.upload(chunkedSource(4), UploadPurpose.media),
      throwsA(isA<UnexpectedFailure>()),
    );
  });

  test('a file that can no longer be read asks the user to choose it again', () async {
    when(
      () => api.createUpload(
        purpose: any(named: 'purpose'),
        mime: any(named: 'mime'),
        size: any(named: 'size'),
      ),
    ).thenAnswer(
      (_) async => const SingleUploadTicket(uploadId: 'u7', url: 'x', headers: <String, String>{}),
    );
    final UploadSource consumed = UploadSource(
      name: 'v.mp4',
      mime: 'video/mp4',
      size: 3,
      openRead: () => Stream<List<int>>.error(StateError('file_must_be_chosen_again')),
    );
    await expectLater(
      repository.upload(consumed, UploadPurpose.media),
      throwsA(const ServerFailure('file_must_be_chosen_again')),
    );
  });
}
