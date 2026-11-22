import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/recording_kind.dart';
import '../../../../core/widgets/recording_kind_label.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../lookups/domain/entities/lookup_item.dart';
import '../../../lookups/presentation/cubit/lookups_cubit.dart';
import '../../domain/entities/upload_draft.dart';
import '../cubit/upload_form_cubit.dart';
import 'issue_list.dart';

const int _otherOption = -1;

class DetailsStep extends StatelessWidget {
  const DetailsStep({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final UploadFormCubit form = context.read<UploadFormCubit>();
    final List<LookupItem> languages = context.select(
      (LookupsCubit cubit) => cubit.state.activeLanguages,
    );
    return BlocBuilder<UploadFormCubit, UploadFormState>(
      builder: (BuildContext context, UploadFormState state) {
        final UploadDraft draft = state.draft;
        final int? languageValue = draft.languageOtherSelected ? _otherOption : draft.languageId;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            _Field(
              label: l10n.fieldTitle,
              initial: draft.title,
              onChanged: (String v) => form.edit((UploadDraft d) => d.copyWith(title: v)),
            ),
            Text(l10n.fieldKind, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  RecordingKind.values
                      .map(
                        (RecordingKind kind) => ChoiceChip(
                          label: Text(recordingKindLabel(l10n, kind)),
                          selected: draft.kind == kind,
                          onSelected:
                              (_) => form.edit((UploadDraft d) => d.copyWith(kind: () => kind)),
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 16),
            _Field(
              label: l10n.fieldPerformer,
              hint: l10n.fieldPerformerHint,
              initial: draft.performerName,
              onChanged: (String v) => form.edit((UploadDraft d) => d.copyWith(performerName: v)),
            ),
            _Field(
              label: l10n.fieldYear,
              initial: draft.yearRecorded?.toString() ?? '',
              keyboardType: TextInputType.number,
              onChanged:
                  (String v) => form.edit(
                    (UploadDraft d) => d.copyWith(yearRecorded: () => int.tryParse(v.trim())),
                  ),
            ),
            DropdownButtonFormField<int>(
              value: languageValue,
              decoration: InputDecoration(
                labelText: l10n.fieldLanguage,
                border: const OutlineInputBorder(),
              ),
              items: <DropdownMenuItem<int>>[
                ...languages.map(
                  (LookupItem language) => DropdownMenuItem<int>(
                    value: language.id,
                    child: Text(language.name.resolve(locale)),
                  ),
                ),
                DropdownMenuItem<int>(value: _otherOption, child: Text(l10n.languageOtherOption)),
              ],
              onChanged:
                  (int? value) => form.edit(
                    (UploadDraft d) => d.copyWith(
                      languageId: () => value == _otherOption ? null : value,
                      languageOtherSelected: value == _otherOption,
                    ),
                  ),
            ),
            const SizedBox(height: 16),
            if (draft.languageOtherSelected)
              _Field(
                label: l10n.fieldLanguageOther,
                initial: draft.languageOther,
                onChanged:
                    (String v) => form.edit((UploadDraft d) => d.copyWith(languageOther: () => v)),
              ),
            _Field(
              label: l10n.fieldTags,
              initial: draft.tags.join(', '),
              onChanged:
                  (String v) =>
                      form.edit((UploadDraft d) => d.copyWith(tags: v.split(RegExp('[,،]')))),
            ),
            _Field(
              label: l10n.fieldDescription,
              initial: draft.description,
              maxLines: 3,
              onChanged: (String v) => form.edit((UploadDraft d) => d.copyWith(description: v)),
            ),
            _Field(
              label: l10n.fieldTranscript,
              initial: draft.transcript,
              maxLines: 6,
              onChanged: (String v) => form.edit((UploadDraft d) => d.copyWith(transcript: v)),
            ),
            IssueList(issues: state.visibleIssues),
          ],
        );
      },
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.label,
    required this.initial,
    required this.onChanged,
    this.hint,
    this.maxLines = 1,
    this.keyboardType,
  });

  final String label;
  final String? hint;
  final String initial;
  final ValueChanged<String> onChanged;
  final int maxLines;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 16),
    child: TextFormField(
      initialValue: initial,
      onChanged: onChanged,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
    ),
  );
}
