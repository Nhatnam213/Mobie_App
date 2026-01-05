import 'package:flutter/material.dart';

import '../../models/job_model.dart';
import '../../services/created_job_store.dart';

class EditJobScreen extends StatefulWidget {
  final Job job;
  const EditJobScreen({super.key, required this.job});

  @override
  State<EditJobScreen> createState() => _EditJobScreenState();
}

class _EditJobScreenState extends State<EditJobScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _loading = false;

  late TextEditingController titleCtrl;
  late TextEditingController salaryCtrl;
  late TextEditingController locationCtrl;
  late TextEditingController companyNameCtrl;
  late TextEditingController quantityCtrl;

  late TextEditingController descriptionCtrl;
  late TextEditingController requirementsCtrl;
  late TextEditingController benefitsCtrl;

  // ✅ Contact
  late TextEditingController contactEmailCtrl;
  late TextEditingController contactPhoneCtrl;

  @override
  void initState() {
    super.initState();
    final job = widget.job;

    titleCtrl = TextEditingController(text: job.title);
    salaryCtrl = TextEditingController(text: job.salary);
    locationCtrl = TextEditingController(text: job.location);
    companyNameCtrl = TextEditingController(text: job.companyName);
    quantityCtrl = TextEditingController(text: job.quantity);

    descriptionCtrl = TextEditingController(text: job.description);
    requirementsCtrl = TextEditingController(text: job.requirements);
    benefitsCtrl = TextEditingController(text: job.benefits);

    final contact = job.contact ?? {};
    contactEmailCtrl = TextEditingController(text: (contact['email'] ?? '').toString());
    contactPhoneCtrl = TextEditingController(text: (contact['phone'] ?? '').toString());
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
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    final email = contactEmailCtrl.text.trim();
    final phone = contactPhoneCtrl.text.trim().replaceAll(RegExp(r'\s+'), '');

    final updated = widget.job.copyWith(
      title: titleCtrl.text.trim(),
      salary: salaryCtrl.text.trim(),
      location: locationCtrl.text.trim(),
      jobName: titleCtrl.text.trim(),
      companyName: companyNameCtrl.text.trim(),
      quantity: quantityCtrl.text.trim(),
      description: descriptionCtrl.text.trim(),
      requirements: requirementsCtrl.text.trim(),
      benefits: benefitsCtrl.text.trim(),
      contact: (email.isNotEmpty || phone.isNotEmpty)
          ? {
              'email': email,
              'phone': phone,
            }
          : null,
      setContactNull: (email.isEmpty && phone.isEmpty), // ✅ xoá contact trong model
    );

    await CreatedJobStore.update(updated);

    if (!mounted) return;
    setState(() => _loading = false);

    Navigator.pop(context, updated);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('✅ Đã lưu công việc')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sửa công việc')),
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
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                        decoration: _input('Tiêu đề'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập tiêu đề' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: salaryCtrl,
                        decoration: _input('Lương'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập lương' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: locationCtrl,
                        decoration: _input('Địa điểm'),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Nhập địa điểm' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: companyNameCtrl,
                        decoration: _input('Tên công ty / cửa hàng'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: quantityCtrl,
                        decoration: _input('Số lượng tuyển'),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== Chi tiết công việc =====
                Text(
                  'Chi tiết công việc',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
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
                        decoration: _input('Mô tả công việc', multiline: true),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: requirementsCtrl,
                        decoration: _input('Yêu cầu', multiline: true),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: benefitsCtrl,
                        decoration: _input('Quyền lợi', multiline: true),
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== ✅ Thông tin liên hệ (KHÔNG CHE) =====
                Text(
                  'Thông tin liên hệ',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),

                // ✅ Không bọc container riêng, hiển thị thẳng
                TextFormField(
                  controller: contactEmailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _input('Email liên hệ', hint: 'hr@company.com'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null;
                    final emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                    return emailRegex.hasMatch(s) ? null : 'Email không hợp lệ';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: contactPhoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: _input('Số điện thoại liên hệ', hint: '0xxx xxx xxx'),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null;
                    final phone = s.replaceAll(RegExp(r'\s+'), '');
                    return RegExp(r'^\d{9,12}$').hasMatch(phone) ? null : 'SĐT không hợp lệ';
                  },
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Lưu'),
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
