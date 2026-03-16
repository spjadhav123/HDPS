// lib/core/models/chat_message_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String senderRole;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      id: doc.id,
      senderId: data['senderId'] as String? ?? '',
      senderName: data['senderName'] as String? ?? '',
      senderRole: data['senderRole'] as String? ?? '',
      message: data['message'] as String? ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isRead: data['isRead'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'senderId': senderId,
        'senderName': senderName,
        'senderRole': senderRole,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'isRead': isRead,
      };
}

class ChatThread {
  final String id; // usually parentEmail_teacherEmail or sorted combo
  final String parentId;
  final String parentName;
  final String teacherId;
  final String teacherName;
  final String studentName;
  final String lastMessage;
  final DateTime lastMessageAt;
  final int unreadCount;

  const ChatThread({
    required this.id,
    required this.parentId,
    required this.parentName,
    required this.teacherId,
    required this.teacherName,
    required this.studentName,
    required this.lastMessage,
    required this.lastMessageAt,
    required this.unreadCount,
  });

  factory ChatThread.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ChatThread(
      id: doc.id,
      parentId: data['parentId'] as String? ?? '',
      parentName: data['parentName'] as String? ?? '',
      teacherId: data['teacherId'] as String? ?? '',
      teacherName: data['teacherName'] as String? ?? '',
      studentName: data['studentName'] as String? ?? '',
      lastMessage: data['lastMessage'] as String? ?? '',
      lastMessageAt:
          (data['lastMessageAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: data['unreadCount'] as int? ?? 0,
    );
  }
}
