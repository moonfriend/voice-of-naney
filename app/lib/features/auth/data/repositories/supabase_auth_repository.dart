import 'package:injectable/injectable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

@LazySingleton(as: AuthRepository)
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Stream<AuthUser?> userChanges() =>
      _client.auth.onAuthStateChange.map((AuthState state) => _toUser(state.session?.user));

  @override
  AuthUser? get currentUser => _toUser(_client.auth.currentUser);

  @override
  Future<void> signIn({required String email, required String password}) =>
      guardAuthCall(() => _client.auth.signInWithPassword(email: email.trim(), password: password));

  @override
  Future<void> signOut() => guardAuthCall(_client.auth.signOut);

  @override
  Future<void> setPassword(String password) =>
      guardAuthCall(() => _client.auth.updateUser(UserAttributes(password: password)));

  @override
  Future<UserProfile?> loadProfile(String userId) => guardRemoteCall(() async {
    final Map<String, Object?>? row =
        await _client
            .from('profiles')
            .select('role,disabled,display_name')
            .eq('id', userId)
            .maybeSingle();
    return row == null ? null : userProfileFromJson(row);
  });

  static AuthUser? _toUser(User? user) =>
      user == null ? null : AuthUser(id: user.id, email: user.email ?? '');
}

UserProfile userProfileFromJson(Map<String, Object?> row) => UserProfile(
  role: row['role'] == 'admin' ? UserRole.admin : UserRole.uploader,
  disabled: row['disabled'] as bool? ?? false,
  displayName: row['display_name'] as String?,
);

/// Auth errors carry a stable code (e.g. `invalid_credentials`, `weak_password`).
Future<void> guardAuthCall(Future<Object?> Function() call) => guardRemoteCall(() async {
  try {
    await call();
  } on AuthException catch (error) {
    throw ServerFailure(error.code ?? 'auth_failed');
  }
});
