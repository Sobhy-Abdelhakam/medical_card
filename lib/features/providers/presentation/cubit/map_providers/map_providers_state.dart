part of 'map_providers_cubit.dart';

/// Base state for MapProvidersCubit
sealed class MapProvidersState extends Equatable {
  const MapProvidersState();

  @override
  List<Object?> get props => [];
}

/// Initial state before any data is loaded
final class MapProvidersInitial extends MapProvidersState {
  const MapProvidersInitial();
}

/// Loading state while fetching data
final class MapProvidersLoading extends MapProvidersState {
  const MapProvidersLoading();
}

/// Success state with loaded providers
final class MapProvidersLoaded extends MapProvidersState {
  final List<ProviderEntity> providers;
  final List<ProviderEntity> filteredProviders;
  final Set<String> selectedTypes;
  final ProviderEntity? selectedProvider;

  const MapProvidersLoaded({
    required this.providers,
    required this.filteredProviders,
    required this.selectedTypes,
    this.selectedProvider,
  });

  /// Returns true if filters are active
  bool get hasFilters => selectedTypes.isNotEmpty;

  /// Returns unique types from all providers
  Set<String> get availableTypes => providers.map((p) => p.type).toSet();

  /// Creates a copy with updated fields
  MapProvidersLoaded copyWith({
    List<ProviderEntity>? providers,
    List<ProviderEntity>? filteredProviders,
    Set<String>? selectedTypes,
    ProviderEntity? selectedProvider,
  }) {
    return MapProvidersLoaded(
      providers: providers ?? this.providers,
      filteredProviders: filteredProviders ?? this.filteredProviders,
      selectedTypes: selectedTypes ?? this.selectedTypes,
      selectedProvider: selectedProvider ?? this.selectedProvider,
    );
  }

  @override
  List<Object?> get props => [
        providers,
        filteredProviders,
        selectedTypes,
        selectedProvider,
      ];
}

/// Error state with message
final class MapProvidersError extends MapProvidersState {
  final String message;

  const MapProvidersError({required this.message});

  @override
  List<Object?> get props => [message];
}
