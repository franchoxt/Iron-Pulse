import 'enums.dart';

/// Perfil de usuario (extensión de auth.users)
class UserProfileModel {
  final String id;
  final String? fullName;
  final String? avatarUrl;
  final UserRole role;
  final DateTime? updatedAt;

  const UserProfileModel({
    required this.id,
    this.fullName,
    this.avatarUrl,
    this.role = UserRole.client,
    this.updatedAt,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isInstructor => role == UserRole.instructor;
  bool get isClient => role == UserRole.client;

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    return UserProfileModel(
      id: json['id'] as String,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String?),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String).toLocal()
          : null,
    );
  }

  UserProfileModel copyWith({
    String? id,
    String? fullName,
    String? avatarUrl,
    UserRole? role,
    DateTime? updatedAt,
  }) {
    return UserProfileModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'role': role.toDbString(),
      'updated_at': updatedAt?.toUtc().toIso8601String(),
    };
  }
}
