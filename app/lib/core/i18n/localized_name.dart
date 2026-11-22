import 'dart:ui';

import 'package:equatable/equatable.dart';

/// A name stored in English and Persian; either may be missing.
class LocalizedName extends Equatable {
  const LocalizedName({required this.en, required this.fa});

  factory LocalizedName.fromJson(Map<String, Object?> json, {String prefix = 'name'}) =>
      LocalizedName(en: json['${prefix}_en'] as String?, fa: json['${prefix}_fa'] as String?);

  final String? en;
  final String? fa;

  /// Prefers the UI language and falls back to the other one, so nothing renders blank.
  String resolve(Locale locale) {
    final String? preferred = locale.languageCode == 'fa' ? fa : en;
    final String? fallback = locale.languageCode == 'fa' ? en : fa;
    for (final String? candidate in <String?>[preferred, fallback]) {
      if (candidate != null && candidate.trim().isNotEmpty) {
        return candidate;
      }
    }
    return '';
  }

  @override
  List<Object?> get props => <Object?>[en, fa];
}
