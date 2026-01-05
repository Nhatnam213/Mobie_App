import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import 'create_job_screen.dart';
import 'edit_job_screen.dart';

class CreatedJobsScreen extends StatelessWidget {
  /// embedded = true  -> dùng trong Tab (KHÔNG AppBar / KHÔNG FAB)
  /// embedded = false -> màn standalone (CÓ AppBar / CÓ FAB)
  final bool embedded;

  const CreatedJobsScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      // ✅ Không còn dòng "Việc tôi tạo" nữa (vì không có AppBar)
      return const CreatedJobsBody();
    }

    // ✅ Standalone screen (có AppBar + FAB)
    return Scaffold(
      appBar: AppBar(title: const Text('Việc tôi tạo')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateJobScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: const CreatedJobsBody(),
    );
  }
}

/// ✅ Body-only: dùng trong MyJobsScreen tab "Tôi tạo" để KHÔNG bị double AppBar
class CreatedJobsBody extends StatefulWidget {
  const CreatedJobsBody({super.key});

  @override
  State<CreatedJobsBody> createState() => _CreatedJobsBodyState();
}

class _CreatedJobsBodyState extends State<CreatedJobsBody> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String _s(dynamic v, [String fallback = '—']) {
    if (v == null) return fallback;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? fallback : t;
    }
    return v.toString();
  }

  int _i(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  String _statusText(String s) {
    switch (s) {
      case 'approved':
        return '✅ Đã duyệt';
      case 'rejected':
        return '❌ Đã từ chối';
      default:
        return '⏳ Chờ duyệt';
    }
  }

  Color _statusColor(BuildContext context, String s) {
    final cs = Theme.of(context).colorScheme;
    switch (s) {
      case 'approved':
        return cs.tertiary;
      case 'rejected':
        return cs.error;
      default:
        return cs.primary;
    }
  }

  Job _toJob(String id, Map<String, dynamic> data) {
    return Job(
      id: id,
      title: _s(data['title'], _s(data['jobName'], '')),
      salary: _s(data['salary'], ''),
      location: _s(data['location'], ''),
      companyName: _s(data['companyName'], _s(data['company'], '')),
      description: _s(data['description'], ''),
      requirements: _s(data['requirements'], ''),
      benefits: _s(data['benefits'], ''),
      quantity: _i(data['quantity'], 0).toString(),
      ownerId: _s(data['createdBy'], _s(data['ownerId'], '')),
      status: _s(data['status'], 'pending'),
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp)
          : Timestamp.fromMillisecondsSinceEpoch(0),
      jobName: _s(data['jobName'], _s(data['title'], '')),
    );
  }

  Future<void> _deleteJob(String jobId) async {
    try {
      await _db.collection('created_jobs').doc(jobId).delete();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🗑️ Đã xoá công việc')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Xoá thất bại: $e')),
      );
    }
  }

  Future<void> _confirmDelete(String jobId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Xoá công việc?'),
        content: const Text('Bạn chắc chắn muốn xoá công việc này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _deleteJob(jobId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Bạn chưa đăng nhập'));
    }

    final createdStream = _db
        .collection('created_jobs')
        .where('createdBy', isEqualTo: user.uid)
        .orderBy('createdAt', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: createdStream,
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Lỗi tải dữ liệu: ${snap.error}'),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('Chưa tạo công việc nào'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final doc = docs[i];
            final data = doc.data();

            final title = _s(data['title'], _s(data['jobName']));
            final salary = _s(data['salary']);
            final location = _s(data['location']);
            final companyName = _s(data['companyName']);
            final quantity = _i(data['quantity'], 0);

            final status = _s(data['status'], 'pending');
            final statusColor = _statusColor(context, status);

            // ✅ RULE THEO YÊU CẦU CỦA BẠN
            final canEdit = status == 'pending';
            final canDelete = status == 'rejected' || status == 'approved';

            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Theme.of(context)
                      .colorScheme
                      .outlineVariant
                      .withOpacity(0.35),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: statusColor.withOpacity(0.35),
                      ),
                    ),
                    child: Icon(Icons.work, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 6),
                        if (companyName != '—') Text('🏢 $companyName'),
                        Text('💰 Lương: $salary'),
                        Text('📍 Địa điểm: $location'),
                        if (quantity > 0) Text('👥 Tuyển: $quantity người'),
                        const SizedBox(height: 8),
                        Text(
                          _statusText(status),
                          style: TextStyle(
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                        if (status == 'rejected') ...[
                          const SizedBox(height: 6),
                          Text(
                            'Lý do: ${_s(data['rejectReason'], '—')}',
                            style: TextStyle(
                              color:
                                  Theme.of(context).colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  // ✅ ACTIONS THEO STATUS
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (canEdit)
                        IconButton(
                          tooltip: 'Sửa',
                          onPressed: () {
                            final job = _toJob(doc.id, data);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditJobScreen(job: job),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit),
                        ),

                      if (canDelete)
                        IconButton(
                          tooltip: 'Xoá',
                          onPressed: () => _confirmDelete(doc.id),
                          icon: const Icon(Icons.delete),
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
  }
}
