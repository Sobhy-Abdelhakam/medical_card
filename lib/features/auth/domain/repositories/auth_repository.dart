import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/member_entity.dart';

/// Authentication repository interface
abstract class AuthRepository {
  /// Login with membership number
  Future<Either<Failure, MemberEntity>> login(String membershipNumber);

  /// Get current logged in member
  Future<MemberEntity?> getCurrentMember();

  /// Check if user is logged in
  Future<bool> isLoggedIn();

  /// Logout current user
  Future<void> logout();

  /// Save member data locally
  Future<void> saveMember(MemberEntity member);
}

