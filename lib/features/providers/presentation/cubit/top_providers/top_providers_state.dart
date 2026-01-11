part of 'top_providers_cubit.dart';

/// Base state for TopProvidersCubit
sealed class TopProvidersState extends Equatable {
  const TopProvidersState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
final class TopProvidersInitial extends TopProvidersState {
  const TopProvidersInitial();
}

/// Loading state while fetching data
final class TopProvidersLoading extends TopProvidersState {
  const TopProvidersLoading();
}

/// Success state with loaded providers
final class TopProvidersLoaded extends TopProvidersState {
  final List<TopProviderEntity> providers;

  const TopProvidersLoaded({required this.providers});

  @override
  List<Object?> get props => [providers];
}

/// Error state with message and optional previous data
final class TopProvidersError extends TopProvidersState {
  final String message;
  final List<TopProviderEntity>? previousProviders;

  const TopProvidersError({
    required this.message,
    this.previousProviders,
  });

  @override
  List<Object?> get props => [message, previousProviders];
}
