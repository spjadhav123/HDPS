// lib/core/models/notification_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum NotificationType { announcement, feeReminder, attendance, homework, event, general }

class AppNotification {
  final String id;
  final String title;
  final String body;
  final NotificationType type;
  final String targetRole; // 'parent', 'teacher', 'all'
  final String? targetUserId; // null = broadcast
  final bool isRead;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.targetRole,
    this.targetUserId,
    required this.isRead,
    required this.createdAt,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      type: _parseType(data['type'] as String? ?? 'general'),
      targetRole: data['targetRole'] as String? ?? 'all',
      targetUserId: data['targetUserId'] as String?,
      isRead: data['isRead'] as bool? ?? false,
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'body': body,
        'type': type.name,
        'targetRole': targetRole,
        'targetUserId': targetUserId,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static NotificationType _parseType(String s) {
    return NotificationType.values.firstWhere(
      (e) => e.name == s,
      orElse: () => NotificationType.general,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      body: body,
      type: type,
      targetRole: targetRole,
      targetUserId: targetUserId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
    );
  }
}
