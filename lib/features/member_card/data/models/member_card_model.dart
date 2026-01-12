import '../../domain/entities/member_card_entity.dart';

/// Data model for MemberCard with JSON serialization
class MemberCardModel extends MemberCardEntity {
  const MemberCardModel({
    required super.id,
    required super.memberName,
    required super.memberNumber,
    required super.clubName,
    super.cardImageUrl,
    super.qrCode,
    super.barcode,
    required super.status,
    super.validFrom,
    super.validUntil,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a MemberCardModel from JSON map
  factory MemberCardModel.fromJson(Map<String, dynamic> json) {
    return MemberCardModel(
      id: _parseInt(json['id']),
      memberName: json['member_name']?.toString() ??
                  json['name']?.toString() ?? '',
      memberNumber: json['member_number']?.toString() ??
                    json['card_number']?.toString() ?? '',
      clubName: json['club_name']?.toString() ??
                json['club']?.toString() ?? 'Euro Medical Card',
      cardImageUrl: json['card_image_url']?.toString() ??
                    json['card_image']?.toString() ??
                    json['image']?.toString(),
      qrCode: json['qr_code']?.toString(),
      barcode: json['barcode']?.toString(),
      status: MemberCardStatus.fromString(json['status']?.toString()),
      validFrom: _parseDateTime(json['valid_from'] ?? json['start_date']),
      validUntil: _parseDateTime(json['valid_until'] ?? json['end_date'] ?? json['expiry_date']),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'member_name': memberName,
      'member_number': memberNumber,
      'club_name': clubName,
      'card_image_url': cardImageUrl,
      'qr_code': qrCode,
      'barcode': barcode,
      'status': status.toApiString(),
      'valid_from': validFrom?.toIso8601String(),
      'valid_until': validUntil?.toIso8601String(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this model with updated fields
  MemberCardModel copyWith({
    int? id,
    String? memberName,
    String? memberNumber,
    String? clubName,
    String? cardImageUrl,
    String? qrCode,
    String? barcode,
    MemberCardStatus? status,
    DateTime? validFrom,
    DateTime? validUntil,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MemberCardModel(
      id: id ?? this.id,
      memberName: memberName ?? this.memberName,
      memberNumber: memberNumber ?? this.memberNumber,
      clubName: clubName ?? this.clubName,
      cardImageUrl: cardImageUrl ?? this.cardImageUrl,
      qrCode: qrCode ?? this.qrCode,
      barcode: barcode ?? this.barcode,
      status: status ?? this.status,
      validFrom: validFrom ?? this.validFrom,
      validUntil: validUntil ?? this.validUntil,
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

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
