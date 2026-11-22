import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/media_type.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../data/datasources/file_picker_service.dart';
import '../../domain/entities/upload_draft.dart';
import '../../domain/entities/upload_source.dart';
import '../cubit/recorder_cubit.dart';
import '../cubit/upload_form_cubit.dart';
import 'issue_list.dart';

class MediaStep extends StatelessWidget {
  const MediaStep({required this.picker, super.key});

  final FilePickerService picker;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final UploadFormCubit form = context.read<UploadFormCubit>();
    return BlocListener<RecorderCubit, RecorderState>(
      listener: (BuildContext context, RecorderState state) {
        if (state is RecorderFinished) {
          form.edit((UploadDraft d) => d.copyWith(media: () => state.recording));
        }
      },
      child: BlocBuilder<UploadFormCubit, UploadFormState>(
        builder: (BuildContext context, UploadFormState state) {
          final UploadSource? media = state.draft.media;
          final UploadSource? photo = state.draft.photo;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (media == null)
                _ChooseOrRecord(picker: picker)
              else
                _ChosenFile(
                  source: media,
                  onRemove: () {
                    context.read<RecorderCubit>().discard();
                    form.edit((UploadDraft d) => d.copyWith(media: () => null));
                  },
                ),
              const SizedBox(height: 8),
              Text(l10n.mediaLimits, style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 32),
              if (photo == null)
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(l10n.addPhoto),
                    onPressed: () async {
                      final UploadSource? picked = await picker.pickPhoto();
                      if (picked != null) {
                        form.edit((UploadDraft d) => d.copyWith(photo: () => picked));
                      }
                    },
                  ),
                )
              else
                _ChosenFile(
                  source: photo,
                  onRemove: () => form.edit((UploadDraft d) => d.copyWith(photo: () => null)),
                ),
              IssueList(issues: state.visibleIssues),
            ],
          );
        },
      ),
    );
  }
}

class _ChooseOrRecord extends StatelessWidget {
  const _ChooseOrRecord({required this.picker});

  final FilePickerService picker;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<RecorderCubit, RecorderState>(
      builder: (BuildContext context, RecorderState recorder) {
        final RecorderCubit recorderCubit = context.read<RecorderCubit>();
        if (recorder is RecorderRecording) {
          return Row(
            children: <Widget>[
              const Icon(Icons.fiber_manual_record, color: Colors.red),
              const SizedBox(width: 8),
              Expanded(child: Text(l10n.recordingElapsed(_clock(recorder.elapsed)))),
              TextButton(onPressed: recorderCubit.discard, child: Text(l10n.discard)),
              FilledButton.icon(
                icon: const Icon(Icons.stop),
                label: Text(l10n.stopRecording),
                onPressed: recorderCubit.stop,
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: <Widget>[
                FilledButton.icon(
                  icon: const Icon(Icons.upload_file),
                  label: Text(l10n.chooseFile),
                  onPressed: () async {
                    final UploadFormCubit form = context.read<UploadFormCubit>();
                    final UploadSource? picked = await picker.pickMedia();
                    if (picked != null) {
                      form.edit((UploadDraft d) => d.copyWith(media: () => picked));
                    }
                  },
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.mic_none),
                  label: Text(l10n.recordVoice),
                  onPressed: recorderCubit.start,
                ),
              ],
            ),
            if (recorder is RecorderPermissionDenied) _Notice(text: l10n.micPermissionDenied),
            if (recorder is RecorderFailed) _Notice(text: l10n.recordingFailed),
          ],
        );
      },
    );
  }

  static String _clock(Duration elapsed) =>
      '${elapsed.inMinutes}:${(elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
}

class _Notice extends StatelessWidget {
  const _Notice({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(top: 8),
    child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.error)),
  );
}

class _ChosenFile extends StatelessWidget {
  const _ChosenFile({required this.source, required this.onRemove});

  final UploadSource source;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final IconData icon = switch (source.mediaType) {
      MediaType.video => Icons.videocam_outlined,
      MediaType.audio => Icons.graphic_eq,
      null => Icons.image_outlined,
    };
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(l10n.selectedFile(source.name, formatBytes(source.size))),
        trailing: TextButton(onPressed: onRemove, child: Text(l10n.removeFile)),
      ),
    );
  }
}
