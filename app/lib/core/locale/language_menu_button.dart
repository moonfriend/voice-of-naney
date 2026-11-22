import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../l10n/generated/app_localizations.dart';
import 'locale_cubit.dart';

class LanguageMenuButton extends StatelessWidget {
  const LanguageMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return PopupMenuButton<Locale>(
      tooltip: l10n.languageMenuTooltip,
      icon: const Icon(Icons.translate),
      onSelected: context.read<LocaleCubit>().select,
      itemBuilder:
          (BuildContext context) => <PopupMenuEntry<Locale>>[
            PopupMenuItem<Locale>(value: LocaleCubit.english, child: Text(l10n.languageEnglish)),
            PopupMenuItem<Locale>(value: LocaleCubit.persian, child: Text(l10n.languagePersian)),
          ],
    );
  }
}
