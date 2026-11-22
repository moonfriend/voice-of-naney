import 'package:equatable/equatable.dart';

/// Thrown when the build was made without the values from `app.public.env`.
class AppConfigException implements Exception {
  const AppConfigException(this.message, {this.missingKeys = const <String>[]});

  final String message;
  final List<String> missingKeys;

  @override
  String toString() => 'AppConfigException: $message';
}

/// Public, build-time configuration (`--dart-define-from-file`).
///
/// Only publishable values may live here: everything compiled into the app is
/// readable by anyone who downloads it.
class AppConfig extends Equatable {
  const AppConfig({
    required this.supabaseUrl,
    required this.supabasePublishableKey,
    required this.apiBaseUrl,
    required this.mapTilerKey,
  });

  /// Validates raw values and fails fast, so a misconfigured build never starts.
  factory AppConfig.fromValues(Map<String, String> values, {bool requireMapTilerKey = true}) {
    final List<String> requiredKeys = <String>[
      supabaseUrlKey,
      supabasePublishableKeyKey,
      apiBaseUrlKey,
      if (requireMapTilerKey) mapTilerKeyKey,
    ];
    final List<String> missingKeys =
        requiredKeys.where((String key) => (values[key] ?? '').trim().isEmpty).toList();
    if (missingKeys.isNotEmpty) {
      throw AppConfigException(
        'Missing build values: ${missingKeys.join(', ')}',
        missingKeys: missingKeys,
      );
    }
    return AppConfig(
      supabaseUrl: _parseHttpUrl(supabaseUrlKey, values[supabaseUrlKey]!),
      supabasePublishableKey: values[supabasePublishableKeyKey]!.trim(),
      apiBaseUrl: _parseHttpUrl(apiBaseUrlKey, values[apiBaseUrlKey]!),
      mapTilerKey: (values[mapTilerKeyKey] ?? '').trim(),
    );
  }

  /// Reads the values compiled in via `--dart-define-from-file`.
  factory AppConfig.fromEnvironment() => AppConfig.fromValues(const <String, String>{
    supabaseUrlKey: String.fromEnvironment(supabaseUrlKey),
    supabasePublishableKeyKey: String.fromEnvironment(supabasePublishableKeyKey),
    apiBaseUrlKey: String.fromEnvironment(apiBaseUrlKey),
    mapTilerKeyKey: String.fromEnvironment(mapTilerKeyKey),
  }, requireMapTilerKey: const bool.fromEnvironment('dart.vm.product'));

  static const String supabaseUrlKey = 'SUPABASE_URL';
  static const String supabasePublishableKeyKey = 'SUPABASE_PUBLISHABLE_KEY';
  static const String apiBaseUrlKey = 'API_BASE_URL';
  static const String mapTilerKeyKey = 'MAPTILER_KEY';

  final Uri supabaseUrl;
  final String supabasePublishableKey;
  final Uri apiBaseUrl;

  /// Empty in development builds without a key; the map then shows no base tiles.
  final String mapTilerKey;

  static Uri _parseHttpUrl(String key, String raw) {
    final Uri? uri = Uri.tryParse(raw.trim());
    final bool isHttp = uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
    if (!isHttp || uri.host.isEmpty) {
      throw AppConfigException('$key must be an absolute http(s) URL');
    }
    return uri;
  }

  @override
  List<Object?> get props => <Object?>[
    supabaseUrl,
    supabasePublishableKey,
    apiBaseUrl,
    mapTilerKey,
  ];
}
