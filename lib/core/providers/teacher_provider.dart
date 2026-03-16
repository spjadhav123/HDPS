// lib/core/providers/teacher_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/teacher_model.dart';
import 'student_provider.dart'; // Reusing firestoreProvider

final teachersStreamProvider = StreamProvider<List<Teacher>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('teachers')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList());
});

final teacherRepositoryProvider = Provider((ref) => TeacherRepository(ref));

class TeacherRepository {
  final Ref _ref;
  TeacherRepository(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  Future<void> addTeacher(Teacher teacher) async {
    await _firestore.collection('teachers').add(teacher.toFirestore());
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await _firestore.collection('teachers').doc(teacher.id).update(teacher.toFirestore());
  }

  Future<void> deleteTeacher(String id) async {
    await _firestore.collection('teachers').doc(id).delete();
  }
}
