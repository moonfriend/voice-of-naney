import 'package:flutter/material.dart';

import '../../l10n/generated/app_localizations.dart';
import '../locale/language_menu_button.dart';

/// Common frame (app bar + language switch) around every page.
class AppShell extends StatelessWidget {
  const AppShell({required this.child, this.actions = const <Widget>[], super.key});

  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context).appTitle),
        actions: <Widget>[...actions, const LanguageMenuButton()],
      ),
      body: child,
    );
  }
}
