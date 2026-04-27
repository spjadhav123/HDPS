// lib/core/models/teacher_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Teacher {
  final String id;
  final String name;
  final String subject;
  final String className;
  final String email;
  final String phone;
  final String qualification;
  final String experience;
  final String status;
  final String? profileImageUrl;
  final DateTime joiningDate;
  final DateTime createdAt;

  Teacher({
    required this.id,
    required this.name,
    required this.subject,
    required this.className,
    required this.email,
    required this.phone,
    required this.qualification,
    required this.experience,
    required this.status,
    this.profileImageUrl,
    required this.joiningDate,
    required this.createdAt,
  });

  factory Teacher.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Teacher(
      id: doc.id,
      name: data['name'] ?? '',
      subject: data['subject'] ?? '',
      className: data['className'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      qualification: data['qualification'] ?? '',
      experience: data['experience'] ?? '',
      status: data['status'] ?? 'Active',
      profileImageUrl: data['profileImageUrl'],
      joiningDate: (data['joiningDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'subject': subject,
      'className': className,
      'email': email,
      'phone': phone,
      'qualification': qualification,
      'experience': experience,
      'status': status,
      'profileImageUrl': profileImageUrl,
      'joiningDate': Timestamp.fromDate(joiningDate),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Teacher copyWith({
    String? id,
    String? name,
    String? subject,
    String? className,
    String? email,
    String? phone,
    String? qualification,
    String? experience,
    String? status,
    String? profileImageUrl,
    DateTime? joiningDate,
    DateTime? createdAt,
  }) {
    return Teacher(
      id: id ?? this.id,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      className: className ?? this.className,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      qualification: qualification ?? this.qualification,
      experience: experience ?? this.experience,
      status: status ?? this.status,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      joiningDate: joiningDate ?? this.joiningDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
