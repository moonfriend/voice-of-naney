import 'package:flutter_test/flutter_test.dart';
import 'package:naney/core/config/app_config.dart';

void main() {
  const Map<String, String> validValues = <String, String>{
    'SUPABASE_URL': 'https://abc.supabase.co',
    'SUPABASE_PUBLISHABLE_KEY': 'sb_publishable_123',
    'API_BASE_URL': 'https://naney.example.workers.dev',
    'MAPTILER_KEY': 'maptiler-key',
  };

  Map<String, String> withValue(String key, String value) =>
      Map<String, String>.of(validValues)..[key] = value;

  group('AppConfig.fromValues', () {
    test('parses a complete set of values', () {
      final AppConfig config = AppConfig.fromValues(validValues);

      expect(config.supabaseUrl, Uri.parse('https://abc.supabase.co'));
      expect(config.supabasePublishableKey, 'sb_publishable_123');
      expect(config.apiBaseUrl, Uri.parse('https://naney.example.workers.dev'));
      expect(config.mapTilerKey, 'maptiler-key');
    });

    test('fails fast naming every missing value', () {
      expect(
        () => AppConfig.fromValues(const <String, String>{'SUPABASE_URL': ''}),
        throwsA(
          isA<AppConfigException>().having(
            (AppConfigException e) => e.missingKeys,
            'missingKeys',
            <String>['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY', 'API_BASE_URL', 'MAPTILER_KEY'],
          ),
        ),
      );
    });

    test('rejects URLs that are not absolute http(s)', () {
      expect(
        () => AppConfig.fromValues(withValue('SUPABASE_URL', 'abc.supabase.co')),
        throwsA(isA<AppConfigException>()),
      );
      expect(
        () => AppConfig.fromValues(withValue('API_BASE_URL', 'ftp://x.y')),
        throwsA(isA<AppConfigException>()),
      );
    });

    test('mapTilerKey may be empty in development, which disables tiles', () {
      final AppConfig config = AppConfig.fromValues(
        withValue('MAPTILER_KEY', ''),
        requireMapTilerKey: false,
      );
      expect(config.mapTilerKey, isEmpty);
    });
  });
}
