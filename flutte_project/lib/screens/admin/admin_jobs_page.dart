import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminJobsPage extends StatefulWidget {
  const AdminJobsPage({super.key});

  @override
  State<AdminJobsPage> createState() => _AdminJobsPageState();
}

class _AdminJobsPageState extends State<AdminJobsPage> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // pending | approved | rejected
  String _status = 'pending';
  String _search = '';
  bool _processing = false;

  CollectionReference<Map<String, dynamic>> get _createdJobs =>
      _db.collection('created_jobs');
  CollectionReference<Map<String, dynamic>> get _jobs => _db.collection('jobs');

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  String _s(dynamic v, [String fallback = '—']) {
    final t = (v as String?)?.trim();
    return (t == null || t.isEmpty) ? fallback : t;
  }

  int _i(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    return fallback;
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'approved':
        return 'Đã duyệt';
      case 'rejected':
        return 'Đã từ chối';
      default:
        return 'Chờ duyệt';
    }
  }

  Color _statusColor(String s, BuildContext context) {
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

  // ===================== ACTIONS =====================

  Future<void> _approveJob(String jobId) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) {
      _toast('Không xác định admin hiện tại.');
      return;
    }

    setState(() => _processing = true);
    try {
      await _db.runTransaction((tx) async {
        final createdRef = _createdJobs.doc(jobId);
        final snap = await tx.get(createdRef);
        if (!snap.exists) throw 'Công việc không tồn tại.';

        final data = (snap.data() as Map<String, dynamic>);
        final currentStatus = (data['status'] as String?) ?? 'pending';
        if (currentStatus == 'approved') return;

        final now = Timestamp.now();
        final jobRef = _jobs.doc(jobId);

        // ✅ FIX NHỎ: đảm bảo public job luôn status=approved
        final publicData = <String, dynamic>{
          ...data,
          'status': 'approved',
          'sourceCreatedJobId': jobId,
          'approvedAt': now,
          'approvedBy': adminUid,
        };

        tx.set(jobRef, publicData, SetOptions(merge: true));
        tx.update(createdRef, {
          'status': 'approved',
          'reviewedAt': now,
          'reviewedBy': adminUid,
          'rejectReason': FieldValue.delete(),
        });
      });

      _toast('Đã duyệt công việc.');
    } catch (e) {
      _toast('Duyệt thất bại: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _rejectJob(String jobId, String reason) async {
    final adminUid = _auth.currentUser?.uid;
    if (adminUid == null) {
      _toast('Không xác định admin hiện tại.');
      return;
    }

    final r = reason.trim();
    if (r.isEmpty) {
      _toast('Bạn phải nhập lý do từ chối.');
      return;
    }

    setState(() => _processing = true);
    try {
      await _db.runTransaction((tx) async {
        final createdRef = _createdJobs.doc(jobId);
        final jobRef = _jobs.doc(jobId);

        final snap = await tx.get(createdRef);
        if (!snap.exists) throw 'Công việc không tồn tại.';

        final data = (snap.data() as Map<String, dynamic>);
        final currentStatus = (data['status'] as String?) ?? 'pending';
        if (currentStatus == 'rejected') return;

        final now = Timestamp.now();

        // ✅ FIX QUAN TRỌNG: LUÔN xoá khỏi jobs nếu tồn tại
        final jobSnap = await tx.get(jobRef);
        if (jobSnap.exists) {
          tx.delete(jobRef);
        }

        // Update created_jobs
        tx.update(createdRef, {
          'status': 'rejected',
          'rejectReason': r,
          'reviewedAt': now,
          'reviewedBy': adminUid,
        });
      });

      _toast('Đã từ chối công việc.');
    } catch (e) {
      _toast('Từ chối thất bại: $e');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  Future<void> _openRejectDialog(String jobId) async {
    final c = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Từ chối công việc'),
        content: TextField(
          controller: c,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Nhập lý do từ chối...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Từ chối'),
          ),
        ],
      ),
    );

    if (ok == true) {
      await _rejectJob(jobId, c.text);
    }
  }

  // ===================== UI =====================

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  elevation: 0,
                  backgroundColor: cs.surface,
                  surfaceTintColor: cs.surface,
                  title: Text(
                    'Duyệt việc làm',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: Column(
                      children: [
                        _SearchPill(
                          hint: 'Tìm theo tiêu đề, công ty, địa điểm...',
                          onChanged: (v) => setState(() => _search = v),
                        ),
                        const SizedBox(height: 10),
                        _StatusTabs(
                          value: _status,
                          onChanged: (v) => setState(() => _status = v),
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _createdJobs
                      .where('status', isEqualTo: _status)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('Lỗi đọc created_jobs: ${snap.error}'),
                        ),
                      );
                    }
                    if (!snap.hasData) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(24),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      );
                    }

                    final docs = snap.data!.docs;
                    final q = _search.toLowerCase().trim();

                    final filtered = docs.where((d) {
                      if (q.isEmpty) return true;
                      final data = d.data();
                      final title = (_s(data['title'], '')).toLowerCase();
                      final company = (_s(data['company'], '')).toLowerCase();
                      final location = (_s(data['location'], '')).toLowerCase();
                      return title.contains(q) ||
                          company.contains(q) ||
                          location.contains(q);
                    }).toList();

                    if (filtered.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                          child: _EmptyState(
                            text: _search.trim().isEmpty
                                ? 'Không có công việc trong mục này.'
                                : 'Không có kết quả phù hợp.',
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final doc = filtered[index];
                          final data = doc.data();

                          final title = _s(data['title']);
                          final company = _s(data['company']);
                          final location = _s(data['location']);
                          final quantity = _i(data['quantity'], 0);
                          final status =
                              (data['status'] as String?) ?? 'pending';

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _JobCard(
                              title: title,
                              company: company,
                              location: location,
                              quantity: quantity,
                              statusLabel: _statusLabel(status),
                              statusColor: _statusColor(status, context),
                              onTap: () => _openJobDetailSheet(
                                jobId: doc.id,
                                data: data,
                              ),
                            ),
                          );
                        }, childCount: filtered.length),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        if (_processing)
          Positioned.fill(
            child: AbsorbPointer(
              child: Container(
                color: Colors.black.withOpacity(0.18),
                child: const Center(child: CircularProgressIndicator()),
              ),
            ),
          ),
      ],
    );
  }

  void _openJobDetailSheet({
    required String jobId,
    required Map<String, dynamic> data,
  }) {
    final cs = Theme.of(context).colorScheme;

    final title = _s(data['title']);
    final company = _s(data['company']);
    final location = _s(data['location']);
    final salary = _s(data['salary']);
    final quantity = _i(data['quantity'], 0);
    final description = _s(data['description'], '—');
    final status = (data['status'] as String?) ?? 'pending';
    final rejectReason = _s(data['rejectReason'], '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            16,
            8,
            16,
            16 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Pill(text: company, icon: Icons.business),
                    _Pill(text: location, icon: Icons.location_on),
                    _Pill(text: 'Số lượng: $quantity', icon: Icons.group),
                    if (salary != '—')
                      _Pill(text: 'Lương: $salary', icon: Icons.payments),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest.withOpacity(0.55),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: cs.outlineVariant.withOpacity(0.35),
                    ),
                  ),
                  child: Text(
                    description,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (status == 'rejected' && rejectReason.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.errorContainer.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.error.withOpacity(0.35)),
                    ),
                    child: Text(
                      'Lý do từ chối: $rejectReason',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                if (status == 'pending' || status == 'approved') ...[
                  if (status == 'pending') ...[
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.close),
                            label: const Text('Từ chối'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _openRejectDialog(jobId);
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            icon: const Icon(Icons.check),
                            label: const Text('Duyệt'),
                            onPressed: () async {
                              Navigator.pop(context);
                              await _approveJob(jobId);
                            },
                          ),
                        ),
                      ],
                    ),
                  ] else if (status == 'approved') ...[
                    Center(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.undo),
                        label: const Text('Thu hồi duyệt'),
                        onPressed: () async {
                          Navigator.pop(context);
                          await _rejectJob(jobId, 'Thu hồi duyệt bởi admin');
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Text(
                    status == 'pending'
                        ? 'Chỉ job ở trạng thái "Chờ duyệt" mới có thể duyệt/từ chối.'
                        : 'Job đã duyệt có thể thu hồi.',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ] else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHighest.withOpacity(0.45),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: cs.outlineVariant.withOpacity(0.35),
                      ),
                    ),
                    child: Text(
                      'Trạng thái hiện tại: ${_statusLabel(status)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                ],
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ===================== Widgets =====================

class _SearchPill extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const _SearchPill({required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.60),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: const Icon(Icons.search),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _StatusTabs extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const _StatusTabs({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'pending',
          label: Text('Chờ duyệt'),
          icon: Icon(Icons.hourglass_top),
        ),
        ButtonSegment(
          value: 'approved',
          label: Text('Đã duyệt'),
          icon: Icon(Icons.check_circle),
        ),
        ButtonSegment(
          value: 'rejected',
          label: Text('Đã từ chối'),
          icon: Icon(Icons.cancel),
        ),
      ],
      selected: {value},
      onSelectionChanged: (s) => onChanged(s.first),
    );
  }
}

class _JobCard extends StatelessWidget {
  final String title;
  final String company;
  final String location;
  final int quantity;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _JobCard({
    required this.title,
    required this.company,
    required this.location,
    required this.quantity,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Material(
      color: cs.surfaceContainerHighest.withOpacity(0.35),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$company • $location • SL: $quantity',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: statusColor.withOpacity(0.35)),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String text;
  final IconData icon;

  const _Pill({required this.text, required this.icon});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: cs.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String text;
  const _EmptyState({required this.text});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.inbox_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
