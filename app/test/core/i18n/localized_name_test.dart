import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:naney/core/i18n/localized_name.dart';

void main() {
  group('LocalizedName.resolve', () {
    test('uses the language of the locale', () {
      const LocalizedName name = LocalizedName(en: 'Tabriz', fa: 'تبریز');
      expect(name.resolve(const Locale('en')), 'Tabriz');
      expect(name.resolve(const Locale('fa')), 'تبریز');
    });

    test('falls back to the other language when one is missing or blank', () {
      expect(const LocalizedName(en: null, fa: 'تبریز').resolve(const Locale('en')), 'تبریز');
      expect(const LocalizedName(en: 'Tabriz', fa: '  ').resolve(const Locale('fa')), 'Tabriz');
    });

    test('returns an empty string when both are missing', () {
      expect(const LocalizedName(en: null, fa: null).resolve(const Locale('fa')), '');
    });
  });

  test('fromJson reads name_en / name_fa', () {
    expect(
      LocalizedName.fromJson(const <String, Object?>{'name_en': 'Kurdish', 'name_fa': 'کرد'}),
      const LocalizedName(en: 'Kurdish', fa: 'کرد'),
    );
  });
}
