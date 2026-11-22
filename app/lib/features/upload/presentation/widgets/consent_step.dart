import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../domain/entities/upload_draft.dart';
import '../../domain/usecases/submit_recording.dart';
import '../cubit/upload_form_cubit.dart';
import 'issue_list.dart';

/// Explicit permission from the recorded person (or family), then submission.
class ConsentStep extends StatelessWidget {
  const ConsentStep({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final UploadFormCubit form = context.read<UploadFormCubit>();
    return BlocBuilder<UploadFormCubit, UploadFormState>(
      builder: (BuildContext context, UploadFormState state) {
        final SubmissionState submission = state.submission;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.consentTitle, style: Theme.of(context).textTheme.titleMedium),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: state.draft.consent,
              onChanged:
                  state.isBusy
                      ? null
                      : (bool? value) =>
                          form.edit((UploadDraft d) => d.copyWith(consent: value ?? false)),
              title: Text(l10n.consentText),
            ),
            IssueList(issues: state.visibleIssues),
            const SizedBox(height: 16),
            if (submission is Submitting) _Progress(progress: submission.progress),
            if (submission is SubmissionFailed)
              Padding(
                padding: const EdgeInsetsDirectional.only(bottom: 12),
                child: Text(
                  '${failureMessage(l10n, submission.failure)}\n${l10n.submitFailed}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton.icon(
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(l10n.submit),
              // Enabled only once consent is given (the server checks it again).
              onPressed: state.isBusy || !state.draft.consent ? null : form.submit,
            ),
          ],
        );
      },
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.progress});

  final SubmissionProgress? progress;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final SubmissionProgress? current = progress;
    final String label = switch (current?.stage) {
      SubmissionStage.uploadingMedia ||
      null => l10n.uploadingMedia(((current?.fraction ?? 0) * 100).round()),
      SubmissionStage.uploadingPhoto => l10n.uploadingPhoto,
      SubmissionStage.savingPlace => l10n.savingPlace,
      SubmissionStage.savingRecording => l10n.savingRecording,
    };
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(label),
          const SizedBox(height: 8),
          LinearProgressIndicator(value: current?.fraction),
        ],
      ),
    );
  }
}
