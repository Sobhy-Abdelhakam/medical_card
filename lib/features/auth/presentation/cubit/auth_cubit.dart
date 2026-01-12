import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

/// Cubit for managing authentication state
class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(const AuthInitial());

  /// Current authenticated user (if any)
  UserEntity? _currentUser;
  UserEntity? get currentUser => _currentUser;

  /// Whether the user is currently authenticated
  bool get isAuthenticated => state is AuthAuthenticated;

  /// Checks the current authentication status
  Future<void> checkAuthStatus() async {
    emit(const AuthLoading());

    final isAuth = await repository.isAuthenticated();
    if (!isAuth) {
      _currentUser = null;
      emit(const AuthUnauthenticated());
      return;
    }

    // Try to get current user
    final result = await repository.getCurrentUser();
    result.fold(
      (failure) {
        _currentUser = null;
        emit(const AuthUnauthenticated());
      },
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Attempts to log in with username and password
  Future<void> login({
    required String username,
    required String password,
  }) async {
    emit(const AuthLoginSubmitting());

    final result = await repository.login(
      username: username,
      password: password,
    );

    result.fold(
      (failure) {
        emit(AuthError(message: failure.message));
        // Return to unauthenticated state after showing error
        emit(const AuthUnauthenticated());
      },
      (loginResult) {
        _currentUser = loginResult.user;
        emit(AuthAuthenticated(user: loginResult.user));
      },
    );
  }

  /// Logs out the current user
  Future<void> logout() async {
    emit(const AuthLoggingOut());

    await repository.logout();
    _currentUser = null;
    emit(const AuthUnauthenticated());
  }

  /// Refreshes the current user data
  Future<void> refreshUser() async {
    if (!isAuthenticated) return;

    final result = await repository.getCurrentUser();
    result.fold(
      (failure) {
        // If refresh fails due to auth error, log out
        if (failure.code == 401) {
          _currentUser = null;
          emit(const AuthUnauthenticated());
        }
      },
      (user) {
        _currentUser = user;
        emit(AuthAuthenticated(user: user));
      },
    );
  }

  /// Clears any error state and returns to appropriate state
  void clearError() {
    if (_currentUser != null) {
      emit(AuthAuthenticated(user: _currentUser!));
    } else {
      emit(const AuthUnauthenticated());
    }
  }
}
