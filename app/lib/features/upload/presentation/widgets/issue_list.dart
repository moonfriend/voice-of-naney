import 'package:flutter/material.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/upload_draft.dart';

String issueText(AppLocalizations l10n, DraftIssue issue) => switch (issue) {
  DraftIssue.mediaMissing => l10n.issueMediaMissing,
  DraftIssue.mediaUnsupported => l10n.issueMediaUnsupported,
  DraftIssue.mediaTooLarge => l10n.issueMediaTooLarge,
  DraftIssue.photoUnsupported => l10n.issuePhotoUnsupported,
  DraftIssue.photoTooLarge => l10n.issuePhotoTooLarge,
  DraftIssue.titleMissing => l10n.issueTitleMissing,
  DraftIssue.titleTooLong => l10n.issueTitleTooLong,
  DraftIssue.kindMissing => l10n.issueKindMissing,
  DraftIssue.yearInvalid => l10n.issueYearInvalid,
  DraftIssue.tooManyTags => l10n.issueTooManyTags,
  DraftIssue.culturesMissing => l10n.issueCulturesMissing,
  DraftIssue.tooManyCultures => l10n.issueTooManyCultures,
  DraftIssue.cultureInvalid => l10n.issueCultureInvalid,
  DraftIssue.cultureDuplicate => l10n.issueCultureDuplicate,
  DraftIssue.placeMissing => l10n.issuePlaceMissing,
  DraftIssue.consentMissing => l10n.issueConsentMissing,
};

/// Shows the problems that keep the uploader from continuing.
class IssueList extends StatelessWidget {
  const IssueList({required this.issues, super.key});

  final Set<DraftIssue> issues;

  @override
  Widget build(BuildContext context) {
    if (issues.isEmpty) {
      return const SizedBox.shrink();
    }
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Color color = Theme.of(context).colorScheme.error;
    return Padding(
      padding: const EdgeInsetsDirectional.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            issues
                .map(
                  (DraftIssue issue) => Row(
                    children: <Widget>[
                      Icon(Icons.error_outline, size: 18, color: color),
                      const SizedBox(width: 6),
                      Flexible(child: Text(issueText(l10n, issue), style: TextStyle(color: color))),
                    ],
                  ),
                )
                .toList(),
      ),
    );
  }
}

String formatBytes(int bytes) {
  const int mb = 1024 * 1024;
  return bytes >= mb ? '${(bytes / mb).toStringAsFixed(1)} MB' : '${(bytes / 1024).ceil()} KB';
}
