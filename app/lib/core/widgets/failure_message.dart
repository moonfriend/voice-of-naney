import '../../l10n/generated/app_localizations.dart';
import '../error/failures.dart';

/// User-facing text for a failure. Server codes we know get specific messages.
String failureMessage(AppLocalizations l10n, Failure failure) => switch (failure) {
  NetworkFailure() => l10n.errorNetwork,
  ServerFailure(code: 'invalid_credentials') => l10n.errorInvalidCredentials,
  ServerFailure(code: 'weak_password') => l10n.errorWeakPassword,
  ServerFailure(code: 'daily_limit_reached') => l10n.dailyLimitReached,
  ServerFailure(code: 'file_must_be_chosen_again') => l10n.fileMustBeChosenAgain,
  _ => l10n.errorGeneric,
};
