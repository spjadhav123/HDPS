// lib/core/providers/receipt_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/receipt_model.dart';

final receiptProvider = Provider<ReceiptService>((ref) {
  return ReceiptService();
});

final allReceiptsStreamProvider = StreamProvider<List<Receipt>>((ref) {
  return ref.read(receiptProvider).getAllReceipts();
});

final studentReceiptsStreamProvider = StreamProvider.family<List<Receipt>, String>((ref, studentId) {
  return ref.read(receiptProvider).getStudentReceipts(studentId);
});

class ReceiptService {
  final _db = FirebaseFirestore.instance.collection('receipts');

  Stream<List<Receipt>> getAllReceipts() {
    return _db.orderBy('date', descending: true).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => Receipt.fromMap(doc.data(), doc.id)).toList();
    });
  }

  Stream<List<Receipt>> getStudentReceipts(String studentId) {
    return _db
        .where('studentId', isEqualTo: studentId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Receipt.fromMap(doc.data(), doc.id)).toList();
    });
  }
}
