// lib/core/providers/event_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/event_model.dart';
import 'student_provider.dart';

final upcomingEventsProvider =
    StreamProvider<List<SchoolEvent>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  final now =
      Timestamp.fromDate(DateTime.now().subtract(const Duration(days: 1)));
  return firestore
      .collection('events')
      .where('date', isGreaterThanOrEqualTo: now)
      .orderBy('date')
      .limit(20)
      .snapshots()
      .map((snap) =>
          snap.docs.map(SchoolEvent.fromFirestore).toList());
});

final allEventsProvider = StreamProvider<List<SchoolEvent>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('events')
      .orderBy('date', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map(SchoolEvent.fromFirestore).toList());
});

final eventRepositoryProvider = Provider((ref) => EventRepository(ref));

class EventRepository {
  final Ref _ref;
  EventRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> addEvent(SchoolEvent event) async {
    await _db.collection('events').add(event.toFirestore());
  }

  Future<void> updateEvent(SchoolEvent event) async {
    await _db.collection('events').doc(event.id).update(event.toFirestore());
  }

  Future<void> deleteEvent(String id) async {
    await _db.collection('events').doc(id).delete();
  }
}
