import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateJobScreen extends StatefulWidget {
  const CreateJobScreen({super.key});

  @override
  State<CreateJobScreen> createState() => _CreateJobScreenState();
}

class _CreateJobScreenState extends State<CreateJobScreen> {
  final _formKey = GlobalKey<FormState>();

  final titleCtrl = TextEditingController();
  final salaryCtrl = TextEditingController();
  final locationCtrl = TextEditingController();

  final companyNameCtrl = TextEditingController();
  final quantityCtrl = TextEditingController();

  final descriptionCtrl = TextEditingController();
  final requirementsCtrl = TextEditingController();
  final benefitsCtrl = TextEditingController();

  // ✅ NEW: Thông tin liên hệ
  final contactEmailCtrl = TextEditingController();
  final contactPhoneCtrl = TextEditingController();

  bool _loading = false;

  int _parseQuantity(String input) {
    final match = RegExp(r'\d+').firstMatch(input);
    if (match == null) return 0;
    return int.tryParse(match.group(0) ?? '') ?? 0;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bạn cần đăng nhập trước')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final docRef =
          FirebaseFirestore.instance.collection('created_jobs').doc();
      final jobId = docRef.id;

      final title = titleCtrl.text.trim();
      final salary = salaryCtrl.text.trim();
      final location = locationCtrl.text.trim();
      final companyName = companyNameCtrl.text.trim();
      final quantity = _parseQuantity(quantityCtrl.text.trim());

      final description = descriptionCtrl.text.trim();
      final requirements = requirementsCtrl.text.trim();
      final benefits = benefitsCtrl.text.trim();

      // ✅ NEW: contact
      final email = contactEmailCtrl.text.trim();
      final phone =
          contactPhoneCtrl.text.trim().replaceAll(RegExp(r'\s+'), '');

      final hasContact = email.isNotEmpty || phone.isNotEmpty;

      await docRef.set({
        'id': jobId,
        'title': title,
        'jobName': title,
        'salary': salary,
        'location': location,
        'companyName': companyName,
        'quantity': quantity,
        'description': description,
        'requirements': requirements,
        'benefits': benefits,

        // ✅ NEW
        if (hasContact)
          'contact': {
            'email': email,
            'phone': phone,
          },

        // quyền sở hữu
        'createdBy': user.uid,

        // trạng thái duyệt
        'status': 'pending',

        // thời gian tạo
        'createdAt': FieldValue.serverTimestamp(),

        // email người tạo (admin xem nhanh)
        'creatorEmail': user.email,
      });

      if (!mounted) return;
      setState(() => _loading = false);
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Đăng việc thành công (chờ duyệt)')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Đăng việc thất bại: $e')),
      );
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    salaryCtrl.dispose();
    locationCtrl.dispose();
    companyNameCtrl.dispose();
    quantityCtrl.dispose();
    descriptionCtrl.dispose();
    requirementsCtrl.dispose();
    benefitsCtrl.dispose();

    // ✅ NEW
    contactEmailCtrl.dispose();
    contactPhoneCtrl.dispose();

    super.dispose();
  }

  InputDecoration _input(String label, {String? hint, bool multiline = false}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      alignLabelWithHint: multiline,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide:
            BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tạo công việc')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ===== Thông tin cơ bản =====
                Text(
                  'Thông tin cơ bản',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: titleCtrl,
                        decoration: _input(
                          'Tiêu đề',
                          hint: 'VD: Nhân viên nhập liệu',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Nhập tiêu đề' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: salaryCtrl,
                        decoration: _input(
                          'Lương',
                          hint: 'VD: 6.000.000đ / tháng',
                        ),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Nhập lương' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationCtrl,
                        decoration: _input(
                          'Địa điểm',
                          hint: 'VD: Tân Bình',
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Nhập địa điểm'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: companyNameCtrl,
                        decoration: _input(
                          'Tên công ty / cửa hàng',
                          hint: 'VD: Công ty TNHH ABC',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityCtrl,
                        decoration: _input(
                          'Số lượng tuyển',
                          hint: 'VD: 3 (hoặc 3 người)',
                        ),
                        keyboardType: TextInputType.number,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Chi tiết công việc =====
                Text(
                  'Chi tiết công việc (không bắt buộc nhưng nên có)',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: descriptionCtrl,
                        decoration: _input(
                          'Mô tả công việc',
                          hint: 'Nhập dữ liệu, kiểm tra thông tin, ...',
                          multiline: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: requirementsCtrl,
                        decoration: _input(
                          'Yêu cầu',
                          hint:
                              'VD: Sinh viên năm 1-3, biết Excel cơ bản, ...',
                          multiline: true,
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: benefitsCtrl,
                        decoration: _input(
                          'Quyền lợi',
                          hint: 'Thưởng lễ tết, linh hoạt ca làm, ...',
                          multiline: true,
                        ),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Thông tin liên hệ (NEW) =====
                Text(
                  'Thông tin liên hệ',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        color: Colors.black.withOpacity(0.04),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      TextFormField(
                        controller: contactEmailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _input(
                          'Email liên hệ',
                          hint: 'hr@company.com',
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return null;
                          final emailRegex =
                              RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                          return emailRegex.hasMatch(s)
                              ? null
                              : 'Email không hợp lệ';
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: _input(
                          'Số điện thoại liên hệ',
                          hint: '0xxx xxx xxx',
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return null;
                          final phone =
                              s.replaceAll(RegExp(r'\s+'), '');
                          return RegExp(r'^\d{9,12}$').hasMatch(phone)
                              ? null
                              : 'SĐT không hợp lệ';
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                    onPressed: _loading ? null : _save,
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Đăng việc'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
