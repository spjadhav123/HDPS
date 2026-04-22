// lib/features/teacher/attendance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/student_model.dart';
import '../../core/models/teacher_model.dart';
import '../../core/providers/student_provider.dart';
import '../../core/providers/teacher_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';

enum _AttStatus { present, absent, leave }

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _loadedForClass; // track which class we last loaded
  bool _isSaving = false;
  bool _isLoadingAttendance = false;

  // studentId -> status
  final Map<String, _AttStatus> _statusByStudentId = {};

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  Widget build(BuildContext context) {
    final teacherAsync = ref.watch(currentTeacherProvider);
    final studentsAsync = ref.watch(studentsStreamProvider);

    // When teacher loads for the first time (or changes), load attendance
    ref.listen<AsyncValue<Teacher?>>(currentTeacherProvider, (prev, next) {
      next.whenData((teacher) {
        if (teacher != null && teacher.className != _loadedForClass) {
          _loadedForClass = teacher.className;
          _loadAttendance(teacher.className);
        }
      });
    });

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: teacherAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error loading teacher profile: $e')),
        data: (teacher) {
          if (teacher == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.person_off_rounded, size: 64, color: AppTheme.textSecondary),
                  const SizedBox(height: 16),
                  const Text(
                    'No class assigned',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please contact the administrator to assign you a class.',
                    style: TextStyle(color: AppTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          final className = teacher.className;

          return Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Attendance',
                  subtitle: '$className • ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
                  action: Row(
                    children: [
                      // Read-only class badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.class_rounded, size: 14, color: AppTheme.primary),
                            const SizedBox(width: 6),
                            Text(
                              className,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () => _pickDate(className),
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('dd MMM').format(_selectedDate)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: (_isSaving || _isLoadingAttendance)
                            ? null
                            : () => _saveAttendance(className),
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: _isSaving
                            ? const Text('Saving...')
                            : const Text('Save'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                _buildSummaryRow(studentsAsync, className),
                const SizedBox(height: 16),
                Expanded(child: _buildList(studentsAsync, className)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryRow(AsyncValue<List<Student>> studentsAsync, String className) {
    final counts = studentsAsync.maybeWhen(
      data: (students) {
        final filtered = students.where((s) => s.className == className);
        int present = 0, absent = 0, leave = 0;
        for (final s in filtered) {
          final st = _statusByStudentId[s.id] ?? _AttStatus.present;
          if (st == _AttStatus.present) present++;
          if (st == _AttStatus.absent) absent++;
          if (st == _AttStatus.leave) leave++;
        }
        return (present, absent, leave);
      },
      orElse: () => (0, 0, 0),
    );

    return Row(
      children: [
        _SummaryChip(label: 'Present', count: counts.$1, color: AppTheme.accent),
        const SizedBox(width: 12),
        _SummaryChip(label: 'Absent', count: counts.$2, color: AppTheme.secondary),
        const SizedBox(width: 12),
        _SummaryChip(label: 'Leave', count: counts.$3, color: AppTheme.warning),
        const Spacer(),
        if (_isLoadingAttendance)
          const Row(
            children: [
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 6),
              Text('Loading...', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
      ],
    );
  }

  Widget _buildList(AsyncValue<List<Student>> studentsAsync, String className) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: studentsAsync.when(
        data: (students) {
          final filtered = students
              .where((s) => s.className == className)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          if (filtered.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.people_outline_rounded, size: 56, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  Text(
                    'No students registered in $className.',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              final s = filtered[i];
              final status = _statusByStudentId[s.id] ?? _AttStatus.present;
              return AnimatedListItem(
                index: i,
                maxDelay: 300,
                child: ListTile(
                  leading: CircleAvatar(
                    radius: 18,
                    backgroundColor: _statusColor(status).withOpacity(0.15),
                    child: Text(
                      s.name.isNotEmpty ? s.name[0] : '?',
                      style: TextStyle(
                        color: _statusColor(status),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(
                    s.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(
                    s.studentCode,
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                  ),
                  trailing: SegmentedButton<_AttStatus>(
                    segments: const [
                      ButtonSegment(
                          value: _AttStatus.present,
                          label: Text('P', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.check_circle_outline, size: 14)),
                      ButtonSegment(
                          value: _AttStatus.absent,
                          label: Text('A', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.cancel_outlined, size: 14)),
                      ButtonSegment(
                          value: _AttStatus.leave,
                          label: Text('L', style: TextStyle(fontSize: 11)),
                          icon: Icon(Icons.beach_access, size: 14)),
                    ],
                    selected: {status},
                    onSelectionChanged: (v) {
                      setState(() => _statusByStudentId[s.id] = v.first);
                    },
                    style: ButtonStyle(
                      visualDensity: VisualDensity.compact,
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) {
                          return _statusColor(status).withOpacity(0.15);
                        }
                        return null;
                      }),
                    ),
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Color _statusColor(_AttStatus status) {
    switch (status) {
      case _AttStatus.present:
        return AppTheme.accent;
      case _AttStatus.absent:
        return AppTheme.secondary;
      case _AttStatus.leave:
        return AppTheme.warning;
    }
  }

  Future<void> _pickDate(String className) async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _loadAttendance(className);
    }
  }

  Future<void> _loadAttendance(String className) async {
    setState(() => _isLoadingAttendance = true);
    try {
      final query = await FirebaseFirestore.instance
          .collection('attendance')
          .where('date', isEqualTo: _dateKey)
          .where('className', isEqualTo: className)
          .get();

      final map = <String, _AttStatus>{};
      for (final doc in query.docs) {
        final data = doc.data();
        final studentId = (data['studentId'] ?? '') as String;
        final statusStr = (data['status'] ?? 'present') as String;
        if (studentId.isEmpty) continue;
        map[studentId] = _parseStatus(statusStr);
      }

      if (!mounted) return;
      setState(() {
        _statusByStudentId
          ..clear()
          ..addAll(map);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading attendance: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingAttendance = false);
    }
  }

  Future<void> _saveAttendance(String className) async {
    final students = ref.read(studentsStreamProvider).maybeWhen(
          data: (s) => s.where((x) => x.className == className).toList(),
          orElse: () => <Student>[],
        );
    if (students.isEmpty) return;

    final teacherName = ref.read(currentTeacherProvider).maybeWhen(
          data: (t) => t?.name ?? 'Teacher',
          orElse: () => 'Teacher',
        );

    setState(() => _isSaving = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final col = FirebaseFirestore.instance.collection('attendance');

      for (final s in students) {
        final status = _statusByStudentId[s.id] ?? _AttStatus.present;
        final docId = '${_dateKey}_${_safeKey(className)}_${s.id}';
        batch.set(col.doc(docId), {
          'date': _dateKey,
          'className': className,
          'studentId': s.id,
          'studentCode': s.studentCode,
          'studentName': s.name,
          'status': _statusToString(status),
          'markedBy': teacherName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Attendance saved for $className (${DateFormat('dd MMM yyyy').format(_selectedDate)})'),
          backgroundColor: AppTheme.accent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving attendance: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String _safeKey(String input) =>
      input.replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_');

  _AttStatus _parseStatus(String s) {
    switch (s) {
      case 'absent':
        return _AttStatus.absent;
      case 'leave':
        return _AttStatus.leave;
      case 'present':
      default:
        return _AttStatus.present;
    }
  }

  String _statusToString(_AttStatus s) {
    switch (s) {
      case _AttStatus.present:
        return 'present';
      case _AttStatus.absent:
        return 'absent';
      case _AttStatus.leave:
        return 'leave';
    }
  }
}

class _SummaryChip extends StatelessWidget {
  final String label;
  final int count;
  final Color color;
  const _SummaryChip(
      {required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text('$count',
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
