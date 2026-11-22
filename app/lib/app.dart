import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';

import 'core/locale/locale_cubit.dart';
import 'core/theme/app_theme.dart';
import 'l10n/generated/app_localizations.dart';

class NaneyApp extends StatelessWidget {
  const NaneyApp({required this.localeCubit, required this.router, super.key});

  final LocaleCubit localeCubit;
  final GoRouter router;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<LocaleCubit>.value(
      value: localeCubit,
      child: BlocBuilder<LocaleCubit, Locale>(
        builder:
            (BuildContext context, Locale locale) => MaterialApp.router(
              onGenerateTitle: (BuildContext context) => AppLocalizations.of(context).appTitle,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light(),
              darkTheme: AppTheme.dark(),
              locale: locale,
              supportedLocales: LocaleCubit.supportedLocales,
              localizationsDelegates: const <LocalizationsDelegate<Object>>[
                AppLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              routerConfig: router,
            ),
      ),
    );
  }
}
