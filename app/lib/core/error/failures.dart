import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Errors the presentation layer understands. Data sources may throw anything;
/// repositories translate it into one of these via [guardRemoteCall].
sealed class Failure extends Equatable implements Exception {
  const Failure();

  @override
  List<Object?> get props => <Object?>[];
}

/// The device could not reach the server (offline, timeout).
class NetworkFailure extends Failure {
  const NetworkFailure();
}

class NotFoundFailure extends Failure {
  const NotFoundFailure();
}

/// The server rejected the request; [code] is the stable error code (e.g. `consent_required`).
class ServerFailure extends Failure {
  const ServerFailure(this.code);

  final String code;

  @override
  List<Object?> get props => <Object?>[code];
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure(this.cause);

  final Object cause;

  @override
  List<Object?> get props => <Object?>[cause];
}

const String _postgrestNoRows = 'PGRST116';
const String _raisedException = 'P0001';

Future<T> guardRemoteCall<T>(Future<T> Function() call) async {
  try {
    return await call();
  } on Failure {
    rethrow;
  } on http.ClientException {
    throw const NetworkFailure();
  } on TimeoutException {
    throw const NetworkFailure();
  } on PostgrestException catch (error) {
    if (error.code == _postgrestNoRows) {
      throw const NotFoundFailure();
    }
    // Our RPCs raise P0001 with a machine-readable message such as `consent_required`.
    throw ServerFailure(error.code == _raisedException ? error.message : (error.code ?? 'unknown'));
  } catch (error) {
    throw UnexpectedFailure(error);
  }
}
