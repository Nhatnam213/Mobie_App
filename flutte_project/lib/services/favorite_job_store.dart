import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoriteJobStore {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('favorite_jobs');

  /// UID hiện tại
  static String get uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('Chưa đăng nhập');
    }
    return user.uid;
  }

  /// docId CHUẨN
  static String _docId(String jobId) => '${uid}_$jobId';

  /// Stream danh sách jobId đã favorite
  static Stream<List<String>> watchFavoriteJobIds(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((e) => (e.data()['jobId'] ?? '').toString())
              .where((id) => id.isNotEmpty)
              .toList(),
        );
  }

  /// Xoá tất cả doc legacy + doc chuẩn theo (uid, jobId)
  static Future<void> _deleteAllByUidJob(String jobId) async {
    final legacy = await _col
        .where('userId', isEqualTo: uid)
        .where('jobId', isEqualTo: jobId)
        .get();

    if (legacy.docs.isEmpty) return;

    // dùng batch cho chắc + nhanh
    final batch = _db.batch();
    for (final doc in legacy.docs) {
      batch.delete(doc.reference);
    }
    await batch.commit();
  }

  /// Toggle favorite (FIX TRIỆT ĐỂ)
  static Future<void> toggle(String jobId) async {
    final fixedRef = _col.doc(_docId(jobId));
    final fixedSnap = await fixedRef.get();

    if (fixedSnap.exists) {
      // ✅ UNFAVORITE
      // 🔥 xoá luôn mọi doc legacy (nếu còn) để không bao giờ nhảy lại
      await _deleteAllByUidJob(jobId);

      // và xoá doc chuẩn (phòng trường hợp doc chuẩn không nằm trong query do dữ liệu lỗi)
      await fixedRef.delete();
      return;
    }

    // ✅ FAVORITE ON
    // 1) xoá sạch legacy trước
    await _deleteAllByUidJob(jobId);

    // 2) set duy nhất doc chuẩn
    await fixedRef.set({
      'userId': uid,
      'jobId': jobId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// set trạng thái rõ ràng
  static Future<void> setFavorite(String jobId, bool value) async {
    if (value) {
      // bật favorite: đảm bảo sạch legacy trước khi set
      await _deleteAllByUidJob(jobId);
      await _col.doc(_docId(jobId)).set({
        'userId': uid,
        'jobId': jobId,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      // tắt favorite: xoá tất cả doc theo (uid, jobId)
      await _deleteAllByUidJob(jobId);
      await _col.doc(_docId(jobId)).delete();
    }
  }
}
