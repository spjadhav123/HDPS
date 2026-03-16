// lib/core/providers/chat_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_message_model.dart';
import 'student_provider.dart';

/// Stream messages for a specific chat thread.
final chatMessagesProvider =
    StreamProvider.family<List<ChatMessage>, String>((ref, threadId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .doc(threadId)
      .collection('messages')
      .orderBy('timestamp', descending: false)
      .limitToLast(100)
      .snapshots()
      .map((snap) =>
          snap.docs.map(ChatMessage.fromFirestore).toList());
});

/// Stream all chat threads for a user.
final chatThreadsProvider =
    StreamProvider.family<List<ChatThread>, String>((ref, userId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('chats')
      .where('participants', arrayContains: userId)
      .orderBy('lastMessageAt', descending: true)
      .snapshots()
      .map((snap) =>
          snap.docs.map(ChatThread.fromFirestore).toList());
});

final chatRepositoryProvider = Provider((ref) => ChatRepository(ref));

class ChatRepository {
  final Ref _ref;
  ChatRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  String buildThreadId(String id1, String id2) {
    final sorted = [id1, id2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }

  Future<void> sendMessage({
    required String threadId,
    required ChatMessage message,
    required String parentName,
    required String teacherName,
    required String studentName,
    required List<String> participantIds,
  }) async {
    final threadRef = _db.collection('chats').doc(threadId);
    final msgRef = threadRef.collection('messages').doc();

    final batch = _db.batch();
    batch.set(msgRef, message.toFirestore());
    batch.set(
      threadRef,
      {
        'participants': participantIds,
        'parentName': parentName,
        'teacherName': teacherName,
        'studentName': studentName,
        'lastMessage': message.message,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'unreadCount': FieldValue.increment(1),
      },
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Future<void> markThreadRead(String threadId) async {
    await _db
        .collection('chats')
        .doc(threadId)
        .update({'unreadCount': 0});
  }
}
