// lib/core/providers/notification_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'auth_provider.dart';
import 'student_provider.dart';

/// Stream notifications visible to the current user's role.
final notificationsProvider =
    StreamProvider<List<AppNotification>>((ref) {
  final authState = ref.watch(authProvider);
  final role = authState.user?.role;
  if (role == null) return const Stream.empty();

  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('notifications')
      .where('targetRole', whereIn: [role, 'all'])
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) =>
          snap.docs.map(AppNotification.fromFirestore).toList());
});

/// Count of unread notifications (drives badge on top bar).
final unreadNotificationCountProvider = Provider<int>((ref) {
  final notifAsync = ref.watch(notificationsProvider);
  return notifAsync.maybeWhen(
    data: (list) => list.where((n) => !n.isRead).length,
    orElse: () => 0,
  );
});

final notificationRepositoryProvider =
    Provider((ref) => NotificationRepository(ref));

class NotificationRepository {
  final Ref _ref;
  NotificationRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> sendNotification(AppNotification notification) async {
    await _db.collection('notifications').add(notification.toFirestore());
  }

  Future<void> markAsRead(String notificationId) async {
    await _db
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllAsRead(List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_db.collection('notifications').doc(id), {'isRead': true});
    }
    await batch.commit();
  }

  Future<void> deleteNotification(String id) async {
    await _db.collection('notifications').doc(id).delete();
  }
}
