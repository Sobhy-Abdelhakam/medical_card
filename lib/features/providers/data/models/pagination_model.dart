import '../../domain/entities/pagination_entity.dart';

/// Data model for Pagination with JSON serialization
class PaginationModel extends PaginationEntity {
  const PaginationModel({
    required super.currentPage,
    required super.lastPage,
    required super.perPage,
    required super.total,
    super.from,
    super.to,
  });

  /// Creates a PaginationModel from JSON map (pagination format from API)
  factory PaginationModel.fromJson(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
      perPage: _parseInt(json['per_page']),
      total: _parseInt(json['total']),
      from: json['from'] != null ? _parseInt(json['from']) : null,
      to: json['to'] != null ? _parseInt(json['to']) : null,
    );
  }

  /// Creates a PaginationModel from meta format (used in search responses)
  factory PaginationModel.fromMeta(Map<String, dynamic> json) {
    return PaginationModel(
      currentPage: _parseInt(json['current_page']),
      lastPage: _parseInt(json['last_page']),
      perPage: _parseInt(json['per_page']),
      total: _parseInt(json['total']),
      from: json['from'] != null ? _parseInt(json['from']) : null,
      to: json['to'] != null ? _parseInt(json['to']) : null,
    );
  }

  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'current_page': currentPage,
      'last_page': lastPage,
      'per_page': perPage,
      'total': total,
      'from': from,
      'to': to,
    };
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 1;
    if (value is num) return value.toInt();
    return 1;
  }
}
