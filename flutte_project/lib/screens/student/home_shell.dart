import 'package:flutter/material.dart';

import 'home_tab.dart';
import 'my_jobs_screen.dart';
import 'favorite_jobs_screen.dart';
import 'profile_tab.dart';
import 'create_job_screen.dart';

class HomeStudentShell extends StatefulWidget {
  final int initialIndex;

  /// Nếu true: ẩn nút + (tạo job).
  /// Dùng cho admin vào xem/xóa job ở HomeTab.
  final bool hideFab;

  const HomeStudentShell({
    super.key,
    this.initialIndex = 0,
    this.hideFab = false,
  });

  @override
  State<HomeStudentShell> createState() => _HomeStudentShellState();
}

class _HomeStudentShellState extends State<HomeStudentShell> {
  late int _index;

  // ✅ giữ state tabs
  late final List<Widget> _tabs;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, 3);
    _tabs = [
      const HomeTab(),
      const MyJobsScreen(),
      const FavoriteJobsScreen(),
      const ProfileTab(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_index],
      floatingActionButton: (widget.hideFab || _index != 0)
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateJobScreen()),
                );
              },
              child: const Icon(Icons.add),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
          BottomNavigationBarItem(icon: Icon(Icons.work), label: 'Việc của tôi'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Yêu thích'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Hồ sơ'),
        ],
      ),
    );
  }
}
