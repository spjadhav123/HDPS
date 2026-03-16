// lib/core/providers/homework_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/homework_model.dart';
import 'student_provider.dart';

/// Stream homework for a specific class.
final homeworkByClassProvider =
    StreamProvider.family<List<HomeworkModel>, String>((ref, className) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('homework')
      .where('className', isEqualTo: className)
      .orderBy('createdAt', descending: true)
      .limit(30)
      .snapshots()
      .map((snap) =>
          snap.docs.map(HomeworkModel.fromFirestore).toList());
});

/// Stream all homework (for admin/teacher view without class filter).
final allHomeworkProvider =
    StreamProvider<List<HomeworkModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('homework')
      .orderBy('createdAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snap) =>
          snap.docs.map(HomeworkModel.fromFirestore).toList());
});

final homeworkRepositoryProvider =
    Provider((ref) => HomeworkRepository(ref));

class HomeworkRepository {
  final Ref _ref;
  HomeworkRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> addHomework(HomeworkModel hw) async {
    await _db.collection('homework').add(hw.toFirestore());
  }

  Future<void> updateHomework(HomeworkModel hw) async {
    await _db.collection('homework').doc(hw.id).update(hw.toFirestore());
  }

  Future<void> deleteHomework(String id) async {
    await _db.collection('homework').doc(id).delete();
  }
}
