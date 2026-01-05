import 'dart:async';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/job_model.dart';
import '../../services/favorite_job_store.dart';
import 'job_detail_screen.dart';

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final _db = FirebaseFirestore.instance;

  final _searchCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _sort = 'newest';

  StreamSubscription<List<String>>? _favSub;
  Set<String> _favoriteJobIds = {};

  bool _checkingRole = true;
  bool _isAdmin = false;

  // ============ helpers ============
  String _s(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) {
      final t = v.trim();
      return t.isEmpty ? fallback : t;
    }
    return v.toString();
  }

  String _qtyToString(dynamic v) {
    if (v == null) return '';
    if (v is int) return v.toString();
    if (v is double) return v.toInt().toString();
    if (v is String) return v.trim();
    return v.toString();
  }

  Timestamp _ts(dynamic v) {
    if (v is Timestamp) return v;
    return Timestamp.fromMillisecondsSinceEpoch(0);
  }

  int _salaryToNumber(String salaryText) {
    final digits = salaryText.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }

  // ============ init ============
  @override
  void initState() {
    super.initState();
    _bindFavorites();
    _loadRoleOnce();
  }

  void _bindFavorites() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _favSub?.cancel();
    _favSub = FavoriteJobStore.watchFavoriteJobIds(user.uid).listen((ids) {
      if (!mounted) return;
      setState(() => _favoriteJobIds = ids.toSet());
    });
  }

  Future<void> _loadRoleOnce() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _checkingRole = false);
      return;
    }

    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final data = snap.data();

      final role = data?['role'];
      final isAdmin = data?['isAdmin'] == true || role == 'admin';

      if (!mounted) return;
      setState(() {
        _isAdmin = isAdmin;
        _checkingRole = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAdmin = false;
        _checkingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _favSub?.cancel();
    _searchCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  // ============ delete ============
  Future<void> _deleteJob(String jobId) async {
    if (!_isAdmin) return;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa công việc'),
        content: const Text(
          'Bạn chắc chắn muốn xóa công việc này?\n'
          'Hành động này KHÔNG thể hoàn tác.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      final batch = _db.batch();
      batch.delete(_db.collection('jobs').doc(jobId));
      batch.delete(_db.collection('created_jobs').doc(jobId));
      await batch.commit();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đã xóa công việc')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Xóa thất bại: $e')),
      );
    }
  }

  // ============ UI ============
  @override
  Widget build(BuildContext context) {
    if (_checkingRole) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      backgroundColor: const Color(0xfff7f6fb),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFilters(),
            Expanded(child: _buildJobList()),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    InputDecoration dec(String hint, IconData icon) => InputDecoration(
          prefixIcon: Icon(icon),
          hintText: hint,
          filled: true,
          fillColor: const Color(0xfff3f3f3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
      ),
      child: Column(
        children: [
          TextField(
            controller: _searchCtrl,
            decoration: dec('Tìm công việc...', Icons.search),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _locationCtrl,
                  decoration: dec('Địa điểm', Icons.location_on_outlined),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _sort,
                  items: const [
                    DropdownMenuItem(value: 'newest', child: Text('Mới nhất')),
                    DropdownMenuItem(value: 'oldest', child: Text('Cũ nhất')),
                    DropdownMenuItem(value: 'salary_asc', child: Text('Lương ↑')),
                    DropdownMenuItem(value: 'salary_desc', child: Text('Lương ↓')),
                  ],
                  onChanged: (v) => setState(() => _sort = v!),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildJobList() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _db.collection('jobs').orderBy('approvedAt', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        List<Job> jobs = snapshot.data!.docs.map((doc) {
          final data = doc.data();
          return Job(
            id: doc.id,
            title: _s(data['title'], _s(data['jobName'], 'Công việc')),
            salary: _s(data['salary'], 'Thỏa thuận'),
            location: _s(data['location'], 'Chưa cập nhật'),
            quantity: _qtyToString(data['quantity']),
            status: 'approved',
            ownerId: _s(data['createdBy'], _s(data['ownerId'], '')),
            createdAt: _ts(data['approvedAt'] ?? data['createdAt']),
          );
        }).toList();

        // filter
        final q = _searchCtrl.text.trim().toLowerCase();
        final loc = _locationCtrl.text.trim().toLowerCase();
        if (q.isNotEmpty) {
          jobs = jobs.where((j) => j.title.toLowerCase().contains(q)).toList();
        }
        if (loc.isNotEmpty) {
          jobs = jobs.where((j) => j.location.toLowerCase().contains(loc)).toList();
        }

        // sort
        if (_sort == 'salary_asc') {
          jobs.sort((a, b) => _salaryToNumber(a.salary).compareTo(_salaryToNumber(b.salary)));
        } else if (_sort == 'salary_desc') {
          jobs.sort((a, b) => _salaryToNumber(b.salary).compareTo(_salaryToNumber(a.salary)));
        } else if (_sort == 'oldest') {
          jobs.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        } else {
          jobs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        }

        if (jobs.isEmpty) {
          return const Center(child: Text('Không có công việc phù hợp.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: jobs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) => _jobCard(jobs[i]),
        );
      },
    );
  }

  Widget _jobCard(Job job) {
    final isFav = _favoriteJobIds.contains(job.id);

    final title = job.title.trim();
    final salary = job.salary.trim();
    final location = job.location.trim();
    final qty = job.quantity.trim();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          // ✅ Job detail của bạn đã chốt: đọc theo jobId.
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => JobDetailScreen(job: job)),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xfff7f6fb),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text('💰 $salary'),
                    const SizedBox(height: 4),
                    Text('📍 $location'),
                    if (qty.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text('👥 Số lượng: $qty'),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_isAdmin)
                    IconButton(
                      tooltip: 'Xóa công việc',
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteJob(job.id),
                    ),
                  IconButton(
                    tooltip: isFav ? 'Bỏ yêu thích' : 'Yêu thích',
                    icon: Icon(
                      isFav ? Icons.favorite : Icons.favorite_border,
                      color: isFav ? Colors.red : Colors.grey,
                    ),
                    onPressed: FirebaseAuth.instance.currentUser == null
                        ? null
                        : () async {
                            try {
                              await FavoriteJobStore.toggle(job.id);
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi yêu thích: $e')),
                              );
                            }
                          },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
