import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/providers_repository.dart';

part 'map_providers_state.dart';

/// Cubit for managing map providers state
class MapProvidersCubit extends Cubit<MapProvidersState> {
  final ProvidersRepository _repository;

  MapProvidersCubit({required ProvidersRepository repository})
      : _repository = repository,
        super(const MapProvidersInitial());

  /// All loaded providers with valid coordinates (unfiltered)
  List<ProviderEntity> _allProviders = [];

  /// Loads all providers with valid coordinates for map
  Future<void> loadMapProviders() async {
    emit(const MapProvidersLoading());

    // Fetch all providers (no pagination)
    final result = await _repository.getProviders(
      const GetProvidersParams(paginate: false),
    );

    result.fold(
      (failure) => emit(MapProvidersError(message: failure.message)),
      (response) {
        // Filter only providers with valid coordinates
        final validProviders = response.providers
            .where((p) => p.hasValidCoordinates)
            .toList();
            
        _allProviders = validProviders;
        
        emit(MapProvidersLoaded(
          providers: validProviders,
          filteredProviders: validProviders,
          selectedTypes: const {},
        ));
      },
    );
  }

  /// Filters providers by type
  void filterByTypes(Set<String> types) {
    if (state is! MapProvidersLoaded) return;

    final currentState = state as MapProvidersLoaded;

    if (types.isEmpty) {
      // Show all if no types selected
      emit(currentState.copyWith(
        filteredProviders: _allProviders,
        selectedTypes: const {},
      ));
    } else {
      final filtered =
          _allProviders.where((p) => types.contains(p.type)).toList();
      emit(currentState.copyWith(
        filteredProviders: filtered,
        selectedTypes: types,
      ));
    }
  }

  /// Toggles a type filter
  void toggleType(String type) {
    if (state is! MapProvidersLoaded) return;

    final currentState = state as MapProvidersLoaded;
    final newTypes = Set<String>.from(currentState.selectedTypes);

    if (newTypes.contains(type)) {
      newTypes.remove(type);
    } else {
      newTypes.add(type);
    }

    filterByTypes(newTypes);
  }

  /// Clears all filters
  void clearFilters() {
    if (state is! MapProvidersLoaded) return;

    emit((state as MapProvidersLoaded).copyWith(
      filteredProviders: _allProviders,
      selectedTypes: const {},
    ));
  }

  /// Searches providers by query and updates state
  void searchMapProviders(String query) {
    if (state is! MapProvidersLoaded) return;
    final currentState = state as MapProvidersLoaded;

    final lowerQuery = query.toLowerCase();
    
    final filtered = _allProviders.where((p) {
      final matchesType = currentState.selectedTypes.isEmpty || 
                         currentState.selectedTypes.contains(p.type);
      final matchesQuery = query.isEmpty || 
                          p.name.toLowerCase().contains(lowerQuery) ||
                          p.type.toLowerCase().contains(lowerQuery) ||
                          p.city.toLowerCase().contains(lowerQuery);
      return matchesType && matchesQuery;
    }).toList();

    emit(currentState.copyWith(filteredProviders: filtered));
  }

  /// Selects a provider
  void selectProvider(ProviderEntity? provider) {
    if (state is! MapProvidersLoaded) return;
    
    emit((state as MapProvidersLoaded).copyWith(
      selectedProvider: provider,
    ));
  }

  /// Gets unique provider types
  Set<String> get availableTypes {
    return _allProviders.map((p) => p.type).toSet();
  }
}
