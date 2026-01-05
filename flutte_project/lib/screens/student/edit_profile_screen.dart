import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _schoolCtrl = TextEditingController();
  final _majorCtrl = TextEditingController();
  final _yearCtrl = TextEditingController();
  final _skillsCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController();
  final _desiredJobCtrl = TextEditingController();
  final _salaryCtrl = TextEditingController();
  final _freeTimeCtrl = TextEditingController();

  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final d = widget.userData;
    _nameCtrl.text = d['name'] ?? '';
    _phoneCtrl.text = d['phone'] ?? '';
    _schoolCtrl.text = d['school'] ?? '';
    _majorCtrl.text = d['major'] ?? '';
    _yearCtrl.text = d['year'] ?? '';
    _skillsCtrl.text = d['skills'] ?? '';
    _experienceCtrl.text = d['experience'] ?? '';
    _desiredJobCtrl.text = d['desiredJob'] ?? '';
    _salaryCtrl.text = d['expectedSalary'] ?? '';
    _freeTimeCtrl.text = d['availableTime'] ?? '';
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance.collection('users').doc(uid).set({
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      'school': _schoolCtrl.text.trim(),
      'major': _majorCtrl.text.trim(),
      'year': _yearCtrl.text.trim(),
      'skills': _skillsCtrl.text.trim(),
      'experience': _experienceCtrl.text.trim(),
      'desiredJob': _desiredJobCtrl.text.trim(),
      'expectedSalary': _salaryCtrl.text.trim(),
      'availableTime': _freeTimeCtrl.text.trim(),
    }, SetOptions(merge: true));

    if (mounted) {
      setState(() => _loading = false);
      Navigator.pop(context);
    }
  }

  Widget _field(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.grey.shade100,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _section(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.deepPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chỉnh sửa hồ sơ')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        child: Column(
          children: [
            _section('Thông tin cá nhân', Icons.person, [
              _field('Họ và tên', _nameCtrl),
              _field('Số điện thoại', _phoneCtrl),
            ]),
            _section('Học tập', Icons.school, [
              _field('Trường', _schoolCtrl),
              _field('Ngành', _majorCtrl),
              _field('Năm học', _yearCtrl),
            ]),
            _section('Kỹ năng & Kinh nghiệm', Icons.build, [
              _field('Kỹ năng', _skillsCtrl),
              _field('Kinh nghiệm', _experienceCtrl, maxLines: 2),
            ]),
            _section('Mong muốn công việc', Icons.work, [
              _field('Công việc mong muốn', _desiredJobCtrl),
              _field('Mức lương mong muốn', _salaryCtrl),
              _field('Thời gian rảnh', _freeTimeCtrl),
            ]),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _loading ? null : _save,
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _loading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Lưu hồ sơ', style: TextStyle(fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
