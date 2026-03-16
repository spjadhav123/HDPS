// lib/core/providers/daily_activity_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/daily_activity_model.dart';
import 'student_provider.dart';

/// Stream daily activities for a specific student on a specific date.
final studentDailyActivityProvider = StreamProvider.family<DailyActivity?, ({String studentId, String date})>((ref, params) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('daily_activities')
      .where('studentId', isEqualTo: params.studentId)
      .where('date', isEqualTo: params.date)
      .limit(1)
      .snapshots()
      .map((snap) => snap.docs.isEmpty ? null : DailyActivity.fromFirestore(snap.docs.first));
});

/// Stream recent daily activities for a student (activity timeline).
final studentActivityTimelineProvider = StreamProvider.family<List<DailyActivity>, String>((ref, studentId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('daily_activities')
      .where('studentId', isEqualTo: studentId)
      .orderBy('date', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) => snap.docs.map(DailyActivity.fromFirestore).toList());
});

final dailyActivityRepositoryProvider = Provider((ref) => DailyActivityRepository(ref));

class DailyActivityRepository {
  final Ref _ref;
  DailyActivityRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> saveDailyActivity(DailyActivity activity) async {
    final docId = '${activity.date}_${activity.studentId}';
    await _db.collection('daily_activities').doc(docId).set(
      activity.toFirestore(),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteDailyActivity(String id) async {
    await _db.collection('daily_activities').doc(id).delete();
  }
}
