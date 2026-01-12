import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/user_entity.dart';

/// Repository interface for authentication operations
abstract class AuthRepository {
  /// Authenticates user with username and password
  /// Returns [LoginResult] on success or [Failure] on error
  Future<Either<Failure, LoginResult>> login({
    required String username,
    required String password,
  });

  /// Logs out the current user
  /// Returns true on success or [Failure] on error
  Future<Either<Failure, bool>> logout();

  /// Gets the currently authenticated user
  /// Returns [UserEntity] on success or [Failure] on error
  Future<Either<Failure, UserEntity>> getCurrentUser();

  /// Checks if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Gets the stored auth token
  Future<String?> getStoredToken();

  /// Clears all stored authentication data
  Future<void> clearAuthData();
}

/// Result model for login operation
class LoginResult {
  final String token;
  final UserEntity user;

  const LoginResult({
    required this.token,
    required this.user,
  });
}
