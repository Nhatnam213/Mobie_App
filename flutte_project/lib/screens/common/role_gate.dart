import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RoleGate extends StatefulWidget {
  final Widget loginScreen;
  final Widget userHome;
  final Widget adminHome;

  const RoleGate({
    super.key,
    required this.loginScreen,
    required this.userHome,
    required this.adminHome,
  });

  @override
  State<RoleGate> createState() => _RoleGateState();
}

class _RoleGateState extends State<RoleGate> {
  bool _navigated = false;

  Future<String> _loadRole(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (doc.data()?['role'] as String?) ?? 'user';
    }

  @override
  Widget build(BuildContext context) {
    // Chỉ hiển thị loading trong lúc quyết định route
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnap) {
        if (authSnap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = authSnap.data;

        // Chưa login -> reset trạng thái và về login screen
        if (user == null) {
          _navigated = false;
          return widget.loginScreen;
        }

        return FutureBuilder<String>(
          future: _loadRole(user.uid),
          builder: (context, roleSnap) {
            if (roleSnap.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final role = roleSnap.data ?? 'user';

            // ✅ ÉP ĐIỀU HƯỚNG 1 LẦN DUY NHẤT
            if (!_navigated) {
              _navigated = true;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                final target = (role == 'admin') ? widget.adminHome : widget.userHome;

                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => target),
                );
              });
            }

            // Trong lúc đợi frame điều hướng, show loading
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          },
        );
      },
    );
  }
}
