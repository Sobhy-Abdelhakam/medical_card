import 'package:equatable/equatable.dart';

/// Core entity representing a medical service provider
class ProviderEntity extends Equatable {
  final int id;
  final String name;
  final String type;
  final String address;
  final String city;
  final String district;
  final String discountPct;
  final String? hours;
  final String phone;
  final String? email;
  final String? website;
  final String mapUrl;
  final String logoPath;
  final String? specialization;
  final String? package;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ProviderEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.district,
    required this.discountPct,
    this.hours,
    required this.phone,
    this.email,
    this.website,
    required this.mapUrl,
    required this.logoPath,
    this.specialization,
    this.package,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true if this provider has valid coordinates
  bool get hasValidCoordinates =>
      latitude != null &&
      longitude != null &&
      latitude! >= -90 &&
      latitude! <= 90 &&
      longitude! >= -180 &&
      longitude! <= 180;

  /// Returns the full logo URL
  String get fullLogoUrl {
    if (logoPath.isEmpty) return '';
    if (logoPath.startsWith('http')) return logoPath;
    return 'https://providers.euro-assist.com/$logoPath';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        address,
        city,
        district,
        discountPct,
        hours,
        phone,
        email,
        website,
        mapUrl,
        logoPath,
        specialization,
        package,
        latitude,
        longitude,
      ];

  @override
  String toString() => 'ProviderEntity(id: $id, name: $name, type: $type)';
}
