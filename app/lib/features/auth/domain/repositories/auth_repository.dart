import '../entities/auth_user.dart';

abstract interface class AuthRepository {
  /// Emits on sign-in, sign-out and token refresh (including sessions restored from
  /// an invite link in the URL).
  Stream<AuthUser?> userChanges();

  AuthUser? get currentUser;

  Future<void> signIn({required String email, required String password});

  Future<void> signOut();

  /// Used by invited users to choose their password after following the invite link.
  Future<void> setPassword(String password);

  Future<UserProfile?> loadProfile(String userId);
}
