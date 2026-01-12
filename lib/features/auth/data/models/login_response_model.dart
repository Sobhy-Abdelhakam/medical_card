import 'user_model.dart';

/// Model for login response from API
class LoginResponseModel {
  final String token;
  final String tokenType;
  final UserModel user;
  final DateTime? expiresAt;

  const LoginResponseModel({
    required this.token,
    required this.tokenType,
    required this.user,
    this.expiresAt,
  });

  /// Creates a LoginResponseModel from JSON map
  factory LoginResponseModel.fromJson(Map<String, dynamic> json) {
    // Handle nested user data - could be under 'user' or 'data' key
    Map<String, dynamic>? userData;
    if (json['user'] is Map<String, dynamic>) {
      userData = json['user'] as Map<String, dynamic>;
    } else if (json['data'] is Map<String, dynamic>) {
      userData = json['data'] as Map<String, dynamic>;
    }

    return LoginResponseModel(
      token: json['token']?.toString() ?? json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'Bearer',
      user: userData != null
          ? UserModel.fromJson(userData)
          : UserModel.fromJson(json),
      expiresAt: _parseDateTime(json['expires_at'] ?? json['expires_in']),
    );
  }

  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'token': token,
      'token_type': tokenType,
      'user': user.toJson(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// Returns the full authorization header value
  String get authorizationHeader => '$tokenType $token';

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    // Handle expires_in as seconds from now
    if (value is int) {
      return DateTime.now().add(Duration(seconds: value));
    }
    return null;
  }

  @override
  String toString() => 'LoginResponseModel(token: ${token.substring(0, 10)}..., user: ${user.username})';
}
