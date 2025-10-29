class ServiceProvider {
  final int id;
  final String name;
  final String type;
  final String address;
  final String city;
  final String district;
  final String discount;
  final String hours;
  final String phone;
  final String email;
  final String website;
  final String mapUrl;
  final String logoPath;
  final String? specialization;
  final String? package;
  final double? latitude;
  final double? longitude;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.type,
    required this.address,
    required this.city,
    required this.district,
    required this.discount,
    required this.hours,
    required this.phone,
    required this.email,
    required this.website,
    required this.mapUrl,
    required this.logoPath,
    this.specialization,
    this.package,
    this.latitude,
    this.longitude,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      address: json['address'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      discount: json['discount_pct'] ?? '',
      hours: json['hours'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      website: json['website'] ?? '',
      mapUrl: json['map_url'] ?? '',
      logoPath: json['logo_path'] ?? '',
      specialization: json['specialization'],
      package: json['package'],
      latitude: json['latitude'] != null ? (json['latitude'] is int ? (json['latitude'] as int).toDouble() : json['latitude'] as double) : null,
      longitude: json['longitude'] != null ? (json['longitude'] is int ? (json['longitude'] as int).toDouble() : json['longitude'] as double) : null,
    );
  }
}

class TopProvider {
  final int id;
  final String nameEnglish;
  final String nameArabic;
  final String logoUrl;
  final String typeArabic;

  TopProvider({
    required this.id,
    required this.nameEnglish,
    required this.nameArabic,
    required this.logoUrl,
    required this.typeArabic,
  });

  factory TopProvider.fromJson(Map<String, dynamic> json) {
    return TopProvider(
      id: json['id'] ?? 0,
      nameEnglish: json['name_english'] ?? '',
      nameArabic: json['name_arabic'] ?? '',
      logoUrl: json['logo_url'] ?? '',
      typeArabic: json['type_ar'] ?? '',
    );
  }
}
