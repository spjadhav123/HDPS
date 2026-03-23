// lib/core/models/student_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Student {
  final String id;
  final String studentCode; // Human-friendly ID including class, name, and phone
  final String name;
  final String className;
  final String parent;
  final String parentEmail;
  final String parentUsername; // Auto-generated: first name lowercase, deduplicated
  final String phone;
  final double feesPaid;
  final double feesTotal;
  final String status;
  final DateTime createdAt;

  Student({
    required this.id,
    required this.studentCode,
    required this.name,
    required this.className,
    required this.parent,
    required this.parentEmail,
    this.parentUsername = '',
    required this.phone,
    required this.feesPaid,
    required this.feesTotal,
    required this.status,
    required this.createdAt,
  });

  factory Student.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Student(
      id: doc.id,
      studentCode: (data['studentCode'] ?? '') as String,
      name: data['name'] ?? '',
      className: data['className'] ?? '',
      parent: data['parent'] ?? '',
      parentEmail: data['parentEmail'] ?? '',
      parentUsername: data['parentUsername'] ?? '',
      phone: data['phone'] ?? '',
      feesPaid: (data['feesPaid'] ?? 0).toDouble(),
      feesTotal: (data['feesTotal'] ?? 0).toDouble(),
      status: data['status'] ?? 'Active',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'studentCode': studentCode,
      'name': name,
      'className': className,
      'parent': parent,
      'parentEmail': parentEmail,
      'parentUsername': parentUsername,
      'phone': phone,
      'feesPaid': feesPaid,
      'feesTotal': feesTotal,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Student copyWith({
    String? studentCode,
    String? name,
    String? className,
    String? parent,
    String? parentEmail,
    String? parentUsername,
    String? phone,
    double? feesPaid,
    double? feesTotal,
    String? status,
  }) {
    return Student(
      id: id,
      studentCode: studentCode ?? this.studentCode,
      name: name ?? this.name,
      className: className ?? this.className,
      parent: parent ?? this.parent,
      parentEmail: parentEmail ?? this.parentEmail,
      parentUsername: parentUsername ?? this.parentUsername,
      phone: phone ?? this.phone,
      feesPaid: feesPaid ?? this.feesPaid,
      feesTotal: feesTotal ?? this.feesTotal,
      status: status ?? this.status,
      createdAt: createdAt,
    );
  }
}
