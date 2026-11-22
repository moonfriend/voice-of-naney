import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../l10n/generated/app_localizations.dart';
import '../../../lookups/domain/entities/lookup_item.dart';
import '../../../lookups/presentation/cubit/lookups_cubit.dart';
import '../../domain/entities/culture_choice.dart';
import '../../domain/entities/upload_draft.dart';
import '../cubit/upload_form_cubit.dart';
import 'issue_list.dart';

const int _otherOption = -1;

/// 1–3 cultures/ethnicities (for mixed or moved families) plus a free-text origin note.
class CulturesStep extends StatelessWidget {
  const CulturesStep({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final UploadFormCubit form = context.read<UploadFormCubit>();
    final List<LookupItem> cultures = context.select(
      (LookupsCubit cubit) => cubit.state.activeCultures,
    );
    return BlocBuilder<UploadFormCubit, UploadFormState>(
      builder: (BuildContext context, UploadFormState state) {
        final List<CultureChoice> chosen = state.draft.cultures;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(l10n.culturesIntro),
            const SizedBox(height: 16),
            for (int index = 0; index < chosen.length; index += 1)
              _CultureRow(
                // Re-keyed when rows are added or removed so text fields never show stale values.
                key: ValueKey<String>('$index/${chosen.length}'),
                index: index,
                choice: chosen[index],
                cultures: cultures,
              ),
            if (chosen.length < CultureChoice.maxPerRecording)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: Text(l10n.addCulture),
                  onPressed:
                      () => form.addCulture(
                        cultures.isEmpty
                            ? const CultureChoice.other('')
                            : CultureChoice.listed(cultures.first.id),
                      ),
                ),
              ),
            const SizedBox(height: 16),
            TextFormField(
              initialValue: state.draft.originNote,
              maxLines: 3,
              onChanged: (String v) => form.edit((UploadDraft d) => d.copyWith(originNote: v)),
              decoration: InputDecoration(
                labelText: l10n.fieldOriginNote,
                hintText: l10n.fieldOriginNoteHint,
                border: const OutlineInputBorder(),
              ),
            ),
            IssueList(issues: state.visibleIssues),
          ],
        );
      },
    );
  }
}

class _CultureRow extends StatelessWidget {
  const _CultureRow({required this.index, required this.choice, required this.cultures, super.key});

  final int index;
  final CultureChoice choice;
  final List<LookupItem> cultures;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    final UploadFormCubit form = context.read<UploadFormCubit>();
    final bool isOther = choice.cultureId == null;
    return Padding(
      padding: const EdgeInsetsDirectional.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Expanded(
            child: Column(
              children: <Widget>[
                DropdownButtonFormField<int>(
                  value: isOther ? _otherOption : choice.cultureId,
                  decoration: InputDecoration(
                    labelText: l10n.cultureLabel(index + 1),
                    border: const OutlineInputBorder(),
                  ),
                  items: <DropdownMenuItem<int>>[
                    ...cultures.map(
                      (LookupItem item) => DropdownMenuItem<int>(
                        value: item.id,
                        child: Text(item.name.resolve(locale)),
                      ),
                    ),
                    DropdownMenuItem<int>(
                      value: _otherOption,
                      child: Text(l10n.cultureOtherOption),
                    ),
                  ],
                  onChanged:
                      (int? value) => form.replaceCulture(
                        index,
                        value == null || value == _otherOption
                            ? const CultureChoice.other('')
                            : CultureChoice.listed(value),
                      ),
                ),
                if (isOther)
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 8),
                    child: TextFormField(
                      initialValue: choice.otherText,
                      onChanged: (String v) => form.replaceCulture(index, CultureChoice.other(v)),
                      decoration: InputDecoration(
                        labelText: l10n.cultureOtherText,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: l10n.removeCulture,
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => form.removeCulture(index),
          ),
        ],
      ),
    );
  }
}
