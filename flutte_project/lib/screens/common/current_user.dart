import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../auth/login_screen.dart';
import '../student/home_shell.dart';
import '../admin/admin_shell.dart'; // đổi đúng tên file admin shell của bạn

class CurrentUser extends StatelessWidget {
  const CurrentUser({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnap.data;
        if (user == null) {
          return const LoginScreen();
        }

        // ✅ ĐÃ LOGIN -> đọc role từ users/{uid}
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            final data = userSnap.data?.data();
            final role = (data?['role'] ?? 'student').toString();

            if (role == 'admin') {
              return const AdminShell(); // ✅ admin
            }

            return const HomeStudentShell(); // ✅ student
          },
        );
      },
    );
  }
}
