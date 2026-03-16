// lib/core/models/fee_structure_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class FeeStructure {
  final String id;
  final String className;
  final double tuitionFee;
  final double termFee;
  final double transportFee;
  final double examFee;
  final double otherFees;
  final DateTime updatedAt;

  const FeeStructure({
    required this.id,
    required this.className,
    required this.tuitionFee,
    required this.termFee,
    required this.transportFee,
    required this.examFee,
    required this.otherFees,
    required this.updatedAt,
  });

  double get totalFee => tuitionFee + termFee + transportFee + examFee + otherFees;

  factory FeeStructure.fromFirestore(DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return FeeStructure(
      id: doc.id,
      className: data['className'] ?? '',
      tuitionFee: (data['tuitionFee'] ?? 0).toDouble(),
      termFee: (data['termFee'] ?? 0).toDouble(),
      transportFee: (data['transportFee'] ?? 0).toDouble(),
      examFee: (data['examFee'] ?? 0).toDouble(),
      otherFees: (data['otherFees'] ?? 0).toDouble(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'className': className,
      'tuitionFee': tuitionFee,
      'termFee': termFee,
      'transportFee': transportFee,
      'examFee': examFee,
      'otherFees': otherFees,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
