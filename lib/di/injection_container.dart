import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/network/api_client.dart';
import '../core/network/network_info.dart';
import '../features/intro/data/repositories/intro_repository_impl.dart';
import '../features/intro/domain/repositories/intro_repository.dart';
import '../features/intro/presentation/cubit/splash/splash_cubit.dart';
import '../features/providers/data/datasources/providers_remote_datasource.dart';
import '../features/providers/data/repositories/providers_repository_impl.dart';
import '../features/providers/domain/repositories/providers_repository.dart';
import '../features/providers/presentation/cubit/map_providers/map_providers_cubit.dart';
import '../features/providers/presentation/cubit/providers_list/providers_list_cubit.dart';
import '../features/providers/presentation/cubit/top_providers/top_providers_cubit.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initializes all dependencies
Future<void> initDependencies() async {
  // ===== CORE =====

  // External
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerLazySingleton(() => sharedPreferences);

  // Network
  sl.registerLazySingleton<ApiClient>(() => ApiClient());
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl());

  // ===== FEATURES - PROVIDERS =====

  // Data Sources
  sl.registerLazySingleton<ProvidersRemoteDataSource>(
    () => ProvidersRemoteDataSourceImpl(apiClient: sl()),
  );

  // Repository
  sl.registerLazySingleton<ProvidersRepository>(
    () => ProvidersRepositoryImpl(
      remoteDataSource: sl(),
      networkInfo: sl(),
    ),
  );

  // Features - Intro
  sl.registerFactory(() => SplashCubit(repository: sl()));
  sl.registerLazySingleton<IntroRepository>(
      () => IntroRepositoryImpl(apiClient: sl(), sharedPreferences: sl()));

  // Cubits
  sl.registerFactory<TopProvidersCubit>(
    () => TopProvidersCubit(repository: sl()),
  );

  sl.registerFactory<ProvidersListCubit>(
    () => ProvidersListCubit(repository: sl()),
  );

  sl.registerFactory<MapProvidersCubit>(
    () => MapProvidersCubit(repository: sl()),
  );
}
