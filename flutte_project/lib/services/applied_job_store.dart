import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/job_model.dart';

class AppliedJobStore {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('applied_jobs');

  /// ===============================
  /// ỨNG TUYỂN
  /// ===============================
  static Future<void> apply(Job job) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    // chặn ứng tuyển job của chính mình
    if (job.ownerId == user.uid) {
      throw Exception('Không thể ứng tuyển công việc do chính bạn tạo');
    }

    final docId = '${job.id}_${user.uid}';

    // ✅ tạo/ghi đè doc ứng tuyển
    await _col.doc(docId).set({
      'jobId': job.id,
      'jobTitle': job.title,
      'location': job.location,
      'salary': job.salary,
      'ownerId': job.ownerId,
      'userId': user.uid,

      // ✅ Flow chuẩn:
      // pending -> admin duyệt thành approved / rejected
      'status': 'pending',

      // ✅ đặt đúng tên appliedAt cho dễ dùng chung
      'appliedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// ===============================
  /// DANH SÁCH ĐÃ ỨNG TUYỂN (student xem)
  /// ===============================
  static Stream<List<Job>> watchMyAppliedJobs(String uid) {
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((snap) {
          final docs = snap.docs.toList();

          // sort client-side để không phụ thuộc field null
          docs.sort((a, b) {
            final ta = a.data()['appliedAt'];
            final tb = b.data()['appliedAt'];
            final da = ta is Timestamp
                ? ta.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            final db = tb is Timestamp
                ? tb.toDate()
                : DateTime.fromMillisecondsSinceEpoch(0);
            return db.compareTo(da);
          });

          return docs.map((doc) {
            final d = doc.data();

            return Job(
              id: d['jobId'],
              title: d['jobTitle'] ?? '',
              salary: d['salary'] ?? '',
              location: d['location'] ?? '',
              ownerId: d['ownerId'] ?? '',

              // ✅ student UI sẽ đọc status này để hiện:
              // pending = chờ duyệt, approved = đã ứng tuyển, rejected = bị từ chối
              status: d['status'] ?? 'pending',

              // giữ createdAt cho model (nếu model đang dùng createdAt)
              createdAt: d['appliedAt'] ?? Timestamp.now(),
            );
          }).toList();
        });
  }

  /// ===============================
  /// HUỶ ỨNG TUYỂN
  /// ===============================
  static Future<void> remove(String uid, String jobId) async {
    await _col.doc('${jobId}_$uid').delete();
  }
}
