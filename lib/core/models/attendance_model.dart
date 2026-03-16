// lib/core/models/attendance_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum AttendanceStatus { present, absent, leave }

class AttendanceRecord {
  final String id;
  final String studentId;
  final String studentName;
  final String studentCode;
  final String className;
  final String date; // 'yyyy-MM-dd'
  final AttendanceStatus status;
  final String markedBy;
  final DateTime updatedAt;

  const AttendanceRecord({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.studentCode,
    required this.className,
    required this.date,
    required this.status,
    required this.markedBy,
    required this.updatedAt,
  });

  factory AttendanceRecord.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceRecord(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      studentCode: data['studentCode'] as String? ?? '',
      className: data['className'] as String? ?? '',
      date: data['date'] as String? ?? '',
      status: _parseStatus(data['status'] as String? ?? 'present'),
      markedBy: data['markedBy'] as String? ?? '',
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'studentName': studentName,
        'studentCode': studentCode,
        'className': className,
        'date': date,
        'status': status.name,
        'markedBy': markedBy,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  static AttendanceStatus _parseStatus(String s) {
    switch (s) {
      case 'absent':
        return AttendanceStatus.absent;
      case 'leave':
        return AttendanceStatus.leave;
      default:
        return AttendanceStatus.present;
    }
  }

  String get statusLabel {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.absent:
        return 'Absent';
      case AttendanceStatus.leave:
        return 'Leave';
    }
  }

  AttendanceRecord copyWith({AttendanceStatus? status}) {
    return AttendanceRecord(
      id: id,
      studentId: studentId,
      studentName: studentName,
      studentCode: studentCode,
      className: className,
      date: date,
      status: status ?? this.status,
      markedBy: markedBy,
      updatedAt: updatedAt,
    );
  }
}
