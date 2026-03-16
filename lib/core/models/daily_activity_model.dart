// lib/core/models/daily_activity_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class DailyActivity {
  final String id;
  final String studentId;
  final String studentName;
  final String className;
  final String date; // 'yyyy-MM-dd'
  final String mood; // 'happy', 'okay', 'sad'
  final List<String> activities; // e.g. ['Drawing', 'Singing', 'Math Games']
  final String teacherNote;
  final List<String> photoUrls;
  final String markedBy;
  final DateTime createdAt;

  const DailyActivity({
    required this.id,
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.date,
    required this.mood,
    required this.activities,
    required this.teacherNote,
    required this.photoUrls,
    required this.markedBy,
    required this.createdAt,
  });

  factory DailyActivity.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DailyActivity(
      id: doc.id,
      studentId: data['studentId'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      className: data['className'] as String? ?? '',
      date: data['date'] as String? ?? '',
      mood: data['mood'] as String? ?? 'okay',
      activities: List<String>.from(data['activities'] ?? []),
      teacherNote: data['teacherNote'] as String? ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      markedBy: data['markedBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'studentId': studentId,
        'studentName': studentName,
        'className': className,
        'date': date,
        'mood': mood,
        'activities': activities,
        'teacherNote': teacherNote,
        'photoUrls': photoUrls,
        'markedBy': markedBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  String get moodEmoji {
    switch (mood) {
      case 'happy':
        return '😊';
      case 'sad':
        return '😢';
      case 'excited':
        return '🤩';
      default:
        return '😐';
    }
  }
}
