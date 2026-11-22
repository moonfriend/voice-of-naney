import 'package:flutter_test/flutter_test.dart';
import 'package:naney/core/router/auth_redirect.dart';
import 'package:naney/features/auth/domain/entities/auth_user.dart';
import 'package:naney/features/auth/presentation/cubit/auth_cubit.dart';

const AuthUser user = AuthUser(id: 'u1', email: 'a@b.c');
const AuthState signedOut = AuthState(status: AuthStatus.signedOut);
const AuthState uploader = AuthState(
  status: AuthStatus.signedIn,
  user: user,
  profile: UserProfile(role: UserRole.uploader, disabled: false),
);
const AuthState disabled = AuthState(
  status: AuthStatus.signedIn,
  user: user,
  profile: UserProfile(role: UserRole.uploader, disabled: true),
);

String? go(String location, AuthState auth) =>
    authRedirect(location: Uri.parse(location), auth: auth);

void main() {
  test('visitors browse freely', () {
    expect(go('/', signedOut), isNull);
    expect(go('/r/11111111-1111-4111-8111-111111111111', signedOut), isNull);
  });

  test('uploading requires signing in and comes back afterwards', () {
    expect(go('/upload', signedOut), '/login?from=%2Fupload');
    expect(go('/login?from=/upload', uploader), '/upload');
  });

  test('disabled accounts cannot open the upload page', () {
    expect(go('/upload', disabled), '/');
    expect(go('/upload', uploader), isNull);
  });

  test('signed-in users skip the login page', () {
    expect(go('/login', uploader), '/upload');
    expect(go('/login', disabled), '/');
  });

  test('never redirects to another site', () {
    expect(go('/login?from=//evil.example', uploader), '/upload');
    expect(go('/login?from=https://evil.example', uploader), '/upload');
  });

  test('setting a password needs the session from the invite link', () {
    expect(go('/set-password', signedOut), '/login');
    expect(go('/set-password', uploader), isNull);
  });

  test('waits while the session is still being restored', () {
    expect(go('/upload', const AuthState()), isNull);
  });
}
