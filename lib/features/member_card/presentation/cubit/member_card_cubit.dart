import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/member_card_entity.dart';
import '../../domain/repositories/member_card_repository.dart';
import 'member_card_state.dart';

/// Cubit for managing member card state
class MemberCardCubit extends Cubit<MemberCardState> {
  final MemberCardRepository repository;

  MemberCardCubit({required this.repository}) : super(const MemberCardInitial());

  /// Current member card (if loaded)
  MemberCardEntity? _currentCard;
  MemberCardEntity? get currentCard => _currentCard;

  /// Loads the member card
  Future<void> loadMemberCard() async {
    emit(const MemberCardLoading());

    final result = await repository.getMemberCard();
    result.fold(
      (failure) {
        _currentCard = null;
        emit(MemberCardError(message: failure.message));
      },
      (card) {
        _currentCard = card;
        emit(MemberCardLoaded(card: card));
      },
    );
  }

  /// Refreshes the member card data
  Future<void> refreshMemberCard() async {
    // If we have existing data, show refreshing state
    if (_currentCard != null) {
      emit(MemberCardRefreshing(card: _currentCard!));
    } else {
      emit(const MemberCardLoading());
    }

    final result = await repository.refreshMemberCard();
    result.fold(
      (failure) {
        // If refresh fails but we have existing data, keep showing it
        if (_currentCard != null) {
          emit(MemberCardLoaded(card: _currentCard!));
        } else {
          emit(MemberCardError(message: failure.message));
        }
      },
      (card) {
        _currentCard = card;
        emit(MemberCardLoaded(card: card));
      },
    );
  }

  /// Clears the member card data (on logout)
  void clearCard() {
    _currentCard = null;
    emit(const MemberCardInitial());
  }
}
