// lib/core/models/report_card_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectGrade {
  final String subject;
  final int marks;
  final int maxMarks;
  final String grade; // e.g., A+, A, B, etc.
  final String remarks;

  const SubjectGrade({
    required this.subject,
    required this.marks,
    required this.maxMarks,
    required this.grade,
    this.remarks = '',
  });

  Map<String, dynamic> toMap() => {
        'subject': subject,
        'marks': marks,
        'maxMarks': maxMarks,
        'grade': grade,
        'remarks': remarks,
      };

  factory SubjectGrade.fromMap(Map<String, dynamic> map) => SubjectGrade(
        subject: map['subject'] ?? '',
        marks: map['marks'] ?? 0,
        maxMarks: map['maxMarks'] ?? 100,
        grade: map['grade'] ?? '',
        remarks: map['remarks'] ?? '',
      );

  SubjectGrade copyWith({
    String? subject,
    int? marks,
    int? maxMarks,
    String? grade,
    String? remarks,
  }) {
    return SubjectGrade(
      subject: subject ?? this.subject,
      marks: marks ?? this.marks,
      maxMarks: maxMarks ?? this.maxMarks,
      grade: grade ?? this.grade,
      remarks: remarks ?? this.remarks,
    );
  }
}

class ReportCard {
  final String id;
  final String studentId;
  final String term; // e.g., First Term, Annual
  final String academicYear; // e.g., 2024-25
  final List<SubjectGrade> grades;
  final int totalMarks;
  final int maxMarks;
  final String teacherRemarks;
  final String status;
  final DateTime createdAt;

  const ReportCard({
    required this.id,
    required this.studentId,
    required this.term,
    required this.academicYear,
    required this.grades,
    required this.totalMarks,
    required this.maxMarks,
    required this.teacherRemarks,
    required this.status,
    required this.createdAt,
  });

  factory ReportCard.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ReportCard(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      term: data['term'] as String? ?? '',
      academicYear: data['academicYear'] as String? ?? '',
      grades: (data['grades'] as List? ?? [])
          .map((g) => SubjectGrade.fromMap(g as Map<String, dynamic>))
          .toList(),
      totalMarks: data['totalMarks'] as int? ?? 0,
      maxMarks: data['maxMarks'] as int? ?? 0,
      teacherRemarks: data['teacherRemarks'] as String? ?? '',
      status: data['status'] as String? ?? 'Published',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'term': term,
        'academicYear': academicYear,
        'grades': grades.map((g) => g.toMap()).toList(),
        'totalMarks': totalMarks,
        'maxMarks': maxMarks,
        'teacherRemarks': teacherRemarks,
        'status': status,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
