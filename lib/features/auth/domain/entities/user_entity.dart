import 'package:equatable/equatable.dart';

/// Core entity representing an authenticated user
class UserEntity extends Equatable {
  final int id;
  final String username;
  final String? name;
  final String? email;
  final String? phone;
  final String? memberNumber;
  final String? clubName;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserEntity({
    required this.id,
    required this.username,
    this.name,
    this.email,
    this.phone,
    this.memberNumber,
    this.clubName,
    this.createdAt,
    this.updatedAt,
  });

  /// Returns true if this user has member information
  bool get isMember => memberNumber != null && memberNumber!.isNotEmpty;

  /// Returns the display name (name if available, otherwise username)
  String get displayName => name?.isNotEmpty == true ? name! : username;

  @override
  List<Object?> get props => [
        id,
        username,
        name,
        email,
        phone,
        memberNumber,
        clubName,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() => 'UserEntity(id: $id, username: $username, name: $name)';
}
