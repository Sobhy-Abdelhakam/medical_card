/// Base exception class for data layer errors
class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException: $message (code: $statusCode)';
}

/// Exception thrown when server returns an error response
class ServerException extends AppException {
  const ServerException({
    super.message = 'Server error occurred',
    super.statusCode,
  });
}

/// Exception thrown when there's no network connection
class NetworkException extends AppException {
  const NetworkException({
    super.message = 'No internet connection',
    super.statusCode,
  });
}

/// Exception thrown when cache operations fail
class CacheException extends AppException {
  const CacheException({
    super.message = 'Cache operation failed',
    super.statusCode,
  });
}

/// Exception thrown when data parsing fails
class ParseException extends AppException {
  const ParseException({
    super.message = 'Failed to parse response data',
    super.statusCode,
  });
}

/// Exception thrown for authentication errors (401)
class AuthenticationException extends AppException {
  const AuthenticationException({
    super.message = 'Authentication required',
    super.statusCode = 401,
  });
}

/// Exception thrown for validation errors (422)
class ValidationException extends AppException {
  final Map<String, List<String>>? errors;

  const ValidationException({
    super.message = 'Validation failed',
    super.statusCode = 422,
    this.errors,
  });
}
