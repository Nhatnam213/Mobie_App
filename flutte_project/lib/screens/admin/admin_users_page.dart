import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final _usersRef = FirebaseFirestore.instance.collection('users');
  final _auth = FirebaseAuth.instance;

  String _search = '';
  bool _updatingRole = false;

  // ---------- Data helpers ----------
  String _pickDisplayName(Map<String, dynamic> data) {
    final name = (data['name'] as String?)?.trim();
    final email = (data['email'] as String?)?.trim();
    if (name != null && name.isNotEmpty) return name;
    if (email != null && email.isNotEmpty) return email;
    return '(Không có tên)';
  }

  String _pickEmail(Map<String, dynamic> data) {
    final email = (data['email'] as String?)?.trim();
    return (email != null && email.isNotEmpty) ? email : '—';
  }

  String _pickRole(Map<String, dynamic> data) {
    final role = (data['role'] as String?)?.trim().toLowerCase();
    return (role == 'admin') ? 'admin' : 'user';
  }

  String _makeInitials(String text) {
    final t = text.trim();
    if (t.isEmpty) return '?';
    final parts = t.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.take(1).toString().toUpperCase();
    final first = parts.first.characters.take(1).toString().toUpperCase();
    final last = parts.last.characters.take(1).toString().toUpperCase();
    return '$first$last';
  }

  // ---------- UI helpers ----------
  Color _roleAccent(String role, BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return role == 'admin' ? cs.primary : cs.tertiary;
  }

  IconData _roleIcon(String role) => role == 'admin' ? Icons.verified_user : Icons.school;

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<bool> _confirmChangeRole({
    required String displayName,
    required String fromRole,
    required String toRole,
  }) async {
    return (await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Xác nhận đổi role'),
            content: Text('Đổi role của "$displayName"\n$fromRole  →  $toRole ?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Huỷ')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Đổi')),
            ],
          ),
        )) ??
        false;
  }

  // ---------- Role change (safe) ----------
  Future<void> _changeRole({
    required String targetUid,
    required String targetRoleCurrent,
    required String newRole,
  }) async {
    final myUid = _auth.currentUser?.uid;

    if (myUid == null) {
      _toast('Không xác định được tài khoản admin hiện tại.');
      return;
    }

    if (targetUid == myUid) {
      _toast('Không thể đổi role của chính bạn.');
      return;
    }

    if (newRole == targetRoleCurrent) return;

    setState(() => _updatingRole = true);

    try {
      await FirebaseFirestore.instance.runTransaction((tx) async {
        final targetRef = _usersRef.doc(targetUid);
        final targetSnap = await tx.get(targetRef);

        if (!targetSnap.exists) throw 'User không tồn tại.';

        final data = (targetSnap.data() as Map<String, dynamic>);
        final currentRole = _pickRole(data);

        if (currentRole == 'admin' && newRole == 'user') {
          final adminsSnap = await _usersRef.where('role', isEqualTo: 'admin').get();
          if (adminsSnap.size <= 1) throw 'Không thể hạ admin cuối cùng.';
        }

        tx.update(targetRef, {'role': newRole});
      });

      _toast('Đã đổi role → $newRole');
    } catch (e) {
      _toast('Đổi role thất bại: $e');
    } finally {
      if (mounted) setState(() => _updatingRole = false);
    }
  }

  // ---------- Bottom sheet ----------
  void _showUserDetailSheet({
    required BuildContext context,
    required String uid,
    required Map<String, dynamic> data,
    required String displayName,
    required String email,
    required String role,
  }) {
    final cs = Theme.of(context).colorScheme;
    final accent = _roleAccent(role, context);
    final isAdmin = role == 'admin';
    final nextRole = isAdmin ? 'user' : 'admin';

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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  _GradientAvatar(
                    initials: _makeInitials(displayName),
                    accent: accent,
                    size: 48,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _RolePill(role: role, accent: accent),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                email,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: cs.onSurfaceVariant,
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

              const SizedBox(height: 14),
              _InfoCard(
                rows: [
                  _InfoRow(icon: Icons.alternate_email, label: 'Email', value: email),
                  _InfoRow(icon: Icons.badge, label: 'Role', value: role),
                  _InfoRow(icon: Icons.fingerprint, label: 'UID', value: uid),
                ],
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.admin_panel_settings),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  label: Text('Đổi role: $role → $nextRole'),
                  onPressed: () async {
                    final ok = await _confirmChangeRole(
                      displayName: displayName,
                      fromRole: role,
                      toRole: nextRole,
                    );
                    if (!ok) return;

                    if (context.mounted) Navigator.pop(context);
                    await _changeRole(
                      targetUid: uid,
                      targetRoleCurrent: role,
                      newRole: nextRole,
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withOpacity(0.55),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
                ),
                child: Text(
                  'Lưu ý: Không cho đổi role của chính bạn và không cho hạ admin cuối cùng.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Scaffold(
          backgroundColor: cs.surface,
          body: SafeArea(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _usersRef.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _ErrorState(message: 'Lỗi đọc users: ${snapshot.error}');
                }
                if (!snapshot.hasData) return const _LoadingState();

                final docs = snapshot.data!.docs;

                // Stats
                final total = docs.length;
                int admins = 0;
                int students = 0;
                for (final d in docs) {
                  final role = _pickRole(d.data());
                  if (role == 'admin') {
                    admins++;
                  } else {
                    students++;
                  }
                }

                // Filter search (client-side)
                final q = _search.toLowerCase().trim();
                final filtered = docs.where((d) {
                  if (q.isEmpty) return true;
                  final data = d.data();
                  final name = (data['name'] as String?)?.toLowerCase() ?? '';
                  final email = (data['email'] as String?)?.toLowerCase() ?? '';
                  final role = (data['role'] as String?)?.toLowerCase() ?? '';
                  return name.contains(q) || email.contains(q) || role.contains(q);
                }).toList();

                return CustomScrollView(
                  slivers: [
                    // ✅ AppBar chỉ giữ title (KHÔNG nhét bottom PreferredSize nữa)
                    SliverAppBar(
                      pinned: true,
                      elevation: 0,
                      backgroundColor: cs.surface,
                      surfaceTintColor: cs.surface,
                      titleSpacing: 16,
                      title: Row(
                        children: [
                          Icon(Icons.admin_panel_settings, color: cs.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Quản lý người dùng',
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                        ],
                      ),
                    ),

                    // ✅ Search + Stats ra ngoài AppBar => tự co giãn, hết overflow
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                        child: Column(
                          children: [
                            _SearchPill(
                              hint: 'Tìm theo tên, email hoặc role...',
                              onChanged: (v) => setState(() => _search = v),
                            ),
                            const SizedBox(height: 10),
                            _StatsRowPretty(
                              total: total,
                              admins: admins,
                              students: students,
                            ),
                          ],
                        ),
                      ),
                    ),

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Danh sách (${filtered.length})',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.surfaceContainerHighest.withOpacity(0.55),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
                              ),
                              child: Text(
                                q.isEmpty ? 'Tất cả' : 'Đang lọc',
                                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (filtered.isEmpty)
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                          child: _EmptyState(),
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final doc = filtered[index];
                              final data = doc.data();

                              final displayName = _pickDisplayName(data); // ✅ name ưu tiên
                              final email = _pickEmail(data);
                              final role = _pickRole(data);

                              final accent = _roleAccent(role, context);
                              final initials = _makeInitials(displayName);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _UserCard(
                                  displayName: displayName,
                                  email: email,
                                  role: role,
                                  initials: initials,
                                  accent: accent,
                                  roleIcon: _roleIcon(role),
                                  onTap: () => _showUserDetailSheet(
                                    context: context,
                                    uid: doc.id,
                                    data: data,
                                    displayName: displayName,
                                    email: email,
                                    role: role,
                                  ),
                                ),
                              );
                            },
                            childCount: filtered.length,
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),

        if (_updatingRole)
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
}

// ===================== Pretty widgets =====================

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
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
    );
  }
}

