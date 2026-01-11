import 'package:equatable/equatable.dart';

/// Entity representing pagination metadata from API responses
class PaginationEntity extends Equatable {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;

  const PaginationEntity({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  /// Returns true if there are more pages available
  bool get hasMorePages => currentPage < lastPage;

  /// Returns true if this is the first page
  bool get isFirstPage => currentPage == 1;

  /// Returns true if this is the last page
  bool get isLastPage => currentPage >= lastPage;

  /// Creates a default single-page pagination
  factory PaginationEntity.single(int total) => PaginationEntity(
        currentPage: 1,
        lastPage: 1,
        perPage: total,
        total: total,
        from: 1,
        to: total,
      );

  @override
  List<Object?> get props => [currentPage, lastPage, perPage, total, from, to];

  @override
  String toString() =>
      'PaginationEntity(page: $currentPage/$lastPage, total: $total)';
}
