import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/recording_kind.dart';
import '../../../../core/widgets/recording_kind_label.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../../../lookups/domain/entities/lookup_item.dart';
import '../../domain/entities/recording_filter.dart';
import '../cubit/filter_draft_cubit.dart';

/// Opens the filter editor and returns the applied filter (null when dismissed).
Future<RecordingFilter?> showFilterSheet(
  BuildContext context, {
  required RecordingFilter initial,
  required List<LookupItem> cultures,
  required List<LookupItem> languages,
}) => showModalBottomSheet<RecordingFilter>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder:
      (BuildContext context) => BlocProvider<FilterDraftCubit>(
        create: (_) => FilterDraftCubit(initial),
        child: FilterSheet(cultures: cultures, languages: languages),
      ),
);

class FilterSheet extends StatelessWidget {
  const FilterSheet({required this.cultures, required this.languages, super.key});

  final List<LookupItem> cultures;
  final List<LookupItem> languages;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Locale locale = Localizations.localeOf(context);
    return BlocBuilder<FilterDraftCubit, RecordingFilter>(
      builder: (BuildContext context, RecordingFilter filter) {
        final FilterDraftCubit draft = context.read<FilterDraftCubit>();
        return SafeArea(
          child: Padding(
            padding: EdgeInsetsDirectional.only(
              start: 16,
              end: 16,
              bottom: 16 + MediaQuery.viewInsetsOf(context).bottom,
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  _Section(
                    title: l10n.filterKinds,
                    chips:
                        RecordingKind.values
                            .map(
                              (RecordingKind kind) => FilterChip(
                                label: Text(recordingKindLabel(l10n, kind)),
                                selected: filter.kinds.contains(kind),
                                onSelected: (_) => draft.toggleKind(kind),
                              ),
                            )
                            .toList(),
                  ),
                  if (cultures.isNotEmpty)
                    _Section(
                      title: l10n.filterCultures,
                      chips:
                          cultures
                              .map(
                                (LookupItem item) => FilterChip(
                                  label: Text(item.name.resolve(locale)),
                                  selected: filter.cultureIds.contains(item.id),
                                  onSelected: (_) => draft.toggleCulture(item.id),
                                ),
                              )
                              .toList(),
                    ),
                  if (languages.isNotEmpty)
                    _Section(
                      title: l10n.filterLanguages,
                      chips:
                          languages
                              .map(
                                (LookupItem item) => FilterChip(
                                  label: Text(item.name.resolve(locale)),
                                  selected: filter.languageIds.contains(item.id),
                                  onSelected: (_) => draft.toggleLanguage(item.id),
                                ),
                              )
                              .toList(),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: filter.tag ?? '',
                    decoration: InputDecoration(
                      labelText: l10n.filterTag,
                      border: const OutlineInputBorder(),
                    ),
                    onChanged: draft.setTag,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: <Widget>[
                      TextButton(onPressed: draft.clear, child: Text(l10n.filterClear)),
                      const Spacer(),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(filter),
                        child: Text(l10n.filterApply),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.chips});

  final String title;
  final List<Widget> chips;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsetsDirectional.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: chips),
      ],
    ),
  );
}
