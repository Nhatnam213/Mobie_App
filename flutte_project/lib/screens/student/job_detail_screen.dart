import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../models/job_model.dart';

class JobDetailScreen extends StatefulWidget {
  final Job job; // giữ nguyên để không phải sửa chỗ gọi
  const JobDetailScreen({super.key, required this.job});

  @override
  State<JobDetailScreen> createState() => _JobDetailScreenState();
}

class _JobDetailScreenState extends State<JobDetailScreen> {
  bool _loading = false;

  String _t(String? v, [String fallback = '—']) {
    final s = v?.trim();
    return (s == null || s.isEmpty) ? fallback : s;
  }

  Future<void> _apply(Job jobFromDb) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập để ứng tuyển')),
      );
      return;
    }

    setState(() => _loading = true);

    final uid = user.uid;
    final jobId = jobFromDb.id;
    final jobsRef = FirebaseFirestore.instance.collection('jobs').doc(jobId);

    try {
      final jobSnap = await jobsRef.get();
      if (!jobSnap.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Công việc không tồn tại.')),
        );
        return;
      }

      final jobData = jobSnap.data() as Map<String, dynamic>;

      final ownerId =
          (jobData['ownerid'] ?? jobData['ownerId'] ?? '').toString();

      if (ownerId.isNotEmpty && ownerId == uid) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Bạn không thể ứng tuyển việc do chính bạn tạo.')),
        );
        return;
      }

      final appId = '${jobId}_$uid';
      final appliedRef =
          FirebaseFirestore.instance.collection('applied_jobs').doc(appId);

      final existed = await appliedRef.get();
      if (existed.exists) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bạn đã ứng tuyển công việc này rồi.')),
        );
        return;
      }

      await appliedRef.set({
        'jobId': jobId,
        'userId': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'applied',
        'jobTitle': (jobData['title'] ?? jobFromDb.title).toString(),
        'companyName': (jobData['companyName'] ?? jobFromDb.companyName).toString(),
        'location': (jobData['location'] ?? jobFromDb.location).toString(),
        'salary': (jobData['salary'] ?? jobFromDb.salary).toString(),
        'ownerId': ownerId,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Ứng tuyển thành công')),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Không thể ứng tuyển: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Lỗi: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final isLoggedIn = uid != null;

    final docRef =
        FirebaseFirestore.instance.collection('jobs').doc(widget.job.id);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const Scaffold(
            body: Center(child: Text('Job không tồn tại hoặc đã bị xoá')),
          );
        }

        final data = snap.data!.data();
        if (data == null) {
          return const Scaffold(
            body: Center(child: Text('Không đọc được dữ liệu job')),
          );
        }

        // ✅ LUÔN lấy job từ DB, không dùng cache object truyền vào
        final job = Job.fromMap(snap.data!.id, data);

        final contact = job.contact ?? {};
        final contactEmail = (contact['email'] ?? '').toString().trim();
        final contactPhone = (contact['phone'] ?? '').toString().trim();
        final hasContact = contactEmail.isNotEmpty || contactPhone.isNotEmpty;

        return Scaffold(
          appBar: AppBar(title: const Text('Chi tiết công việc')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  _t(job.title),
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 12),

                _row('🏢 Công ty', _t(job.companyName)),
                _row('📍 Địa điểm', _t(job.location)),
                _row('💰 Lương', _t(job.salary)),
                if (job.quantity.trim().isNotEmpty)
                  _row('👥 Số lượng', job.quantity.trim()),

                // ✅ THÔNG TIN LIÊN HỆ - lấy từ DB nên chắc chắn hiện nếu có
                if (hasContact) ...[
                  const SizedBox(height: 12),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    'Thông tin liên hệ',
                    style: TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 8),
                  if (contactEmail.isNotEmpty) _row('📧 Email', contactEmail),
                  if (contactPhone.isNotEmpty) _row('📞 SĐT', contactPhone),
                ],

                const SizedBox(height: 12),
                const Divider(),

                _section('Mô tả', _t(job.description)),
                _section('Yêu cầu', _t(job.requirements)),
                _section('Quyền lợi', _t(job.benefits)),

                const SizedBox(height: 16),

                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (!isLoggedIn || _loading) ? null : () => _apply(job),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Ứng tuyển'),
                  ),
                ),

                if (!isLoggedIn) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Bạn cần đăng nhập để ứng tuyển.',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(k, style: const TextStyle(fontWeight: FontWeight.w700)),
          ),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }

  Widget _section(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(content),
        ],
      ),
    );
  }
}
