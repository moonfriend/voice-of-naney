import '../../l10n/generated/app_localizations.dart';
import '../domain/recording_kind.dart';

String recordingKindLabel(AppLocalizations l10n, RecordingKind kind) => switch (kind) {
  RecordingKind.lullaby => l10n.kindLullaby,
  RecordingKind.poem => l10n.kindPoem,
  RecordingKind.wisdom => l10n.kindWisdom,
  RecordingKind.murmur => l10n.kindMurmur,
  RecordingKind.other => l10n.kindOther,
};
