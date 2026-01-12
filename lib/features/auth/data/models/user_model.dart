import '../../domain/entities/user_entity.dart';

/// Data model for User with JSON serialization
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.username,
    super.name,
    super.email,
    super.phone,
    super.memberNumber,
    super.clubName,
    super.createdAt,
    super.updatedAt,
  });

  /// Creates a UserModel from JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _parseInt(json['id']),
      username: json['username']?.toString() ?? '',
      name: json['name']?.toString(),
      email: json['email']?.toString(),
      phone: json['phone']?.toString(),
      memberNumber: json['member_number']?.toString(),
      clubName: json['club_name']?.toString(),
      createdAt: _parseDateTime(json['created_at']),
      updatedAt: _parseDateTime(json['updated_at']),
    );
  }

  /// Converts the model to a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'name': name,
      'email': email,
      'phone': phone,
      'member_number': memberNumber,
      'club_name': clubName,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Creates a copy of this model with updated fields
  UserModel copyWith({
    int? id,
    String? username,
    String? name,
    String? email,
    String? phone,
    String? memberNumber,
    String? clubName,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      memberNumber: memberNumber ?? this.memberNumber,
      clubName: clubName ?? this.clubName,
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
