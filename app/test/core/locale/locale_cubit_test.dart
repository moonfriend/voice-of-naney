import 'dart:ui';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:naney/core/locale/locale_cubit.dart';

void main() {
  group('LocaleCubit', () {
    test('starts in English', () {
      expect(LocaleCubit().state, const Locale('en'));
    });

    blocTest<LocaleCubit, Locale>(
      'switches to Persian',
      build: LocaleCubit.new,
      act: (LocaleCubit cubit) => cubit.select(const Locale('fa')),
      expect: () => <Locale>[const Locale('fa')],
    );

    blocTest<LocaleCubit, Locale>(
      'ignores unsupported locales',
      build: LocaleCubit.new,
      act: (LocaleCubit cubit) => cubit.select(const Locale('de')),
      expect: () => <Locale>[],
    );
  });
}
