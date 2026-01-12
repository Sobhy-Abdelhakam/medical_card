import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

/// Base state for authentication
sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state - checking authentication status
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state - authentication operation in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Unauthenticated state - user is in guest mode
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Authenticated state - user is logged in
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object?> get props => [user];
}

/// Error state - authentication operation failed
class AuthError extends AuthState {
  final String message;

  const AuthError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Login form state for tracking form submission
class AuthLoginSubmitting extends AuthState {
  const AuthLoginSubmitting();
}

/// Logout in progress
class AuthLoggingOut extends AuthState {
  const AuthLoggingOut();
}
