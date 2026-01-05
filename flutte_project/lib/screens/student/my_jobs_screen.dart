import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/applied_job_store.dart';
import 'created_jobs_screen.dart';

class MyJobsScreen extends StatelessWidget {
  const MyJobsScreen({super.key});

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  String _statusText(String s) {
    final status = (s == 'applied') ? 'pending' : s;
    switch (status) {
      case 'approved':
        return '✅ Đã ứng tuyển';
      case 'rejected':
        return '❌ Bị từ chối';
      default:
        return '⏳ Đang chờ duyệt';
    }
  }

  Color _statusColor(String s) {
    final status = (s == 'applied') ? 'pending' : s;
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Việc của tôi'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Đã ứng tuyển'),
              Tab(text: 'Tôi tạo'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _AppliedTab(
              uid: _uid,
              statusText: _statusText,
              statusColor: _statusColor,
            ),

            // ✅ FIX DOUBLE: dùng embedded=true => không AppBar, không "Việc tôi tạo"
            const CreatedJobsScreen(embedded: true),
          ],
        ),
      ),
    );
  }
}

class _AppliedTab extends StatelessWidget {
  final String uid;
  final String Function(String) statusText;
  final Color Function(String) statusColor;

  const _AppliedTab({
    required this.uid,
    required this.statusText,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Job>>(
      stream: AppliedJobStore.watchMyAppliedJobs(uid),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final jobs = snap.data!;
        if (jobs.isEmpty) {
          return const Center(child: Text('Chưa ứng tuyển công việc nào'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, i) {
            final job = jobs[i];

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          job.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('💰 Lương: ${job.salary}'),
                        Text('📍 Địa điểm: ${job.location}'),
                        const SizedBox(height: 10),
                        Text(
                          statusText(job.status),
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: statusColor(job.status),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    onTap: () async {
                      try {
                        await AppliedJobStore.remove(uid, job.id);
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xoá ứng tuyển')),
                        );
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    },
                    child: Row(
                      children: const [
                        Icon(Icons.delete, size: 18, color: Colors.deepPurple),
                        SizedBox(width: 6),
                        Text('Xóa', style: TextStyle(color: Colors.deepPurple)),
                      ],
                    ),
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
