import 'package:equatable/equatable.dart';

enum UserRole { admin, uploader }

class AuthUser extends Equatable {
  const AuthUser({required this.id, required this.email});

  final String id;
  final String email;

  @override
  List<Object?> get props => <Object?>[id, email];
}

/// The `profiles` row of a signed-in user. Only invited people have one.
class UserProfile extends Equatable {
  const UserProfile({required this.role, required this.disabled, this.displayName});

  final UserRole role;
  final bool disabled;
  final String? displayName;

  @override
  List<Object?> get props => <Object?>[role, disabled, displayName];
}
