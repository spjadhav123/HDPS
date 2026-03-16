// lib/core/providers/report_card_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/report_card_model.dart';
import 'student_provider.dart';

/// Stream report cards for a specific student.
final studentReportCardsProvider = StreamProvider.family<List<ReportCard>, String>((ref, studentId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('report_cards')
      .where('studentId', isEqualTo: studentId)
      .orderBy('date', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map(ReportCard.fromFirestore).toList());
});

final reportCardRepositoryProvider = Provider((ref) => ReportCardRepository(ref));

class ReportCardRepository {
  final Ref _ref;
  ReportCardRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  Future<void> addReportCard(ReportCard report) async {
    await _db.collection('report_cards').add(report.toFirestore());
  }

  Future<void> updateReportCard(ReportCard report) async {
    await _db.collection('report_cards').doc(report.id).update(report.toFirestore());
  }

  Future<void> deleteReportCard(String id) async {
    await _db.collection('report_cards').doc(id).delete();
  }
}