class _StatsRowPretty extends StatelessWidget {
  final int total;
  final int admins;
  final int students;

  const _StatsRowPretty({
    required this.total,
    required this.admins,
    required this.students,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCardPretty(
            title: 'Tổng users',
            value: '$total',
            icon: Icons.groups_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCardPretty(
            title: 'Admin',
            value: '$admins',
            icon: Icons.verified_user_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCardPretty(
            title: 'Sinh viên',
            value: '$students',
            icon: Icons.school_rounded,
          ),
        ),
      ],
    );
  }
}

class _StatCardPretty extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _StatCardPretty({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cs.surfaceContainerHighest.withOpacity(0.75),
            cs.surfaceContainerHighest.withOpacity(0.45),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: Colors.black.withOpacity(0.06),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: cs.surface.withOpacity(0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
            ),
            child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final String displayName;
  final String email;
  final String role;
  final String initials;
  final Color accent;
  final IconData roleIcon;
  final VoidCallback onTap;

  const _UserCard({
    required this.displayName,
    required this.email,
    required this.role,
    required this.initials,
    required this.accent,
    required this.roleIcon,
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
              _GradientAvatar(initials: initials, accent: accent, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
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
              _RoleChipFancy(role: role, accent: accent, icon: roleIcon),
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded, color: cs.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final String initials;
  final Color accent;
  final double size;

  const _GradientAvatar({
    required this.initials,
    required this.accent,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            accent.withOpacity(0.90),
            accent.withOpacity(0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size / 2),
        boxShadow: [
          BoxShadow(
            blurRadius: 14,
            offset: const Offset(0, 8),
            color: accent.withOpacity(0.18),
          ),
        ],
        border: Border.all(color: cs.surface.withOpacity(0.45), width: 1),
      ),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: cs.onPrimary,
          ),
        ),
      ),
    );
  }
}

class _RoleChipFancy extends StatelessWidget {
  final String role;
  final Color accent;
  final IconData icon;

  const _RoleChipFancy({
    required this.role,
    required this.accent,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: accent),
          const SizedBox(width: 6),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String role;
  final Color accent;

  const _RolePill({required this.role, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withOpacity(0.35)),
      ),
      child: Text(
        role,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w900,
          color: accent,
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<_InfoRow> rows;

  const _InfoCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i != rows.length - 1) const Divider(height: 16),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: cs.surface.withOpacity(0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.35)),
          ),
          child: Icon(icon, size: 18, color: cs.onSurfaceVariant),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          flex: 2,
          child: Text(
            value,
            textAlign: TextAlign.right,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
        ),
      ],
    );
  }
}

// ===================== States =====================

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) => const Center(child: CircularProgressIndicator());
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

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
          Icon(Icons.person_off_rounded, color: cs.onSurfaceVariant),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Không có user phù hợp với từ khóa tìm kiếm.',
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
