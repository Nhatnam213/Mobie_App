import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/job_model.dart';

class CreatedJobStore {
  static final _db = FirebaseFirestore.instance;

  static const String createdCol = 'created_jobs';

  /// ===============================
  /// Job do user tạo (chờ duyệt / bị từ chối / đã duyệt nếu bạn vẫn giữ trong created_jobs)
  /// ===============================
  static Stream<List<Job>> watchMyJobs(String uid) {
    return _db
        .collection(createdCol)
        .where('ownerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((e) => Job.fromMap(e.id, e.data())).toList());
  }

  /// ===============================
  /// Tạo job (LUÔN ghi vào created_jobs với status = pending)
  /// ===============================
  static Future<void> create(Job job) async {
    if (job.ownerId.trim().isEmpty) {
      throw Exception('ownerId is empty. Không thể tạo job khi thiếu ownerId.');
    }

    final docRef = _db.collection(createdCol).doc(job.id);

    // ép status pending + tạo createdAt chuẩn
    final data = <String, dynamic>{
      ...job.toMap(),
      'ownerId': job.ownerId, // bắt buộc
      'createdBy': job.ownerId, // để tương thích rule cũ nếu bạn dùng createdBy
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(data);
  }

  /// ===============================
  /// Cập nhật job (user chỉ nên sửa khi pending theo rule)
  /// ===============================
  static Future<void> update(Job job) async {
    if (job.ownerId.trim().isEmpty) {
      throw Exception('ownerId is empty. Không thể update job khi thiếu ownerId.');
    }

    await _db.collection(createdCol).doc(job.id).update({
      ...job.toMap(),
      'ownerId': job.ownerId,
      'createdBy': job.ownerId,
    });
  }

  /// ===============================
  /// Xóa job (user chỉ nên xóa khi pending theo rule)
  /// ===============================
  static Future<void> delete(String jobId) async {
    await _db.collection(createdCol).doc(jobId).delete();
  }
}
