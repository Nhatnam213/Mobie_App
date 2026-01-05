import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../widgets/job_card.dart';

class AdminAppliedJobsPage extends StatelessWidget {
  const AdminAppliedJobsPage({super.key});

  FirebaseFirestore get _db => FirebaseFirestore.instance;

  String _s(dynamic v, [String fallback = '—']) {
    final t = (v as String?)?.trim();
    return (t == null || t.isEmpty) ? fallback : t;
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _statusText(String s) {
    switch (s) {
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Đang chờ';
    }
  }

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

  Future<Map<String, dynamic>?> _fetchUser(String userId) async {
    final doc = await _db.collection('users').doc(userId).get();
    return doc.data();
  }

  Future<void> _updateAppliedStatus({
    required String docId,
    required String status,
  }) async {
    await _db.collection('applied_jobs').doc(docId).update({
      'status': status,
      'reviewedAt': FieldValue.serverTimestamp(),
    });
  }

  void _showUserProfileDialog(BuildContext context, String userId) async {
    showDialog(
      context: context,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final data = await _fetchUser(userId);
      if (context.mounted) Navigator.pop(context);

      showDialog(
        context: context,
        builder: (_) {
          final name = _s(data?['name'], _s(data?['displayName'], '—'));
          final email = _s(data?['email']);
          final phone = _s(data?['phone']);
          final school = _s(data?['school']);
          final major = _s(data?['major']);
          final bio = _s(data?['bio']);

          return AlertDialog(
            title: const Text('Hồ sơ ứng viên'),
            content: SizedBox(
              width: 420,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('👤 Tên: $name'),
                  const SizedBox(height: 6),
                  Text('📧 Email: $email'),
                  const SizedBox(height: 6),
                  Text('📞 SĐT: $phone'),
                  const SizedBox(height: 6),
                  Text('🏫 Trường: $school'),
                  const SizedBox(height: 6),
                  Text('📚 Ngành: $major'),
                  const SizedBox(height: 10),
                  Text('📝 Giới thiệu: $bio'),
                  const SizedBox(height: 10),
                  Text('🆔 userId: $userId', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Đóng'),
              ),
            ],
          );
        },
      );
    } catch (e) {
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không đọc được hồ sơ: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ Không orderBy để tránh lỗi appliedAt null
    final stream = _db.collection('applied_jobs').limit(300).snapshots();

    return Scaffold(
      appBar: AppBar(title: const Text('Ứng tuyển')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: stream,
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(child: Text('Lỗi: ${snap.error}'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final appliedDocs = snap.data!.docs;
          if (appliedDocs.isEmpty) {
            return const Center(child: Text('Chưa có ứng tuyển'));
          }

          final jobIds = appliedDocs
              .map((d) => _s(d.data()['jobId'], ''))
              .where((id) => id.isNotEmpty)
              .toSet()
              .toList();

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

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: appliedDocs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, i) {
                  final doc = appliedDocs[i];
                  final data = doc.data();

                  final jobId = _s(data['jobId'], '');
                  final userId = _s(data['userId'], '');
                  final status = _s(data['status'], 'applied');

                  final job = jobsMap[jobId];

                  return _AppliedCard(
                    job: job,
                    jobId: jobId,
                    userId: userId,
                    status: status,
                    statusColor: _statusColor(status),
                    statusText: _statusText(status),
                    onViewProfile: () => _showUserProfileDialog(context, userId),
                    onApprove: () => _updateAppliedStatus(docId: doc.id, status: 'approved'),
                    onReject: () => _updateAppliedStatus(docId: doc.id, status: 'rejected'),
                    onReset: () => _updateAppliedStatus(docId: doc.id, status: 'applied'),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _AppliedCard extends StatefulWidget {
  final Job? job;
  final String jobId;
  final String userId;
  final String status;
  final Color statusColor;
  final String statusText;

  final VoidCallback onViewProfile;
  final Future<void> Function() onApprove;
  final Future<void> Function() onReject;
  final Future<void> Function() onReset;

  const _AppliedCard({
    required this.job,
    required this.jobId,
    required this.userId,
    required this.status,
    required this.statusColor,
    required this.statusText,
    required this.onViewProfile,
    required this.onApprove,
    required this.onReject,
    required this.onReset,
  });

  @override
  State<_AppliedCard> createState() => _AppliedCardState();
}

class _AppliedCardState extends State<_AppliedCard> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() fn, String okMsg) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(okMsg)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Job
          if (widget.job != null)
            JobCard(
              job: widget.job!,
              isOwner: false,
              isFavorite: false,
              onTap: null,
              onFavoriteToggle: null,
              onEdit: null,
              onDelete: null,
            )
          else
            Text(
              'Job đã bị xoá / không tồn tại (jobId: ${widget.jobId})',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),

          const SizedBox(height: 10),

          // Applicant row
          Row(
            children: [
              const Icon(Icons.person, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'userId: ${widget.userId}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton.icon(
                onPressed: _busy ? null : widget.onViewProfile,
                icon: const Icon(Icons.badge_outlined, size: 18),
                label: const Text('Xem hồ sơ'),
              ),
            ],
          ),

          const SizedBox(height: 6),

          // Status chip
          Row(
            children: [
              const Icon(Icons.push_pin, size: 18),
              const SizedBox(width: 8),
              Text(
                'Trạng thái: ',
                style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: widget.statusColor.withOpacity(0.35)),
                ),
                child: Text(
                  widget.statusText,
                  style: TextStyle(fontWeight: FontWeight.w800, color: widget.statusColor),
                ),
              ),
              const Spacer(),
              if (widget.status != 'applied')
                TextButton(
                  onPressed: _busy ? null : () => _run(widget.onReset, 'Đã đưa về trạng thái chờ'),
                  child: const Text('Hoàn tác'),
                ),
            ],
          ),

          const SizedBox(height: 10),

          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: _busy ? null : () => _run(widget.onReject, 'Đã từ chối'),
                child: const Text('Từ chối'),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: _busy ? null : () => _run(widget.onApprove, 'Đã duyệt'),
                child: _busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Duyệt'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
