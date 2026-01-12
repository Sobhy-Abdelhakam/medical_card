import 'package:equatable/equatable.dart';

import '../../domain/entities/member_card_entity.dart';

/// Base state for member card
sealed class MemberCardState extends Equatable {
  const MemberCardState();

  @override
  List<Object?> get props => [];
}

/// Initial state
class MemberCardInitial extends MemberCardState {
  const MemberCardInitial();
}

/// Loading state
class MemberCardLoading extends MemberCardState {
  const MemberCardLoading();
}

/// Loaded state with member card data
class MemberCardLoaded extends MemberCardState {
  final MemberCardEntity card;

  const MemberCardLoaded({required this.card});

  @override
  List<Object?> get props => [card];
}

/// Error state
class MemberCardError extends MemberCardState {
  final String message;

  const MemberCardError({required this.message});

  @override
  List<Object?> get props => [message];
}

/// Refreshing state - shows current data while refreshing
class MemberCardRefreshing extends MemberCardState {
  final MemberCardEntity card;

  const MemberCardRefreshing({required this.card});

  @override
  List<Object?> get props => [card];
}
