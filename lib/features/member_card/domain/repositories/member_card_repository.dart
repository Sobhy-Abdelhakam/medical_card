import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/member_card_entity.dart';

/// Repository interface for member card operations
abstract class MemberCardRepository {
  /// Gets the member card for the authenticated user
  /// Returns [MemberCardEntity] on success or [Failure] on error
  Future<Either<Failure, MemberCardEntity>> getMemberCard();

  /// Refreshes the member card data
  /// Returns [MemberCardEntity] on success or [Failure] on error
  Future<Either<Failure, MemberCardEntity>> refreshMemberCard();
}
