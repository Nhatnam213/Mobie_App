import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_profile.dart';

class UserStore {
  static UserProfile? currentUser;

  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static String? get uid => _auth.currentUser?.uid;

  /// ✅ Clear cache khi logout / đổi tài khoản
  static void clear() {
    currentUser = null;
  }

  /// ✅ Tạo doc nếu chưa có + đảm bảo field tối thiểu
  static Future<void> createUserIfNotExists({String defaultRole = 'user'}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final ref = _db.collection('users').doc(user.uid);
    final doc = await ref.get();

    if (!doc.exists) {
      await ref.set({
        'id': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'phone': '',
        'bio': '',
        'role': defaultRole,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    // ✅ user cũ -> migrate field thiếu
    final data = doc.data() ?? {};
    final updates = <String, dynamic>{};

    if ((data['id'] ?? '').toString().trim().isEmpty) updates['id'] = user.uid;
    if ((data['email'] ?? '').toString().trim().isEmpty) updates['email'] = user.email ?? '';
    if (data['role'] == null) updates['role'] = defaultRole;

    final name = (data['name'] ?? '').toString().trim();
    if (name.isEmpty && (user.displayName ?? '').trim().isNotEmpty) {
      updates['name'] = user.displayName!.trim();
    }

    if (updates.isNotEmpty) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await ref.set(updates, SetOptions(merge: true));
    }
  }

  /// ✅ Load 1 lần (giữ lại cho bạn nếu đang dùng)
  static Future<void> loadCurrentUser({String defaultRole = 'user'}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await createUserIfNotExists(defaultRole: defaultRole);

    final doc = await _db.collection('users').doc(user.uid).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    data['id'] ??= doc.id;

    currentUser = UserProfile.fromMap(data);
  }

  /// ✅ NEW: Watch realtime (để web đổi tài khoản không cần reload)
  static Stream<UserProfile?> watchCurrentUser({String defaultRole = 'user'}) async* {
    // lắng nghe auth change
    await for (final user in _auth.authStateChanges()) {
      if (user == null) {
        clear();
        yield null;
        continue;
      }

      // đảm bảo doc tồn tại
      await createUserIfNotExists(defaultRole: defaultRole);

      // stream doc users/{uid}
      yield* _db.collection('users').doc(user.uid).snapshots().map((doc) {
        if (!doc.exists) return null;
        final data = doc.data() ?? {};
        data['id'] ??= doc.id;
        final profile = UserProfile.fromMap(data);
        currentUser = profile; // sync cache cho code cũ
        return profile;
      });
    }
  }

  /// ✅ Update profile
  static Future<void> updateProfile(UserProfile user) async {
    final userAuth = _auth.currentUser;
    if (userAuth == null) return;

    await _db.collection('users').doc(userAuth.uid).set({
      ...user.toMap(),
      'id': userAuth.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    currentUser = user;
  }
}
