part of 'providers_list_cubit.dart';

/// Base state for ProvidersListCubit
sealed class ProvidersListState extends Equatable {
  const ProvidersListState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
final class ProvidersListInitial extends ProvidersListState {
  const ProvidersListInitial();
}

/// Loading state while fetching data
final class ProvidersListLoading extends ProvidersListState {
  final GetProvidersParams params;

  const ProvidersListLoading({required this.params});

  @override
  List<Object?> get props => [params];
}

/// Success state with loaded providers
final class ProvidersListLoaded extends ProvidersListState {
  final List<ProviderEntity> providers;
  final PaginationEntity? pagination;
  final List<String> availableCities;
  final GetProvidersParams params;
  final bool isLoadingMore;
  final String? selectedCity;

  const ProvidersListLoaded({
    required this.providers,
    this.pagination,
    required this.availableCities,
    required this.params,
    this.isLoadingMore = false,
    this.selectedCity,
  });

  /// Returns true if there are more pages to load
  bool get hasMorePages => pagination?.hasMorePages ?? false;

  /// Returns true if the list is empty
  bool get isEmpty => providers.isEmpty;

  /// Creates a copy with updated fields
  ProvidersListLoaded copyWith({
    List<ProviderEntity>? providers,
    PaginationEntity? pagination,
    List<String>? availableCities,
    GetProvidersParams? params,
    bool? isLoadingMore,
    String? selectedCity,
  }) {
    return ProvidersListLoaded(
      providers: providers ?? this.providers,
      pagination: pagination ?? this.pagination,
      availableCities: availableCities ?? this.availableCities,
      params: params ?? this.params,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      selectedCity: selectedCity ?? this.selectedCity,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        pagination,
        availableCities,
        params,
        isLoadingMore,
        selectedCity,
      ];
}

/// Error state with message
final class ProvidersListError extends ProvidersListState {
  final String message;
  final GetProvidersParams params;

  const ProvidersListError({
    required this.message,
    required this.params,
  });

  @override
  List<Object?> get props => [message, params];
}
