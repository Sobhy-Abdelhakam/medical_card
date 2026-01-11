
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/intro_repository.dart';
import 'splash_state.dart';

class SplashCubit extends Cubit<SplashState> {
  final IntroRepository repository;

  SplashCubit({required this.repository}) : super(SplashInitial());

  Future<void> startSplash() async {
    await Future.delayed(const Duration(seconds: 2));
    _navigate();
  }

  Future<void> _navigate() async {
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
