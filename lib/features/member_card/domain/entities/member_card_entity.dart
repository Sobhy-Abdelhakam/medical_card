import 'package:equatable/equatable.dart';

/// Core entity representing a member card
class MemberCardEntity extends Equatable {
  final int id;
  final String memberName;
  final String memberNumber;
  final String clubName;
  final String? cardImageUrl;
  final String? qrCode;
  final String? barcode;
  final MemberCardStatus status;
  final DateTime? validFrom;
  final DateTime? validUntil;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemberCardEntity({
    required this.id,
    required this.memberName,
    required this.memberNumber,
    required this.clubName,
    this.cardImageUrl,
    this.qrCode,
    this.barcode,
    required this.status,
    this.validFrom,
    this.validUntil,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true if the card is currently valid
  bool get isValid {
    if (status != MemberCardStatus.active) return false;
    if (validUntil == null) return true;
    return DateTime.now().isBefore(validUntil!);
  }

  /// Returns true if the card is expired
  bool get isExpired {
    if (validUntil == null) return false;
    return DateTime.now().isAfter(validUntil!);
  }

  /// Returns the remaining days until expiry
  int? get daysUntilExpiry {
    if (validUntil == null) return null;
    final difference = validUntil!.difference(DateTime.now());
    return difference.inDays;
  }

  @override
  List<Object?> get props => [
        id,
        memberName,
        memberNumber,
        clubName,
        cardImageUrl,
        qrCode,
        barcode,
        status,
        validFrom,
        validUntil,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() =>
      'MemberCardEntity(id: $id, memberName: $memberName, memberNumber: $memberNumber)';
}

/// Status of a member card
enum MemberCardStatus {
  active,
  inactive,
  expired,
  suspended,
  pending;

  /// Creates a MemberCardStatus from a string value
  static MemberCardStatus fromString(String? value) {
    if (value == null) return MemberCardStatus.pending;

    switch (value.toLowerCase()) {
      case 'active':
        return MemberCardStatus.active;
      case 'inactive':
        return MemberCardStatus.inactive;
      case 'expired':
        return MemberCardStatus.expired;
      case 'suspended':
        return MemberCardStatus.suspended;
      case 'pending':
      default:
        return MemberCardStatus.pending;
    }
  }

  /// Returns the string representation for API
  String toApiString() {
    switch (this) {
      case MemberCardStatus.active:
        return 'active';
      case MemberCardStatus.inactive:
        return 'inactive';
      case MemberCardStatus.expired:
        return 'expired';
      case MemberCardStatus.suspended:
        return 'suspended';
      case MemberCardStatus.pending:
        return 'pending';
    }
  }

  /// Returns the Arabic display name
  String get displayName {
    switch (this) {
      case MemberCardStatus.active:
        return 'نشطة';
      case MemberCardStatus.inactive:
        return 'غير نشطة';
      case MemberCardStatus.expired:
        return 'منتهية';
      case MemberCardStatus.suspended:
        return 'معلقة';
      case MemberCardStatus.pending:
        return 'قيد الانتظار';
    }
  }
}
