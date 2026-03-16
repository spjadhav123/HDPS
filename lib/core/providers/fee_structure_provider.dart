// lib/core/providers/fee_structure_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_structure_model.dart';
import '../models/student_model.dart';
// to update students when fee changes

class FeeStructureRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<FeeStructure>> getFeeStructures() {
    return _db.collection('fee_structures').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => FeeStructure.fromFirestore(doc)).toList();
    });
  }

  Future<void> saveFeeStructure(FeeStructure structure) async {
    // Save to firebase
    if (structure.id.isEmpty) {
      // creating new structure via a specific document ID (like className)
      await _db.collection('fee_structures').doc(structure.className).set(structure.toFirestore());
    } else {
      await _db.collection('fee_structures').doc(structure.id).update(structure.toFirestore());
    }
  }
}

final feeStructureRepositoryProvider = Provider<FeeStructureRepository>((ref) {
  return FeeStructureRepository();
});

final allFeeStructuresProvider = StreamProvider<List<FeeStructure>>((ref) {
  final repo = ref.watch(feeStructureRepositoryProvider);
  return repo.getFeeStructures();
});

class FeeAssignmentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Calculates new total for a student and updates the database
  Future<void> assignFeeToStudent(Student student, double newTotalFee) async {
    await _db.collection('students').doc(student.id).update({
      'feesTotal': newTotalFee,
    });
  }

  // Mass update all students in a class
  Future<void> updateStudentsFeeByClass(String className, double newTotalFee) async {
    final students = await _db.collection('students')
        .where('className', isEqualTo: className)
        .get();

    WriteBatch batch = _db.batch();
    for (var doc in students.docs) {
      batch.update(doc.reference, {'feesTotal': newTotalFee});
    }
    await batch.commit();
  }
}

final feeAssignmentServiceProvider = Provider<FeeAssignmentService>((ref) {
  return FeeAssignmentService();
});
