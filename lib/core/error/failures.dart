import 'package:equatable/equatable.dart';

/// Base failure class for handling errors across the application
abstract class Failure extends Equatable {
  final String message;
  final int? code;

  const Failure({required this.message, this.code});

  @override
  List<Object?> get props => [message, code];
}

/// Represents a server-side failure (4xx, 5xx responses)
class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'حدث خطأ في الخادم. يرجى المحاولة لاحقاً.',
    super.code,
  });
}

/// Represents a network connectivity failure
class NetworkFailure extends Failure {
  const NetworkFailure({
    super.message = 'لا يوجد اتصال بالإنترنت. يرجى التحقق من اتصالك.',
    super.code,
  });
}

/// Represents a cache operation failure
class CacheFailure extends Failure {
  const CacheFailure({
    super.message = 'فشل في تحميل البيانات المحفوظة.',
    super.code,
  });
}

/// Represents an unexpected failure
class UnexpectedFailure extends Failure {
  const UnexpectedFailure({
    super.message = 'حدث خطأ غير متوقع.',
    super.code,
  });
}

/// Represents a validation failure
class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'البيانات المدخلة غير صحيحة.',
    super.code,
  });
}

/// Represents an authentication failure
class AuthenticationFailure extends Failure {
  const AuthenticationFailure({
    super.message = 'انتهت صلاحية الجلسة. يرجى تسجيل الدخول مجدداً.',
    super.code = 401,
  });
}
