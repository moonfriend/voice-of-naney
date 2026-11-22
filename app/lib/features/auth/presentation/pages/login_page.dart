import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/widgets/failure_message.dart';
import '../../../../l10n/generated/app_localizations.dart';
import '../cubit/auth_cubit.dart';
import '../widgets/auth_card.dart';

/// Email + password sign-in for invited uploaders. Redirects happen in the router.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

/// The State only owns text controllers (UI resources); session state is in [AuthCubit].
class _LoginPageState extends State<LoginPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = AppLocalizations.of(context);
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (BuildContext context, AuthState state) {
        void submit() {
          if (_formKey.currentState?.validate() ?? false) {
            context.read<AuthCubit>().signIn(email.text, password.text);
          }
        }

        return AuthCard(
          title: l10n.signInTitle,
          hint: l10n.signInHint,
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  TextFormField(
                    controller: email,
                    decoration: InputDecoration(
                      labelText: l10n.email,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const <String>[AutofillHints.email],
                    textDirection: TextDirection.ltr,
                    validator: (String? value) => (value ?? '').contains('@') ? null : l10n.email,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: password,
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      border: const OutlineInputBorder(),
                    ),
                    obscureText: true,
                    autofillHints: const <String>[AutofillHints.password],
                    textDirection: TextDirection.ltr,
                    onFieldSubmitted: (_) => submit(),
                    validator: (String? value) => (value ?? '').isEmpty ? l10n.password : null,
                  ),
                  if (state.failure != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Text(
                      failureMessage(l10n, state.failure!),
                      style: TextStyle(color: Theme.of(context).colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(onPressed: state.busy ? null : submit, child: Text(l10n.signIn)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
