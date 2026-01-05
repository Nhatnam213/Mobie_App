class AppUser {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String bio;
  final String avatarUrl;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.bio,
    required this.avatarUrl,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> data) {
    return AppUser(
      uid: uid,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      bio: data['bio'] ?? '',
      avatarUrl: data['avatarUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'email': email,
        'phone': phone,
        'bio': bio,
        'avatarUrl': avatarUrl,
      };

  AppUser copyWith({
    String? name,
    String? phone,
    String? bio,
    String? avatarUrl,
  }) {
    return AppUser(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }
}
