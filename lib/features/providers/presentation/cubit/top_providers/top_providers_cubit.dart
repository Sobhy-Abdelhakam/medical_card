import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/entities.dart';
import '../../../domain/repositories/providers_repository.dart';

part 'top_providers_state.dart';

/// Cubit for managing top providers state
class TopProvidersCubit extends Cubit<TopProvidersState> {
  final ProvidersRepository _repository;

  TopProvidersCubit({required ProvidersRepository repository})
      : _repository = repository,
        super(const TopProvidersInitial());

  /// Loads top providers from the repository
  Future<void> loadTopProviders() async {
    emit(const TopProvidersLoading());

    final result = await _repository.getTopProviders();

    result.fold(
      (failure) => emit(TopProvidersError(message: failure.message)),
      (providers) => emit(TopProvidersLoaded(providers: providers)),
    );
  }

  /// Refreshes the top providers list
  Future<void> refresh() async {
    // Don't show loading if we already have data
    if (state is TopProvidersLoaded) {
      final result = await _repository.getTopProviders();
      result.fold(
        (failure) {
          // Keep existing data on error
          emit(TopProvidersError(
            message: failure.message,
            previousProviders: (state as TopProvidersLoaded).providers,
          ));
        },
        (providers) => emit(TopProvidersLoaded(providers: providers)),
      );
    } else {
      await loadTopProviders();
    }
  }
}
