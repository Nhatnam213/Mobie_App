import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAppliedJobStore {
  static final _db = FirebaseFirestore.instance;

  /// Stream toàn bộ applied_jobs (admin)
  /// Bạn có thể đổi limit tuỳ ý
  static Stream<QuerySnapshot<Map<String, dynamic>>> watchAllApplied({
    int limit = 200,
  }) {
    return _db
        .collection('applied_jobs')
        .orderBy('appliedAt', descending: true)
        .limit(limit)
        .snapshots();
  }

  /// Fetch nhiều doc theo ids, tự chia batch 10 (Firestore whereIn limit)
  static Future<Map<String, Map<String, dynamic>>> fetchDocsByIds({
    required String collection,
    required List<String> ids,
  }) async {
    final clean = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (clean.isEmpty) return {};

    final Map<String, Map<String, dynamic>> out = {};

    for (var i = 0; i < clean.length; i += 10) {
      final batch = clean.sublist(i, (i + 10 > clean.length) ? clean.length : i + 10);

      final snap = await _db
          .collection(collection)
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snap.docs) {
        out[doc.id] = doc.data();
      }
    }
    return out;
  }
}
