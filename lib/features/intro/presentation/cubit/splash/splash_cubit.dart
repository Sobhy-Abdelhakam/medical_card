import 'package:euro_medical_card/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/intro_repository.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final IntroRepository repository;
  final AuthRepository authRepository;

  SplashCubit({
    required this.repository,
    required this.authRepository,
  }) : super(SplashInitial());

  Future<void> startSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    _navigate();
  }

  Future<void> _navigate() async {
    // Check authentication first
    final isLoggedIn = await authRepository.isLoggedIn();
    if (!isLoggedIn) {
      emit(SplashNavigateToLogin());
      return;
    }

    // Check if app was opened before (for welcome screen)
    final isOpened = await repository.isAppOpened();
    if (isOpened) {
      emit(SplashNavigateToHome());
    } else {
      emit(SplashNavigateToWelcome());
    }
  }

  Future<void> skipUpdate() async {
    _navigate();
  }
}
