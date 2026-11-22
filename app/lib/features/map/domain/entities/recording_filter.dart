import 'package:equatable/equatable.dart';

import '../../../../core/domain/recording_kind.dart';

/// What the visitor wants to see. Empty sets mean "no restriction".
class RecordingFilter extends Equatable {
  const RecordingFilter({
    this.cultureIds = const <int>{},
    this.languageIds = const <int>{},
    this.kinds = const <RecordingKind>{},
    this.tag,
  });

  final Set<int> cultureIds;
  final Set<int> languageIds;
  final Set<RecordingKind> kinds;
  final String? tag;

  bool get isEmpty =>
      cultureIds.isEmpty && languageIds.isEmpty && kinds.isEmpty && normalizedTag == null;

  int get activeCount =>
      cultureIds.length + languageIds.length + kinds.length + (normalizedTag == null ? 0 : 1);

  /// Tags are matched exactly in the database, so whitespace is trimmed and blanks ignored.
  String? get normalizedTag {
    final String? trimmed = tag?.trim();
    return (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  }

  RecordingFilter copyWith({
    Set<int>? cultureIds,
    Set<int>? languageIds,
    Set<RecordingKind>? kinds,
    String? Function()? tag,
  }) => RecordingFilter(
    cultureIds: cultureIds ?? this.cultureIds,
    languageIds: languageIds ?? this.languageIds,
    kinds: kinds ?? this.kinds,
    tag: tag != null ? tag() : this.tag,
  );

  @override
  List<Object?> get props => <Object?>[cultureIds, languageIds, kinds, normalizedTag];
}
