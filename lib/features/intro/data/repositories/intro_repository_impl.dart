
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../domain/repositories/intro_repository.dart';

class IntroRepositoryImpl implements IntroRepository {
  final ApiClient apiClient;
  final SharedPreferences sharedPreferences;

  IntroRepositoryImpl({
    required this.apiClient,
    required this.sharedPreferences,
  });

  @override
  Future<bool> isAppOpened() async {
    return sharedPreferences.getBool('isLoggedIn') ?? false;
  }

  @override
  Future<void> setAppOpened() async {
    await sharedPreferences.setBool('isLoggedIn', true);
  }
}
