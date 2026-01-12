/// Model for login request payload
class LoginRequestModel {
  final String username;
  final String password;

  const LoginRequestModel({
    required this.username,
    required this.password,
  });

  /// Converts the model to a JSON map for API request
  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
    };
  }

  @override
  String toString() => 'LoginRequestModel(username: $username)';
}
