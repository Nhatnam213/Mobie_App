import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'edit_profile_screen.dart';
import '../../screens/auth/login_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Center(child: Text('Chưa đăng nhập'));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Hồ sơ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              }
            },
          )
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Không tìm thấy dữ liệu hồ sơ'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ===== AVATAR =====
                CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.deepPurple,
                  child: Text(
                    (data['name'] ?? 'U')
                        .toString()
                        .substring(0, 1)
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                Text(
                  data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  data['email'] ?? '',
                  style: const TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EditProfileScreen(
                          userData: data, // ✅ FIX LỖI Ở ĐÂY
                        ),
                      ),
                    );
                  },
                  child: const Text('Chỉnh sửa hồ sơ'),
                ),

                const SizedBox(height: 24),

                _infoCard(
                  title: 'Thông tin cá nhân',
                  items: {
                    'Số điện thoại': data['phone'] ?? 'Chưa cập nhật',
                  },
                ),

                _infoCard(
                  title: 'Thông tin học tập',
                  items: {
                    'Trường': data['school'] ?? '',
                    'Ngành': data['major'] ?? '',
                    'Năm học': data['year'] ?? '',
                  },
                ),

                _infoCard(
                  title: 'Kỹ năng & kinh nghiệm',
                  items: {
                    'Kỹ năng': data['skills'] ?? '',
                    'Kinh nghiệm': data['experience'] ?? '',
                  },
                ),

                _infoCard(
                  title: 'Công việc mong muốn',
                  items: {
                    'Vị trí': data['desiredJob'] ?? '',
                    'Mức lương': data['expectedSalary'] ?? '',
                    'Thời gian rảnh': data['availableTime'] ?? '',
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required Map<String, String> items,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const Divider(),
          ...items.entries.map(
            (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      e.key,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 5,
                    child: Text(e.value),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
