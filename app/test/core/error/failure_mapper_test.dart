import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:naney/core/error/failures.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('guardRemoteCall', () {
    test('returns the value on success', () async {
      expect(await guardRemoteCall(() async => 42), 42);
    });

    test('maps connectivity problems to NetworkFailure', () async {
      await expectLater(
        guardRemoteCall<void>(() async => throw http.ClientException('offline')),
        throwsA(isA<NetworkFailure>()),
      );
      await expectLater(
        guardRemoteCall<void>(() async => throw TimeoutException('slow')),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('maps "no rows" from PostgREST to NotFoundFailure', () async {
      await expectLater(
        guardRemoteCall<void>(
          () async => throw const PostgrestException(message: 'no rows', code: 'PGRST116'),
        ),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('keeps the database error code for other PostgREST errors', () async {
      await expectLater(
        guardRemoteCall<void>(
          () async => throw const PostgrestException(message: 'consent_required', code: 'P0001'),
        ),
        throwsA(
          isA<ServerFailure>().having((ServerFailure f) => f.code, 'code', 'consent_required'),
        ),
      );
    });

    test('passes existing failures through untouched', () async {
      await expectLater(
        guardRemoteCall<void>(() async => throw const NotFoundFailure()),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('wraps anything else as UnexpectedFailure', () async {
      await expectLater(
        guardRemoteCall<void>(() async => throw StateError('bug')),
        throwsA(isA<UnexpectedFailure>()),
      );
    });
  });
}
