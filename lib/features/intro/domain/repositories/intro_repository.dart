
abstract class IntroRepository {
  // Future<Either<Failure, Map<String, dynamic>>> checkVersion();
  Future<void> setAppOpened();
  Future<bool> isAppOpened();
}
