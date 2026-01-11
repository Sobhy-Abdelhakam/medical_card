import 'package:dartz/dartz.dart';

import '../../../../core/error/failures.dart';
import '../entities/entities.dart';

/// Request parameters for fetching providers
class GetProvidersParams {
  final String? searchName;
  final String? type;
  final String? search;
  final String? city;
  final String? district;
  final String? governorate;
  final bool paginate;
  final int page;
  final int perPage;

  const GetProvidersParams({
    this.searchName,
    this.type,
    this.search,
    this.city,
    this.district,
    this.governorate,
    this.paginate = false,
    this.page = 1,
    this.perPage = 25,
  });

  /// Creates params for loading branches of a specific provider
  factory GetProvidersParams.forBranches({
    required String searchName,
    String? type,
    String? search,
    bool paginate = true,
    int page = 1,
    int perPage = 25,
  }) =>
      GetProvidersParams(
        searchName: searchName,
        type: type,
        search: search,
        paginate: paginate,
        page: page,
        perPage: perPage,
      );

  /// Creates params for loading all providers of a type
  factory GetProvidersParams.forType({
    required String type,
    String? search,
    bool paginate = true,
    int page = 1,
    int perPage = 25,
  }) =>
      GetProvidersParams(
        type: type,
        search: search,
        paginate: paginate,
        page: page,
        perPage: perPage,
      );
}

/// Request parameters for free-form search
class SearchProvidersParams {
  final String query;
  final String? type;
  final String? city;
  final String? district;
  final String? governorate;
  final int page;
  final int perPage;

  const SearchProvidersParams({
    required this.query,
    this.type,
    this.city,
    this.district,
    this.governorate,
    this.page = 1,
    this.perPage = 25,
  });
}

/// Response wrapper for paginated providers
class ProvidersResponse {
  final List<ProviderEntity> providers;
  final PaginationEntity? pagination;

  const ProvidersResponse({
    required this.providers,
    this.pagination,
  });
}

/// Repository contract for providers feature
abstract class ProvidersRepository {
  /// Fetches list of top providers for home screen cards
  Future<Either<Failure, List<TopProviderEntity>>> getTopProviders();

  /// Fetches providers with optional filtering and pagination
  Future<Either<Failure, ProvidersResponse>> getProviders(
    GetProvidersParams params,
  );

  /// Performs free-form search across all provider fields
  Future<Either<Failure, ProvidersResponse>> searchProviders(
    SearchProvidersParams params,
  );
}
