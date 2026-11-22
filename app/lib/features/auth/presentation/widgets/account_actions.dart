import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/auth_redirect.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../cubit/auth_cubit.dart';

/// App-bar actions: uploaders get "Add a recording" and sign-out; visitors a quiet sign-in.
class AccountActions extends StatelessWidget {
  const AccountActions({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        if (state.status != AuthStatus.signedIn) {
          return TextButton(
            onPressed: () => context.go(AuthRoutes.login),
            child: Text(l10n.signIn),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (state.canUpload)
              FilledButton.tonalIcon(
                icon: const Icon(Icons.add),
                label: Text(l10n.addRecording),
                onPressed: () => context.go(AuthRoutes.upload),
              ),
            PopupMenuButton<void>(
              tooltip: l10n.account,
              icon: const Icon(Icons.account_circle_outlined),
              itemBuilder:
                  (BuildContext context) => <PopupMenuEntry<void>>[
                    PopupMenuItem<void>(enabled: false, child: Text(state.user?.email ?? '')),
                    PopupMenuItem<void>(
                      onTap: () => context.read<AuthCubit>().signOut(),
                      child: Text(l10n.signOut),
                    ),
                  ],
            ),
          ],
        );
      },
    );
  }
}
