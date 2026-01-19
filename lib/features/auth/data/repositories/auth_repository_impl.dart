import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/member_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_datasource.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, MemberEntity>> login(String membershipNumber) async {
    try {
      if (!await networkInfo.isConnected) {
        return const Left(NetworkFailure(message: 'لا يوجد اتصال بالإنترنت'));
      }

      final memberModel = await remoteDataSource.getMember(membershipNumber);
      final member = memberModel.toEntity();

      if (member.memberId <= 0 || member.memberName.trim().isEmpty) {
        // ignore: avoid_print
        print(
            '[AUTH] invalid parsed member payload -> id=${member.memberId} name="${member.memberName}" templateId=${member.templateId} templateName="${member.templateName}"');
        return const Left(
          ServerFailure(message: 'تعذر قراءة بيانات العضو من الاستجابة.'),
        );
      }
      
      await localDataSource.saveMember(member);
      
      return Right(member);
    } catch (e) {
      if (e.toString().contains('404') || e.toString().contains('not found')) {
        return const Left(ServerFailure(message: 'رقم العضوية غير موجود'));
      }
      // ignore: avoid_print
      print('[AUTH] login exception: $e');
      return Left(ServerFailure(message: 'حدث خطأ أثناء تسجيل الدخول'));
    }
  }

  @override
  Future<MemberEntity?> getCurrentMember() async {
    return await localDataSource.getMember();
  }

  @override
  Future<bool> isLoggedIn() async {
    return await localDataSource.isLoggedIn();
  }

  @override
  Future<void> logout() async {
    await localDataSource.logout();
  }

  @override
  Future<void> saveMember(MemberEntity member) async {
    await localDataSource.saveMember(member);
  }
}

