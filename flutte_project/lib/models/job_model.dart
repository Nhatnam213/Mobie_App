import 'package:cloud_firestore/cloud_firestore.dart';

class Job {
  final String id;
  final String title;
  final String salary;
  final String location;

  /// chủ job (bắt buộc)
  final String ownerId;

  /// pending / approved / rejected
  final String status;

  final Timestamp createdAt;

  // ==== Field cho chi tiết ====
  final String jobName;
  final String description;
  final String requirements;
  final String benefits;
  final String quantity;
  final String companyName;

  /// ✅ NEW: Thông tin liên hệ (email, phone)
  /// Lưu trong Firestore dạng:
  /// contact: { email: "...", phone: "..." }
  final Map<String, dynamic>? contact;

  Job({
    required this.id,
    required this.title,
    required this.salary,
    required this.location,
    required this.ownerId,
    required this.status,
    required this.createdAt,
    this.jobName = '',
    this.description = '',
    this.requirements = '',
    this.benefits = '',
    this.quantity = '',
    this.companyName = '',
    this.contact,
  });

  factory Job.fromMap(String id, Map<String, dynamic> map) {
    final rawContact = map['contact'];
    Map<String, dynamic>? contact;
    if (rawContact is Map) {
      contact = Map<String, dynamic>.from(rawContact as Map);
    }

    return Job(
      id: id,
      title: (map['title'] ?? '').toString(),
      salary: (map['salary'] ?? '').toString(),
      location: (map['location'] ?? '').toString(),

      // nếu bên created_jobs bạn lỡ lưu createdBy thì vẫn fallback
      ownerId: (map['ownerId'] ?? map['createdBy'] ?? '').toString(),

      status: (map['status'] ?? 'pending').toString(),
      createdAt: map['createdAt'] is Timestamp
          ? map['createdAt'] as Timestamp
          : Timestamp.now(),

      jobName: (map['jobName'] ?? map['title'] ?? '').toString(),
      description: (map['description'] ?? '').toString(),
      requirements: (map['requirements'] ?? '').toString(),
      benefits: (map['benefits'] ?? '').toString(),
      quantity: (map['quantity'] ?? '').toString(),
      companyName: (map['companyName'] ?? '').toString(),

      // ✅ NEW
      contact: contact,
    );
  }

  Map<String, dynamic> toMap() {
    // Nếu contact rỗng (email/phone đều trống) thì không lưu
    final email = (contact?['email'] ?? '').toString().trim();
    final phone = (contact?['phone'] ?? '').toString().trim();
    final hasContact = email.isNotEmpty || phone.isNotEmpty;

    return {
      'title': title,
      'salary': salary,
      'location': location,
      'ownerId': ownerId,
      'status': status,
      'createdAt': createdAt,
      'jobName': jobName,
      'description': description,
      'requirements': requirements,
      'benefits': benefits,
      'quantity': quantity,
      'companyName': companyName,

      // ✅ NEW
      if (hasContact)
        'contact': {
          'email': email,
          'phone': phone,
        }
      else
        'contact': null, // để merge update có thể xoá contact
    };
  }

  Job copyWith({
    String? title,
    String? salary,
    String? location,
    String? status,
    String? jobName,
    String? description,
    String? requirements,
    String? benefits,
    String? quantity,
    String? companyName,

    /// ✅ NEW: cho phép set contact hoặc set null để xoá
    Map<String, dynamic>? contact,
    bool setContactNull = false, // nếu bạn muốn ép xoá
  }) {
    return Job(
      id: id,
      title: title ?? this.title,
      salary: salary ?? this.salary,
      location: location ?? this.location,
      ownerId: ownerId,
      status: status ?? this.status,
      createdAt: createdAt,
      jobName: jobName ?? this.jobName,
      description: description ?? this.description,
      requirements: requirements ?? this.requirements,
      benefits: benefits ?? this.benefits,
      quantity: quantity ?? this.quantity,
      companyName: companyName ?? this.companyName,

      // ✅ NEW
      contact: setContactNull ? null : (contact ?? this.contact),
    );
  }
}
