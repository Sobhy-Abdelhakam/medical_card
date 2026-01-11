import '../../domain/entities/provider_entity.dart';

/// Data model for Provider with JSON serialization
class ProviderModel extends ProviderEntity {
  const ProviderModel({
    required super.id,
    required super.name,
    required super.type,
    required super.address,
    required super.city,
    required super.district,
    required super.discountPct,
    super.hours,
    required super.phone,
    super.email,
    super.website,
    required super.mapUrl,
    required super.logoPath,
    super.specialization,
    super.package,
    super.latitude,
    super.longitude,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a ProviderModel from JSON map
  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: _parseInt(json['id']),
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      discountPct: json['discount_pct']?.toString() ?? '',
      hours: json['hours']?.toString(),
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      website: json['website']?.toString(),
      mapUrl: json['map_url']?.toString() ?? '',
      logoPath: json['logo_path']?.toString() ?? '',
      specialization: json['specialization']?.toString(),
      package: json['package']?.toString(),
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'address': address,
      'city': city,
      'district': district,
      'discount_pct': discountPct,
      'hours': hours,
      'phone': phone,
      'email': email,
      'website': website,
      'map_url': mapUrl,
      'logo_path': logoPath,
      'specialization': specialization,
      'package': package,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this model with updated fields
  ProviderModel copyWith({
    int? id,
    String? name,
    String? type,
    String? address,
    String? city,
    String? district,
    String? discountPct,
    String? hours,
    String? phone,
    String? email,
    String? website,
    String? mapUrl,
    String? logoPath,
    String? specialization,
    String? package,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      discountPct: discountPct ?? this.discountPct,
      hours: hours ?? this.hours,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      mapUrl: mapUrl ?? this.mapUrl,
      logoPath: logoPath ?? this.logoPath,
      specialization: specialization ?? this.specialization,
      package: package ?? this.package,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Helper methods for safe parsing

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
