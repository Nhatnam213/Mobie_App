import 'package:flutter/material.dart';

import 'admin_users_page.dart';
import 'admin_jobs_page.dart';
import 'admin_applied_jobs_page.dart';
import 'admin_csv_page.dart'; // ✅ thêm: page CSV thật
import 'admin_system_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _index = 0;

  late final List<Widget> _pages = const [
    AdminUsersPage(),
    AdminJobsPage(),
    AdminAppliedJobsPage(),
    AdminCsvPage(), // ✅ FIX: thay placeholder bằng page CSV thật
    AdminSystemPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_index],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.people_alt_rounded),
            label: 'Users',
          ),
          NavigationDestination(
            icon: Icon(Icons.work_rounded),
            label: 'Việc làm',
          ),
          NavigationDestination(
            icon: Icon(Icons.how_to_reg_rounded),
            label: 'Ứng tuyển',
          ),
          NavigationDestination(
            icon: Icon(Icons.download_rounded),
            label: 'CSV',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_rounded),
            label: 'Hệ thống',
          ),
        ],
      ),
    );
  }
}
