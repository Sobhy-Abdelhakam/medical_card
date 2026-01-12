import 'package:dartz/dartz.dart';

import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/member_card_entity.dart';
import '../../domain/repositories/member_card_repository.dart';
import '../datasources/member_card_remote_datasource.dart';

/// Implementation of [MemberCardRepository]
class MemberCardRepositoryImpl implements MemberCardRepository {
  final MemberCardRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  MemberCardRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, MemberCardEntity>> getMemberCard() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }

    try {
      final memberCard = await remoteDataSource.getMemberCard();
      return Right(memberCard);
    } on AuthenticationException catch (e) {
      return Left(AuthenticationFailure(message: e.message));
    } on NetworkException {
      return const Left(NetworkFailure());
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(UnexpectedFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, MemberCardEntity>> refreshMemberCard() async {
    return getMemberCard();
  }
}
