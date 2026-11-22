import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.profile,
    this.busy = false,
    this.failure,
    this.passwordSet = false,
  });

  final AuthStatus status;
  final AuthUser? user;
  final UserProfile? profile;
  final bool busy;
  final Failure? failure;
  final bool passwordSet;

  /// Mirrors the server rule: an invited, non-disabled profile is required.
  bool get canUpload => status == AuthStatus.signedIn && profile != null && !profile!.disabled;

  AuthState copyWith({bool? busy, Failure? Function()? failure, bool? passwordSet}) => AuthState(
    status: status,
    user: user,
    profile: profile,
    busy: busy ?? this.busy,
    failure: failure != null ? failure() : this.failure,
    passwordSet: passwordSet ?? this.passwordSet,
  );

  @override
  List<Object?> get props => <Object?>[status, user, profile, busy, failure, passwordSet];
}

/// Session state for invited uploaders. Visitors never need to sign in.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit(this._repository) : super(const AuthState());

  static const int minPasswordLength = 8;

  final AuthRepository _repository;
  StreamSubscription<AuthUser?>? _subscription;

  Future<void> start() async {
    _subscription ??= _repository.userChanges().listen(_onUserChanged);
    await _onUserChanged(_repository.currentUser);
  }

  Future<void> signIn(String email, String password) async {
    emit(state.copyWith(busy: true, failure: () => null));
    try {
      await _repository.signIn(email: email, password: password);
      emit(state.copyWith(busy: false));
    } on Failure catch (failure) {
      emit(state.copyWith(busy: false, failure: () => failure));
    }
  }

  Future<void> setPassword(String password) async {
    if (password.length < minPasswordLength) {
      emit(state.copyWith(failure: () => const ServerFailure('weak_password')));
      return;
    }
    emit(state.copyWith(busy: true, failure: () => null));
    try {
      await _repository.setPassword(password);
      emit(state.copyWith(busy: false, passwordSet: true));
    } on Failure catch (failure) {
      emit(state.copyWith(busy: false, failure: () => failure));
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    emit(const AuthState(status: AuthStatus.signedOut));
  }

  Future<void> _onUserChanged(AuthUser? user) async {
    if (user == null) {
      // Cubits drop duplicate states, so repeated "signed out" events are harmless.
      emit(const AuthState(status: AuthStatus.signedOut));
      return;
    }
    if (state.status == AuthStatus.signedIn && state.user == user) {
      return;
    }
    UserProfile? profile;
    try {
      profile = await _repository.loadProfile(user.id);
    } on Failure {
      profile = null;
    }
    if (!isClosed) {
      emit(AuthState(status: AuthStatus.signedIn, user: user, profile: profile));
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
