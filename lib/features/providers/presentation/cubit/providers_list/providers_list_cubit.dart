import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/providers_repository.dart';

part 'providers_list_state.dart';

/// Cubit for managing providers list state with pagination
class ProvidersListCubit extends Cubit<ProvidersListState> {
  final ProvidersRepository _repository;

  ProvidersListCubit({required ProvidersRepository repository})
      : _repository = repository,
        super(const ProvidersListInitial());

  /// Current parameters for fetching
  GetProvidersParams? _currentParams;

  /// Loads providers with the given parameters
  Future<void> loadProviders({
    String? searchName,
    String? type,
    String? search,
    String? city,
    bool paginate = true,
    int perPage = 25,
  }) async {
    _currentParams = GetProvidersParams(
      searchName: searchName,
      type: type,
      search: search,
      city: city,
      paginate: paginate,
      page: 1,
      perPage: perPage,
    );

    emit(ProvidersListLoading(params: _currentParams!));

    final result = await _repository.getProviders(_currentParams!);

    result.fold(
      (failure) => emit(ProvidersListError(
        message: failure.message,
        params: _currentParams!,
      )),
      (response) {
        // Extract unique cities for filtering
        final cities = <String>{};
        for (final provider in response.providers) {
          if (provider.city.isNotEmpty) {
            cities.add(provider.city);
          }
        }

        emit(ProvidersListLoaded(
          providers: response.providers,
          pagination: response.pagination,
          availableCities: cities.toList()..sort(),
          params: _currentParams!,
        ));
      },
    );
  }

  /// Loads the next page of providers
  Future<void> loadNextPage() async {
    final currentState = state;
    if (currentState is! ProvidersListLoaded) return;
    if (!currentState.hasMorePages) return;
    if (currentState.isLoadingMore) return;

    // Emit loading more state
    emit(currentState.copyWith(isLoadingMore: true));

    final nextPage = (currentState.pagination?.currentPage ?? 1) + 1;
    final params = GetProvidersParams(
      searchName: _currentParams?.searchName,
      type: _currentParams?.type,
      search: _currentParams?.search,
      city: _currentParams?.city,
      paginate: true,
      page: nextPage,
      perPage: _currentParams?.perPage ?? 25,
    );

    final result = await _repository.getProviders(params);

    result.fold(
      (failure) {
        // Revert to previous state without loading indicator
        emit(currentState.copyWith(isLoadingMore: false));
      },
      (response) {
        // Merge new providers with existing ones
        final existingIds = currentState.providers.map((p) => p.id).toSet();
        final newProviders = response.providers
            .where((p) => !existingIds.contains(p.id))
            .toList();

        // Update cities list
        final cities = Set<String>.from(currentState.availableCities);
        for (final provider in newProviders) {
          if (provider.city.isNotEmpty) {
            cities.add(provider.city);
          }
        }

        emit(ProvidersListLoaded(
          providers: [...currentState.providers, ...newProviders],
          pagination: response.pagination,
          availableCities: cities.toList()..sort(),
          params: params,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Applies search filter to current list
  Future<void> applySearch(String query) async {
    if (_currentParams == null) return;

    final params = GetProvidersParams(
      searchName: _currentParams!.searchName,
      type: _currentParams!.type,
      search: query.isNotEmpty ? query : null,
      city: _currentParams!.city,
      paginate: _currentParams!.paginate,
      page: 1,
      perPage: _currentParams!.perPage,
    );

    _currentParams = params;
    emit(ProvidersListLoading(params: params));

    final result = await _repository.getProviders(params);

    result.fold(
      (failure) => emit(ProvidersListError(
        message: failure.message,
        params: params,
      )),
      (response) {
        final cities = <String>{};
        for (final provider in response.providers) {
          if (provider.city.isNotEmpty) {
            cities.add(provider.city);
          }
        }

        emit(ProvidersListLoaded(
          providers: response.providers,
          pagination: response.pagination,
          availableCities: cities.toList()..sort(),
          params: params,
        ));
      },
    );
  }

  /// Filters by city
  Future<void> filterByCity(String? city) async {
    if (_currentParams == null) return;

    final params = GetProvidersParams(
      searchName: _currentParams!.searchName,
      type: _currentParams!.type,
      search: _currentParams!.search,
      city: city,
      paginate: _currentParams!.paginate,
      page: 1,
      perPage: _currentParams!.perPage,
    );

    _currentParams = params;
    
    // If we have loaded data, filter locally first for UX
    final currentState = state;
    if (currentState is ProvidersListLoaded && city != null) {
      final filteredLocally = currentState.providers
          .where((p) => p.city == city)
          .toList();
      
      emit(currentState.copyWith(
        providers: filteredLocally,
        selectedCity: city,
      ));
    }

    // Then fetch fresh data from server
    final result = await _repository.getProviders(params);

    result.fold(
      (failure) => emit(ProvidersListError(
        message: failure.message,
        params: params,
      )),
      (response) {
        final cities = <String>{};
        for (final provider in response.providers) {
          if (provider.city.isNotEmpty) {
            cities.add(provider.city);
          }
        }

        emit(ProvidersListLoaded(
          providers: response.providers,
          pagination: response.pagination,
          availableCities: cities.toList()..sort(),
          params: params,
          selectedCity: city,
        ));
      },
    );
  }

  /// Refreshes the current list
  Future<void> refresh() async {
    if (_currentParams == null) return;
    
    await loadProviders(
      searchName: _currentParams!.searchName,
      type: _currentParams!.type,
      search: _currentParams!.search,
      city: _currentParams!.city,
      paginate: _currentParams!.paginate,
      perPage: _currentParams!.perPage,
    );
  }
}
