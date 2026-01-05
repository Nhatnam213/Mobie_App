import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final passCtrl = TextEditingController();

  Future<void> _change() async {
    final pass = passCtrl.text.trim();

    if (pass.length < 6) {
      _show('Mật khẩu phải từ 6 ký tự');
      return;
    }

    await FirebaseAuth.instance.currentUser!.updatePassword(pass);
    _show('Đổi mật khẩu thành công');
  }

  void _show(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đổi mật khẩu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: passCtrl,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
              obscureText: true,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _change,
              child: const Text('Xác nhận'),
            )
          ],
        ),
      ),
    );
  }
}
