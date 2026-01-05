import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../services/csv_downloader.dart';

class AdminCsvPage extends StatefulWidget {
  const AdminCsvPage({super.key});

  @override
  State<AdminCsvPage> createState() => _AdminCsvPageState();
}

class _AdminCsvPageState extends State<AdminCsvPage> {
  final _db = FirebaseFirestore.instance;

  bool _loading = false;
  bool _loadingStats = false;

  String _mode = 'applied_detail';
  final _modes = const <String>[
    'applied_detail', // ✅ chi tiết nhất
    'Ứng tuyển',
    'created_jobs',
    'jobs',
    'users',
    'favorite_jobs',
  ];

  Map<String, int> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  // ================== LOGIC GIỮ NGUYÊN ==================
  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);
    try {
      final futures = await Future.wait([
        _db.collection('jobs').get(),
        _db.collection('created_jobs').get(),
        _db.collection('applied_jobs').get(),
        _db.collection('users').get(),
      ]);

      final jobsSnap = futures[0] as QuerySnapshot<Map<String, dynamic>>;
      final createdSnap = futures[1] as QuerySnapshot<Map<String, dynamic>>;
      final appliedSnap = futures[2] as QuerySnapshot<Map<String, dynamic>>;
      final usersSnap = futures[3] as QuerySnapshot<Map<String, dynamic>>;

      int createdPending = 0, createdApproved = 0, createdRejected = 0;
      for (final d in createdSnap.docs) {
        final s = (d.data()['status'] ?? 'pending').toString();
        if (s == 'approved') createdApproved++;
        else if (s == 'rejected') createdRejected++;
        else createdPending++;
      }

      int appliedPending = 0, appliedApproved = 0, appliedRejected = 0;
      for (final d in appliedSnap.docs) {
        // bạn đang dùng 'applied' => coi như pending
        final raw = (d.data()['status'] ?? 'applied').toString();
        final s = (raw == 'applied') ? 'pending' : raw;
        if (s == 'approved') appliedApproved++;
        else if (s == 'rejected') appliedRejected++;
        else appliedPending++;
      }

      setState(() {
        _stats = {
          'jobs_total': jobsSnap.size,
          'created_total': createdSnap.size,
          'created_pending': createdPending,
          'created_approved': createdApproved,
          'created_rejected': createdRejected,
          'applied_total': appliedSnap.size,
          'applied_pending': appliedPending,
          'applied_approved': appliedApproved,
          'applied_rejected': appliedRejected,
          'users_total': usersSnap.size,
        };
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi load thống kê: $e')),
      );
    } finally {
      if (mounted) setState(() => _loadingStats = false);
    }
  }

  Future<void> _exportCsv() async {
    setState(() => _loading = true);
    try {
      if (_mode == 'applied_detail') {
        await _exportAppliedDetail();
      } else {
        await _exportCollectionRaw(_mode);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi xuất CSV: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _exportCollectionRaw(String col) async {
    final snap = await _db.collection(col).get();

    if (snap.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có dữ liệu để xuất')),
      );
      return;
    }

    final allKeys = <String>{'docId'};
    for (final d in snap.docs) {
      allKeys.addAll(d.data().keys);
    }
    final headers = allKeys.toList();

    final rows = <List<String>>[];
    rows.add(headers);

    for (final d in snap.docs) {
      final data = d.data();
      final row = <String>[];
      for (final k in headers) {
        dynamic v;
        if (k == 'docId') v = d.id;
        else v = data[k];
        row.add(_toCsvCell(v));
      }
      rows.add(row);
    }

    final csv = const _Csv().convert(rows);
    downloadCsv(csv, '${col}_${DateTime.now().millisecondsSinceEpoch}.csv');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo CSV, đang tải xuống...')),
    );
  }

  /// ✅ Applied Jobs (CHI TIẾT): join users + jobs
  Future<void> _exportAppliedDetail() async {
    final appliedSnap = await _db.collection('applied_jobs').get();

    if (appliedSnap.docs.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không có Ứng tuyển để xuất')),
      );
      return;
    }

    final appliedDocs = appliedSnap.docs;
    final userIds = appliedDocs
        .map((d) => (d.data()['userId'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();
    final jobIds = appliedDocs
        .map((d) => (d.data()['jobId'] ?? '').toString())
        .where((e) => e.isNotEmpty)
        .toSet()
        .toList();

    final usersMap = await _batchGetByDocId('users', userIds);
    final jobsMap = await _batchGetByDocId('jobs', jobIds);

    // headers chi tiết nhất
    final headers = <String>[
      'appliedDocId',
      'jobId',
      'jobTitle',
      'jobLocation',
      'jobSalary',
      'jobOwnerId',
      'userId',
      'userName',
      'userEmail',
      'userPhone',
      'status',
      'createdAt',
    ];

    final rows = <List<String>>[];
    rows.add(headers);

    for (final d in appliedDocs) {
      final data = d.data();

      final jobId = (data['jobId'] ?? '').toString();
      final userId = (data['userId'] ?? '').toString();

      final job = jobsMap[jobId] ?? <String, dynamic>{};
      final user = usersMap[userId] ?? <String, dynamic>{};

      // status: applied => pending
      final rawStatus = (data['status'] ?? 'applied').toString();
      final status = (rawStatus == 'applied') ? 'pending' : rawStatus;

      final row = <String>[
        d.id,
        jobId,
        (job['title'] ?? data['jobTitle'] ?? '').toString(),
        (job['location'] ?? data['location'] ?? '').toString(),
        (job['salary'] ?? data['salary'] ?? '').toString(),
        (job['ownerId'] ?? data['ownerId'] ?? '').toString(),
        userId,
        (user['name'] ?? user['fullName'] ?? user['displayName'] ?? '').toString(),
        (user['email'] ?? '').toString(),
        (user['phone'] ?? user['phoneNumber'] ?? '').toString(),
        status,
        _toCsvCell(data['createdAt'] ?? data['appliedAt']),
      ];

      rows.add(row.map(_toCsvCell).toList());
    }

    final csv = const _Csv().convert(rows);
    downloadCsv(csv, 'applied_jobs_detail_${DateTime.now().millisecondsSinceEpoch}.csv');

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã tạo CSV chi tiết, đang tải xuống...')),
    );
  }

  Future<Map<String, Map<String, dynamic>>> _batchGetByDocId(
    String col,
    List<String> ids,
  ) async {
    final result = <String, Map<String, dynamic>>{};
    if (ids.isEmpty) return result;

    // Firestore whereIn tối đa 10
    for (int i = 0; i < ids.length; i += 10) {
      final chunk = ids.sublist(i, (i + 10 > ids.length) ? ids.length : i + 10);

      final snap = await _db
          .collection(col)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final d in snap.docs) {
        result[d.id] = d.data();
      }
    }
    return result;
  }

  String _toCsvCell(dynamic v) {
    if (v == null) return '';
    if (v is Timestamp) return v.toDate().toIso8601String();
    if (v is DateTime) return v.toIso8601String();
    if (v is Map || v is List) return jsonEncode(v);
    return v.toString();
  }

  // ================== UI HELPERS (UI-ONLY) ==================
  int _stat(String key) => _stats[key] ?? 0;

  String _modeLabel(String mode) {
    if (mode == 'applied_detail') return 'Ứng tuyển (CHI TIẾT: join users + jobs)';
    return mode;
  }

  Widget _sectionTitle(String text) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required int value,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12), // spacing 12
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Icon(icon, color: cs.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value.toString(),
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w900,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required Widget child,
  }) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }

  // ================== BUILD ==================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo & Xuất dữ liệu'),
        actions: [
          IconButton(
            tooltip: 'Refresh thống kê',
            onPressed: _loadingStats ? null : _loadStats,
            icon: _loadingStats
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 980), // responsive web
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              // ===== Stats =====
              Row(
                children: [
                  Expanded(child: _sectionTitle('Thống kê nhanh')),
                  TextButton.icon(
                    onPressed: _loadingStats ? null : _loadStats,
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Làm mới'),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              _panel(
                child: LayoutBuilder(
                  builder: (context, c) {
                    // 1 cột ở mobile, 2 ở tablet, 3 ở web
                    final w = c.maxWidth;
                    final crossAxisCount = w >= 900 ? 3 : (w >= 560 ? 2 : 1);
                    final itemWidth = (w - (crossAxisCount - 1) * 12) / crossAxisCount;

                    final items = <Widget>[
                      _statCard(icon: Icons.work_outline, label: 'Jobs', value: _stat('jobs_total')),
                      _statCard(icon: Icons.inventory_2_outlined, label: 'Created', value: _stat('created_total')),
                      _statCard(icon: Icons.hourglass_bottom, label: 'Created Pending', value: _stat('created_pending')),
                      _statCard(icon: Icons.check_circle_outline, label: 'Created Approved', value: _stat('created_approved')),
                      _statCard(icon: Icons.cancel_outlined, label: 'Created Rejected', value: _stat('created_rejected')),
                      _statCard(icon: Icons.how_to_reg_outlined, label: 'Applied', value: _stat('applied_total')),
                      _statCard(icon: Icons.schedule_outlined, label: 'Applied Pending', value: _stat('applied_pending')),
                      _statCard(icon: Icons.verified_outlined, label: 'Applied Approved', value: _stat('applied_approved')),
                      _statCard(icon: Icons.block_outlined, label: 'Applied Rejected', value: _stat('applied_rejected')),
                      _statCard(icon: Icons.people_outline, label: 'Users', value: _stat('users_total')),
                    ];

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: items
                          .map((e) => SizedBox(width: itemWidth, child: e))
                          .toList(),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ===== Export =====
              _sectionTitle('Xuất dữ liệu'),
              const SizedBox(height: 12),

              _panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Loại dữ liệu',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),

                    DropdownButtonFormField<String>(
                      value: _mode,
                      items: _modes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e,
                              child: Text(_modeLabel(e)),
                            ),
                          )
                          .toList(),
                      onChanged: _loading ? null : (v) => setState(() => _mode = v!),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: cs.surfaceContainerHighest,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: cs.primary, width: 1.2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    SizedBox(
                      height: 48,
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: _loading ? null : _exportCsv,
                        icon: _loading
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.download_rounded),
                        label: Text(_loading ? 'Đang xuất…' : 'Xuất file'),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, size: 18, color: cs.onSurfaceVariant),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Gợi ý: chọn "Ứng tuyển (CHI TIẾT)" để có đầy đủ job + user + status.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CSV converter đơn giản (không cần package)
class _Csv {
  const _Csv();

  String convert(List<List<String>> rows) {
    return rows.map(_row).join('\n');
  }

  String _row(List<String> row) => row.map(_escape).join(',');

  String _escape(String value) {
    final v = value.replaceAll('"', '""');
    final mustQuote = v.contains(',') || v.contains('\n') || v.contains('\r');
    return mustQuote ? '"$v"' : v;
  }
}
