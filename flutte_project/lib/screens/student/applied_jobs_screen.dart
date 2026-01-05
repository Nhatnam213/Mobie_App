import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../widgets/job_card.dart';
import 'job_detail_screen.dart';

class AppliedJobsScreen extends StatelessWidget {
  const AppliedJobsScreen({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  String _s(dynamic v, [String fallback = '']) {
    final t = (v as String?)?.trim();
    return (t == null || t.isEmpty) ? fallback : t;
  }

  // ✅ Firestore whereIn giới hạn 10 -> chia batch
  Future<Map<String, Job>> _fetchJobsByIds(List<String> ids) async {
    final clean = ids.where((e) => e.trim().isNotEmpty).toSet().toList();
    if (clean.isEmpty) return {};

    final Map<String, Job> out = {};
    for (var i = 0; i < clean.length; i += 10) {
      final batch = clean.sublist(i, (i + 10 > clean.length) ? clean.length : i + 10);

      final snap = await _db
          .collection('jobs')
          .where(FieldPath.documentId, whereIn: batch)
          .get();

      for (final doc in snap.docs) {
        out[doc.id] = Job.fromMap(doc.id, doc.data());
      }
    }
    return out;
  }

  String _statusText(String status) {
    switch (status) {
      case 'approved':
        return '✅ Đã duyệt';
      case 'rejected':
        return '❌ Từ chối';
      default:
        return '⏳ Đang chờ';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Student chỉ cần đọc applied_jobs của chính mình
    final appliedStream = _db
        .collection('applied_jobs')
        .where('userId', isEqualTo: _uid)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: appliedStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Lỗi: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final appliedDocs = snap.data!.docs;

        if (appliedDocs.isEmpty) {
          return const Center(child: Text('Chưa ứng tuyển công việc nào'));
        }

        // map jobId -> status
        final Map<String, String> statusByJobId = {};
        final Set<String> jobIdsSet = {};

        for (final d in appliedDocs) {
          final data = d.data();
          final jobId = _s(data['jobId'], '');
          if (jobId.isEmpty) continue;
          jobIdsSet.add(jobId);
          statusByJobId[jobId] = _s(data['status'], 'applied'); // ✅ applied là mặc định
        }

        final jobIds = jobIdsSet.toList();
        if (jobIds.isEmpty) {
          return const Center(child: Text('Dữ liệu ứng tuyển lỗi: thiếu jobId'));
        }

        return FutureBuilder<Map<String, Job>>(
          future: _fetchJobsByIds(jobIds),
          builder: (context, jobsSnap) {
            if (jobsSnap.hasError) {
              return Center(child: Text('Lỗi load jobs: ${jobsSnap.error}'));
            }
            if (!jobsSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final jobsMap = jobsSnap.data!;

            // giữ thứ tự mới -> cũ theo appliedAt nếu có
            appliedDocs.sort((a, b) {
              final ta = a.data()['appliedAt'];
              final tb = b.data()['appliedAt'];
              final da = ta is Timestamp ? ta.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              final db = tb is Timestamp ? tb.toDate() : DateTime.fromMillisecondsSinceEpoch(0);
              return db.compareTo(da);
            });

            // build list theo appliedDocs để không bị “nhảy”
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: appliedDocs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final data = appliedDocs[i].data();
                final jobId = _s(data['jobId'], '');
                final status = _s(data['status'], 'applied');

                final job = jobsMap[jobId];

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (job != null)
                        JobCard(
                          job: job,
                          isOwner: false,
                          isFavorite: false,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => JobDetailScreen(job: job),
                              ),
                            );
                          },
                        )
                      else
                        Text(
                          'Job không còn tồn tại (jobId: $jobId)',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Trạng thái: ${_statusText(status)}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: _statusColor(status),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
