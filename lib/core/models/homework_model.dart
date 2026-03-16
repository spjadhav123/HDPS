// lib/core/models/homework_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String id;
  final String title;
  final String subject;
  final String description;
  final String className;
  final DateTime dueDate;
  final String teacherId;
  final String teacherName;
  final String? attachmentUrl;
  final DateTime createdAt;

  const HomeworkModel({
    required this.id,
    required this.title,
    required this.subject,
    required this.description,
    required this.className,
    required this.dueDate,
    required this.teacherId,
    required this.teacherName,
    this.attachmentUrl,
    required this.createdAt,
  });

  factory HomeworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HomeworkModel(
      id: doc.id,
      title: data['title'] as String? ?? '',
      subject: data['subject'] as String? ?? '',
      description: data['description'] as String? ?? '',
      className: data['className'] as String? ?? '',
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      attachmentUrl: data['attachmentUrl'] as String?,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'subject': subject,
        'description': description,
        'className': className,
        'dueDate': Timestamp.fromDate(dueDate),
        'teacherId': teacherId,
        'teacherName': teacherName,
        'attachmentUrl': attachmentUrl,
        'createdAt': FieldValue.serverTimestamp(),
      };

  bool get isOverdue => dueDate.isBefore(DateTime.now());
}
