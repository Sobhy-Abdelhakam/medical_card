import 'dart:convert';

import 'package:dartz/dartz.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../models/login_request_model.dart';
import '../models/user_model.dart';

/// Implementation of [AuthRepository]
class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;
  final SharedPreferences sharedPreferences;
  final ApiClient apiClient;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
    required this.sharedPreferences,
    required this.apiClient,
  });

  @override
  Future<Either<Failure, LoginResult>> login({
    required String username,
    required String password,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final request = LoginRequestModel(
        username: username,
        password: password,
      );

      final response = await remoteDataSource.login(request);

      // Store token securely
      await sharedPreferences.setString(StorageKeys.authToken, response.token);
      await sharedPreferences.setString(
        StorageKeys.userData,
        jsonEncode(response.user.toJson()),
      );
      await sharedPreferences.setBool(StorageKeys.isLoggedIn, true);

      // Set token in API client
      apiClient.setAuthToken(response.token);

      return Right(LoginResult(
        token: response.token,
        user: response.user,
      ));
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on ValidationException catch (e) {
      return Left(ValidationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> logout() async {
    try {
      // Try to call logout API if connected
      if (await networkInfo.isConnected) {
        try {
          await remoteDataSource.logout();
        } catch (_) {
          // Continue with local logout even if API fails
        }
      }

      // Clear local data
      await clearAuthData();

      return const Right(true);
    } catch (e) {
      // Still clear local data on error
      await clearAuthData();
      return const Right(true);
    }
  }

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    // First try to get from cache
    final cachedUser = _getCachedUser();

    if (!await networkInfo.isConnected) {
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return const Left(NetworkFailure());
    }

    try {
      final user = await remoteDataSource.getCurrentUser();

      // Update cached user data
      await sharedPreferences.setString(
        StorageKeys.userData,
        jsonEncode(user.toJson()),
      );

      return Right(user);
    } on AuthenticationException catch (e) {
      // Clear auth data on authentication failure
      await clearAuthData();
      return Left(AuthenticationFailure(message: e.message));
    } on ServerException catch (e) {
      // Return cached user if available on server error
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      if (cachedUser != null) {
        return Right(cachedUser);
      }
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<bool> isAuthenticated() async {
    final isLoggedIn = sharedPreferences.getBool(StorageKeys.isLoggedIn) ?? false;
    final token = sharedPreferences.getString(StorageKeys.authToken);

    if (!isLoggedIn || token == null || token.isEmpty) {
      return false;
    }

    // Set token in API client if authenticated
    apiClient.setAuthToken(token);
    return true;
  }

  @override
  Future<String?> getStoredToken() async {
    return sharedPreferences.getString(StorageKeys.authToken);
  }

  @override
  Future<void> clearAuthData() async {
    await sharedPreferences.remove(StorageKeys.authToken);
    await sharedPreferences.remove(StorageKeys.userData);
    await sharedPreferences.setBool(StorageKeys.isLoggedIn, false);
    apiClient.clearAuthToken();
  }

  /// Gets the cached user from SharedPreferences
  UserModel? _getCachedUser() {
    final userData = sharedPreferences.getString(StorageKeys.userData);
    if (userData == null || userData.isEmpty) {
      return null;
    }

    try {
      final json = jsonDecode(userData) as Map<String, dynamic>;
      return UserModel.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
