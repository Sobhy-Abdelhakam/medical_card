import '../../domain/entities/top_provider_entity.dart';

/// Data model for Top Provider with JSON serialization
class TopProviderModel extends TopProviderEntity {
  const TopProviderModel({
    required super.id,
    required super.nameEnglish,
    required super.nameArabic,
    required super.typeEnglish,
    required super.typeArabic,
    required super.logoUrl,
  });

  /// Creates a TopProviderModel from JSON map
  factory TopProviderModel.fromJson(Map<String, dynamic> json) {
    return TopProviderModel(
      id: _parseInt(json['id']),
      nameEnglish: json['name_english']?.toString() ?? '',
      nameArabic: json['name_arabic']?.toString() ?? '',
      typeEnglish: json['type_en']?.toString() ?? '',
      typeArabic: json['type_ar']?.toString() ?? '',
      logoUrl: json['logo_url']?.toString() ?? '',
    );
  }

  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name_english': nameEnglish,
      'name_arabic': nameArabic,
      'type_en': typeEnglish,
      'type_ar': typeArabic,
      'logo_url': logoUrl,
    };
  }

  /// Creates a copy of this model with updated fields
  TopProviderModel copyWith({
    int? id,
    String? nameEnglish,
    String? nameArabic,
    String? typeEnglish,
    String? typeArabic,
    String? logoUrl,
  }) {
    return TopProviderModel(
      id: id ?? this.id,
      nameEnglish: nameEnglish ?? this.nameEnglish,
      nameArabic: nameArabic ?? this.nameArabic,
      typeEnglish: typeEnglish ?? this.typeEnglish,
      typeArabic: typeArabic ?? this.typeArabic,
      logoUrl: logoUrl ?? this.logoUrl,
    );
  }

  static int _parseInt(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    if (value is num) return value.toInt();
    return 0;
  }
}
