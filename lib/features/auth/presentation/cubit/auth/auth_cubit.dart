import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/repositories/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repository;

  AuthCubit({required this.repository}) : super(AuthInitial()) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isLoggedIn = await repository.isLoggedIn();
    if (isLoggedIn) {
      final member = await repository.getCurrentMember();
      if (member != null) {
        emit(AuthAuthenticated(member));
      } else {
        emit(AuthUnauthenticated());
      }
    } else {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> login(String membershipNumber) async {
    emit(AuthLoading());
    
    final result = await repository.login(membershipNumber);
    
    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (member) => emit(AuthAuthenticated(member)),
    );
  }

  Future<void> logout() async {
    await repository.logout();
    emit(AuthUnauthenticated());
  }
}

