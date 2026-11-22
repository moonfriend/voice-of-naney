import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:naney/core/error/failures.dart';
import 'package:naney/features/auth/domain/entities/auth_user.dart';
import 'package:naney/features/auth/domain/repositories/auth_repository.dart';
import 'package:naney/features/auth/presentation/cubit/auth_cubit.dart';

class _MockRepo extends Mock implements AuthRepository {}

const AuthUser leila = AuthUser(id: 'u1', email: 'leila@example.com');
const UserProfile uploader = UserProfile(role: UserRole.uploader, disabled: false);
const UserProfile disabled = UserProfile(role: UserRole.uploader, disabled: true);

void main() {
  late _MockRepo repo;
  late StreamController<AuthUser?> changes;

  setUp(() {
    repo = _MockRepo();
    changes = StreamController<AuthUser?>.broadcast();
    when(() => repo.userChanges()).thenAnswer((_) => changes.stream);
    when(() => repo.currentUser).thenReturn(null);
  });

  tearDown(() => changes.close());

  blocTest<AuthCubit, AuthState>(
    'starts signed out without a session',
    build: () => AuthCubit(repo),
    act: (AuthCubit cubit) => cubit.start(),
    expect: () => <AuthState>[const AuthState(status: AuthStatus.signedOut)],
  );

  blocTest<AuthCubit, AuthState>(
    'restores an existing session with its profile',
    build: () {
      when(() => repo.currentUser).thenReturn(leila);
      when(() => repo.loadProfile('u1')).thenAnswer((_) async => uploader);
      return AuthCubit(repo);
    },
    act: (AuthCubit cubit) => cubit.start(),
    expect:
        () => <AuthState>[
          const AuthState(status: AuthStatus.signedIn, user: leila, profile: uploader),
        ],
    verify: (AuthCubit cubit) => expect(cubit.state.canUpload, isTrue),
  );

  blocTest<AuthCubit, AuthState>(
    'follows sign-in and sign-out events (e.g. from an invite link)',
    build: () {
      when(() => repo.loadProfile('u1')).thenAnswer((_) async => uploader);
      return AuthCubit(repo);
    },
    act: (AuthCubit cubit) async {
      await cubit.start();
      changes.add(leila);
      await Future<void>.delayed(Duration.zero);
      changes.add(null);
      await Future<void>.delayed(Duration.zero);
    },
    expect:
        () => <AuthState>[
          const AuthState(status: AuthStatus.signedOut),
          const AuthState(status: AuthStatus.signedIn, user: leila, profile: uploader),
          const AuthState(status: AuthStatus.signedOut),
        ],
  );

  test('disabled users and users without a profile cannot upload', () {
    expect(
      const AuthState(status: AuthStatus.signedIn, user: leila, profile: disabled).canUpload,
      isFalse,
    );
    expect(const AuthState(status: AuthStatus.signedIn, user: leila).canUpload, isFalse);
    expect(const AuthState(status: AuthStatus.signedOut).canUpload, isFalse);
  });

  blocTest<AuthCubit, AuthState>(
    'signs in and clears earlier errors',
    build: () {
      when(
        () => repo.signIn(email: 'leila@example.com', password: 'secret123'),
      ).thenAnswer((_) async {});
      return AuthCubit(repo);
    },
    seed:
        () => const AuthState(
          status: AuthStatus.signedOut,
          failure: ServerFailure('invalid_credentials'),
        ),
    act: (AuthCubit cubit) => cubit.signIn('leila@example.com', 'secret123'),
    expect:
        () => <AuthState>[
          const AuthState(status: AuthStatus.signedOut, busy: true),
          const AuthState(status: AuthStatus.signedOut),
        ],
  );

  blocTest<AuthCubit, AuthState>(
    'reports wrong credentials',
    build: () {
      when(
        () => repo.signIn(email: any(named: 'email'), password: any(named: 'password')),
      ).thenThrow(const ServerFailure('invalid_credentials'));
      return AuthCubit(repo);
    },
    seed: () => const AuthState(status: AuthStatus.signedOut),
    act: (AuthCubit cubit) => cubit.signIn('leila@example.com', 'nope'),
    expect:
        () => <AuthState>[
          const AuthState(status: AuthStatus.signedOut, busy: true),
          const AuthState(
            status: AuthStatus.signedOut,
            failure: ServerFailure('invalid_credentials'),
          ),
        ],
  );

  blocTest<AuthCubit, AuthState>(
    'rejects short passwords before calling the server',
    build: () => AuthCubit(repo),
    seed: () => const AuthState(status: AuthStatus.signedIn, user: leila, profile: uploader),
    act: (AuthCubit cubit) => cubit.setPassword('short'),
    expect:
        () => <AuthState>[
          const AuthState(
            status: AuthStatus.signedIn,
            user: leila,
            profile: uploader,
            failure: ServerFailure('weak_password'),
          ),
        ],
    verify: (_) => verifyNever(() => repo.setPassword(any())),
  );

  blocTest<AuthCubit, AuthState>(
    'sets a new password and remembers it was done',
    build: () {
      when(() => repo.setPassword('long enough')).thenAnswer((_) async {});
      return AuthCubit(repo);
    },
    seed: () => const AuthState(status: AuthStatus.signedIn, user: leila, profile: uploader),
    act: (AuthCubit cubit) => cubit.setPassword('long enough'),
    expect:
        () => <AuthState>[
          const AuthState(status: AuthStatus.signedIn, user: leila, profile: uploader, busy: true),
          const AuthState(
            status: AuthStatus.signedIn,
            user: leila,
            profile: uploader,
            passwordSet: true,
          ),
        ],
  );

  blocTest<AuthCubit, AuthState>(
    'signs out',
    build: () {
      when(() => repo.signOut()).thenAnswer((_) async {});
      return AuthCubit(repo);
    },
    seed: () => const AuthState(status: AuthStatus.signedIn, user: leila, profile: uploader),
    act: (AuthCubit cubit) => cubit.signOut(),
    expect: () => <AuthState>[const AuthState(status: AuthStatus.signedOut)],
  );
}
