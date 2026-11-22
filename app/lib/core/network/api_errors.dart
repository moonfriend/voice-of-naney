import 'package:dio/dio.dart';

import '../error/failures.dart';

/// Runs a Worker API call and translates Dio errors into [Failure]s.
Future<T> guardApiCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on Failure {
    rethrow;
  } on DioException catch (error) {
    throw failureFromDio(error);
  } catch (error) {
    throw UnexpectedFailure(error);
  }
}

Failure failureFromDio(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionError:
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.transformTimeout:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      final Response<Object?>? response = error.response;
      if (response?.statusCode == 404) {
        return const NotFoundFailure();
      }
      final Object? data = response?.data;
      final Object? code = data is Map<String, Object?> ? data['error'] : null;
      return ServerFailure(code is String ? code : 'http_${response?.statusCode}');
    case DioExceptionType.cancel:
    case DioExceptionType.badCertificate:
    case DioExceptionType.unknown:
      return UnexpectedFailure(error);
  }
}
