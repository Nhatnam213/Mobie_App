import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String bio;

  /// ✅ PHÂN QUYỀN
  /// 'admin' | 'user'
  final String role;

  /// ✅ TIMESTAMP
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    this.role = 'user',
    this.createdAt,
    this.updatedAt,
  });

  /// ===== COPY WITH =====
  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? role,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// ===== FIRESTORE MAP =====
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'role': role,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  /// ===== FROM FIRESTORE =====
  factory UserProfile.fromMap(Map<String, dynamic> map) {
    DateTime? _parse(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      return null;
    }

    return UserProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      role: map['role'] ?? 'user',
      createdAt: _parse(map['createdAt']),
      updatedAt: _parse(map['updatedAt']),
    );
  }
}
