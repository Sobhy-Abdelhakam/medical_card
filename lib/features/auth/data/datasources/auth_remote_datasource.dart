import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/login_request_model.dart';
import '../models/login_response_model.dart';
import '../models/user_model.dart';

/// Remote data source for authentication API calls
abstract class AuthRemoteDataSource {
  /// Authenticates user with credentials
  /// Returns [LoginResponseModel] on success
  /// Throws [ServerException] or [AuthenticationException] on error
  Future<LoginResponseModel> login(LoginRequestModel request);

  /// Logs out the current user
  /// Returns true on success
  /// Throws [ServerException] on error
  Future<bool> logout();

  /// Gets the current authenticated user's profile
  /// Returns [UserModel] on success
  /// Throws [ServerException] or [AuthenticationException] on error
  Future<UserModel> getCurrentUser();
}

/// Implementation of [AuthRemoteDataSource]
class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<LoginResponseModel> login(LoginRequestModel request) async {
    try {
      final response = await apiClient.post(
        ApiConstants.authLogin,
        data: request.toJson(),
      );

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'Empty response from server');
      }

      // Handle response structure
      Map<String, dynamic> responseData;
      if (data is Map<String, dynamic>) {
        // Check if response has a 'data' wrapper
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          responseData = data['data'] as Map<String, dynamic>;
          // Include token from root if present
          if (data.containsKey('token')) {
            responseData['token'] = data['token'];
          }
          if (data.containsKey('access_token')) {
            responseData['token'] = data['access_token'];
          }
        } else {
          responseData = data;
        }
      } else {
        throw const ParseException(message: 'Invalid response format');
      }

      return LoginResponseModel.fromJson(responseData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Login failed: ${e.toString()}');
    }
  }

  @override
  Future<bool> logout() async {
    try {
      await apiClient.post(ApiConstants.authLogout);
      return true;
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Logout failed: ${e.toString()}');
    }
  }

  @override
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await apiClient.get(ApiConstants.authMe);

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'Empty response from server');
      }

      Map<String, dynamic> userData;
      if (data is Map<String, dynamic>) {
        // Check if response has a 'data' wrapper
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          userData = data['data'] as Map<String, dynamic>;
        } else {
          userData = data;
        }
      } else {
        throw const ParseException(message: 'Invalid response format');
      }

      return UserModel.fromJson(userData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get user: ${e.toString()}');
    }
  }
}
