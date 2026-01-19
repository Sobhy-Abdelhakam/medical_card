import '../../../../core/network/api_client.dart';
import '../models/member_model.dart';

/// Remote data source for authentication
abstract class AuthRemoteDataSource {
  Future<MemberModel> getMember(String membershipNumber);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final ApiClient apiClient;

  AuthRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<MemberModel> getMember(String membershipNumber) async {
    final url =
        'http://euroassist.3utilities.com:5001/api/member/$membershipNumber';
    final response = await apiClient.get(url);

    // Debugging requirements
    // ignore: avoid_print
    print('[AUTH] GET $url status=${response.statusCode}');
    // ignore: avoid_print
    print('[AUTH] raw response.data type=${response.data.runtimeType}');
    // ignore: avoid_print
    print('[AUTH] raw response.data=${response.data}');

    if (response.data == null) {
      throw Exception('Member not found');
    }

    final model = MemberModel.fromApi(response.data);

    // ignore: avoid_print
    print(
        '[AUTH] parsed member: id=${model.memberId} name="${model.memberName}" templateId=${model.templateId} templateName="${model.templateName}"');

    return model;
  }
}

