import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../features/auth/presentation/cubit/auth_cubit.dart';

abstract final class AuthRoutes {
  static const String login = '/login';
  static const String setPassword = '/set-password';
  static const String upload = '/upload';
}

/// Decides where a navigation should go given the session. Visitors can browse
/// everything except the upload flow; only invited, active profiles may upload.
String? authRedirect({required Uri location, required AuthState auth}) {
  final String path = location.path;
  if (auth.status == AuthStatus.unknown) {
    return null;
  }
  final bool signedIn = auth.status == AuthStatus.signedIn;

  if (path == AuthRoutes.upload) {
    if (!signedIn) {
      return Uri(
        path: AuthRoutes.login,
        queryParameters: <String, String>{'from': path},
      ).toString();
    }
    return auth.canUpload ? null : '/';
  }
  if (path == AuthRoutes.setPassword) {
    return signedIn ? null : AuthRoutes.login;
  }
  if (path == AuthRoutes.login && signedIn) {
    final String? from = location.queryParameters['from'];
    // Only same-app paths, never absolute URLs (no open redirects).
    final bool safeFrom = from != null && from.startsWith('/') && !from.startsWith('//');
    if (safeFrom) {
      return from;
    }
    return auth.canUpload ? AuthRoutes.upload : '/';
  }
  return null;
}

/// Lets GoRouter re-run redirects when the session changes.
class StreamRefreshListenable extends ChangeNotifier {
  StreamRefreshListenable(Stream<Object?> stream) {
    _subscription = stream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<Object?> _subscription;

  @override
  void dispose() {
    unawaited(_subscription.cancel());
    super.dispose();
  }
}
