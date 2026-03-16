// lib/core/providers/attendance_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/attendance_model.dart';
import 'student_provider.dart';

/// Stream all attendance records for a class on a specific date.
final attendanceByClassDateProvider = StreamProvider.family<
    List<AttendanceRecord>,
    ({String className, String date})>((ref, params) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('attendance')
      .where('date', isEqualTo: params.date)
      .where('className', isEqualTo: params.className)
      .snapshots()
      .map((snap) =>
          snap.docs.map(AttendanceRecord.fromFirestore).toList());
});

/// Stream attendance records for a specific student (for calendar view).
final studentAttendanceProvider =
    StreamProvider.family<List<AttendanceRecord>, String>((ref, studentId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('attendance')
      .where('studentId', isEqualTo: studentId)
      .orderBy('date', descending: true)
      .limit(90) // last 3 months
      .snapshots()
      .map((snap) =>
          snap.docs.map(AttendanceRecord.fromFirestore).toList());
});

final attendanceRepositoryProvider =
    Provider((ref) => AttendanceRepository(ref));

class AttendanceRepository {
  final Ref _ref;
  AttendanceRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);

  String _safeKey(String input) =>
      input.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');

  Future<void> saveAttendance({
    required String date,
    required String className,
    required List<AttendanceRecord> records,
    required String markedBy,
  }) async {
    final batch = _db.batch();
    final col = _db.collection('attendance');

    for (final record in records) {
      final docId =
          '${date}_${_safeKey(className)}_${record.studentId}';
      batch.set(
        col.doc(docId),
        record.toFirestore()..['markedBy'] = markedBy,
        SetOptions(merge: true),
      );
    }
    await batch.commit();
  }

  /// Returns a map of 'yyyy-MM-dd' -> AttendanceStatus for a student
  Future<Map<String, AttendanceStatus>> getAttendanceMap(
      String studentId, DateTime from, DateTime to) async {
    final fromStr =
        '${from.year.toString().padLeft(4, '0')}-${from.month.toString().padLeft(2, '0')}-${from.day.toString().padLeft(2, '0')}';
    final toStr =
        '${to.year.toString().padLeft(4, '0')}-${to.month.toString().padLeft(2, '0')}-${to.day.toString().padLeft(2, '0')}';

    final snap = await _db
        .collection('attendance')
        .where('studentId', isEqualTo: studentId)
        .where('date', isGreaterThanOrEqualTo: fromStr)
        .where('date', isLessThanOrEqualTo: toStr)
        .get();

    final map = <String, AttendanceStatus>{};
    for (final doc in snap.docs) {
      final record = AttendanceRecord.fromFirestore(doc);
      map[record.date] = record.status;
    }
    return map;
  }

  /// Compute attendance % for a student in last N days
  Future<double> getAttendancePercentage(
      String studentId, int days) async {
    final to = DateTime.now();
    final from = to.subtract(Duration(days: days));
    final map = await getAttendanceMap(studentId, from, to);
    if (map.isEmpty) return 0.0;
    final present =
        map.values.where((s) => s == AttendanceStatus.present).length;
    return (present / map.length) * 100;
  }
}
