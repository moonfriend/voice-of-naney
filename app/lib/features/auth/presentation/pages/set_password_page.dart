import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/auth_redirect.dart';
import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_card.dart';

/// Where invite links land: the invited person chooses their password.
class SetPasswordPage extends StatefulWidget {
  const SetPasswordPage({super.key});

  @override
  State<SetPasswordPage> createState() => _SetPasswordPageState();
}

class _SetPasswordPageState extends State<SetPasswordPage> {
  final TextEditingController password = TextEditingController();

  @override
  void dispose() {
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder:
          (BuildContext context, AuthState state) => AuthCard(
            title: l10n.setPasswordTitle,
            hint: state.passwordSet ? l10n.passwordSaved : l10n.setPasswordHint,
            child:
                state.passwordSet
                    ? FilledButton(
                      onPressed: () => context.go(AuthRoutes.upload),
                      child: Text(l10n.addRecording),
                    )
                    : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        TextField(
                          controller: password,
                          obscureText: true,
                          autofillHints: const <String>[AutofillHints.newPassword],
                          textDirection: TextDirection.ltr,
                          decoration: InputDecoration(
                            labelText: l10n.newPassword,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        if (state.failure != null) ...<Widget>[
                          const SizedBox(height: 12),
                          Text(
                            failureMessage(l10n, state.failure!),
                            style: TextStyle(color: Theme.of(context).colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed:
                              state.busy
                                  ? null
                                  : () => context.read<AuthCubit>().setPassword(password.text),
                          child: Text(l10n.savePassword),
                        ),
                      ],
                    ),
          ),
    );
  }
}
