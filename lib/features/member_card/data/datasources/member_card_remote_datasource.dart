import '../../../../core/constants/api_constants.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/network/api_client.dart';
import '../models/member_card_model.dart';

/// Remote data source for member card API calls
abstract class MemberCardRemoteDataSource {
  /// Gets the member card for the authenticated user
  /// Returns [MemberCardModel] on success
  /// Throws [ServerException] or [AuthenticationException] on error
  Future<MemberCardModel> getMemberCard();
}

/// Implementation of [MemberCardRemoteDataSource]
class MemberCardRemoteDataSourceImpl implements MemberCardRemoteDataSource {
  final ApiClient apiClient;

  MemberCardRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<MemberCardModel> getMemberCard() async {
    try {
      final response = await apiClient.get(ApiConstants.memberCard);

      final data = response.data;
      if (data == null) {
        throw const ServerException(message: 'Empty response from server');
      }

      Map<String, dynamic> cardData;
      if (data is Map<String, dynamic>) {
        // Check if response has a 'data' wrapper
        if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
          cardData = data['data'] as Map<String, dynamic>;
        } else {
          cardData = data;
        }
      } else {
        throw const ParseException(message: 'Invalid response format');
      }

      return MemberCardModel.fromJson(cardData);
    } on AppException {
      rethrow;
    } catch (e) {
      throw ServerException(message: 'Failed to get member card: ${e.toString()}');
    }
  }
}
