import 'package:dio/dio.dart';

/// Adds the signed-in user's Supabase access token to Worker API calls.
class AuthTokenInterceptor extends Interceptor {
  AuthTokenInterceptor(this._accessToken);

  final String? Function() _accessToken;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final String? token = _accessToken();
    if (token != null) {
      options.headers['authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
