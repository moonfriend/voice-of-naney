import 'dart:ui';

import 'package:flutter_bloc/flutter_bloc.dart';

/// Holds the UI language. Persian switches the whole app to right-to-left.
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit() : super(english);

  static const Locale english = Locale('en');
  static const Locale persian = Locale('fa');
  static const List<Locale> supportedLocales = <Locale>[english, persian];

  void select(Locale locale) {
    final bool isSupported = supportedLocales.any(
      (Locale supported) => supported.languageCode == locale.languageCode,
    );
    if (!isSupported) {
      return;
    }
    emit(Locale(locale.languageCode));
  }
}
