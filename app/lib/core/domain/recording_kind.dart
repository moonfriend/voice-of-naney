/// Kinds of oral heritage; values match the `recording_kind` database enum.
enum RecordingKind {
  lullaby,
  poem,
  wisdom,
  murmur,
  other;

  static RecordingKind fromDb(String value) => RecordingKind.values.firstWhere(
    (RecordingKind kind) => kind.name == value,
    orElse: () => throw FormatException('Unknown recording kind: $value'),
  );
}
