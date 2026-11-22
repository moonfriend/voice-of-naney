import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../media/media_url_builder.dart';
import '../network/auth_token_interceptor.dart';

/// Third-party objects the app depends on, created once at startup.
@module
abstract class AppModule {
  @singleton
  AppConfig get appConfig => AppConfig.fromEnvironment();

  /// Supabase must be initialised in `main` before the container is built.
  @singleton
  SupabaseClient get supabaseClient => Supabase.instance.client;

  @singleton
  MediaUrlBuilder mediaUrlBuilder(AppConfig config) => MediaUrlBuilder(config.apiBaseUrl);

  /// Calls our Worker API with the signed-in user's token.
  @Named('api')
  @singleton
  Dio apiDio(AppConfig config, SupabaseClient supabase) => Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl.toString(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  )..interceptors.add(AuthTokenInterceptor(() => supabase.auth.currentSession?.accessToken));

  /// Talks to presigned storage URLs; deliberately has no auth interceptor.
  @Named('storage')
  @singleton
  Dio storageDio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(minutes: 10),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );
}
