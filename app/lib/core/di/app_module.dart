import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../media/media_url_builder.dart';

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

  @singleton
  Dio apiDio(AppConfig config) => Dio(
    BaseOptions(
      baseUrl: config.apiBaseUrl.toString(),
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
    ),
  );
}
