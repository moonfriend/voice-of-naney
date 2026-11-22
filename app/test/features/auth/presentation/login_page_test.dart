import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:naney/features/auth/presentation/pages/login_page.dart';

import '../../../helpers/pump_localized.dart';

class _MockAuth extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockAuth auth;
  setUp(() {
    auth = _MockAuth();
    when(() => auth.signIn(any(), any())).thenAnswer((_) async {});
  });

  Future<void> pump(WidgetTester tester, AuthState state) async {
    when(() => auth.state).thenReturn(state);
    await pumpLocalized(
      tester,
      BlocProvider<AuthCubit>.value(value: auth, child: const LoginPage()),
    );
  }

  testWidgets('signs in with the typed credentials', (WidgetTester tester) async {
    await pump(tester, const AuthState(status: AuthStatus.signedOut));
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'leila@example.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'secret123');
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    verify(() => auth.signIn('leila@example.com', 'secret123')).called(1);
  });

  testWidgets('does not send an empty form', (WidgetTester tester) async {
    await pump(tester, const AuthState(status: AuthStatus.signedOut));
    await tester.tap(find.widgetWithText(FilledButton, 'Sign in'));
    verifyNever(() => auth.signIn(any(), any()));
  });

  testWidgets('explains wrong credentials', (WidgetTester tester) async {
    await pump(
      tester,
      const AuthState(status: AuthStatus.signedOut, failure: ServerFailure('invalid_credentials')),
    );
    expect(find.text('Email or password is not correct.'), findsOneWidget);
  });

  testWidgets('tells visitors that listening needs no account', (WidgetTester tester) async {
    await pump(tester, const AuthState(status: AuthStatus.signedOut));
    expect(
      find.text('Accounts are by invitation only. Listening to recordings needs no account.'),
      findsOneWidget,
    );
  });
}
