// lib/features/teacher/attendance_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';
import '../../shared/widgets/page_header.dart';

enum _AttStatus { present, absent, leave }

class AttendanceScreen extends ConsumerStatefulWidget {
  const AttendanceScreen({super.key});

  @override
  ConsumerState<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends ConsumerState<AttendanceScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedClass;
  bool _isSaving = false;
  bool _isLoadingAttendance = false;

  // studentId -> status
  final Map<String, _AttStatus> _statusByStudentId = {};

  String get _dateKey => DateFormat('yyyy-MM-dd').format(_selectedDate);

  @override
  void initState() {
    super.initState();
    // We'll load attendance after we have a class selection.
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Attendance',
              subtitle:
                  '${_selectedClass ?? 'Select class'} • ${DateFormat('dd MMM yyyy').format(_selectedDate)}',
              action: studentsAsync.maybeWhen(
                data: (students) {
                  final classes = ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG'];

                  if (_selectedClass == null) {
                    // Set default class
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _selectedClass = classes.first);
                      _loadAttendance();
                    });
                  }

                  return Row(
                    children: [
                      DropdownButton<String>(
                        value: _selectedClass,
                        hint: const Text('Class'),
                        onChanged: (v) {
                          setState(() => _selectedClass = v);
                          _loadAttendance();
                        },
                        items: classes
                            .map((c) =>
                                DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        underline: const SizedBox(),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: _pickDate,
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(DateFormat('dd MMM').format(_selectedDate)),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: (_isSaving ||
                                _isLoadingAttendance ||
                                _selectedClass == null)
                            ? null
                            : _saveAttendance,
                        icon: const Icon(Icons.save_rounded, size: 16),
                        label: _isSaving
                            ? const Text('Saving...')
                            : const Text('Save'),
                      ),
                    ],
                  );
                },
                orElse: () => Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today, size: 16),
                      label: Text(DateFormat('dd MMM').format(_selectedDate)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildSummaryRow(studentsAsync),
            const SizedBox(height: 16),
            Expanded(child: _buildList(studentsAsync)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(AsyncValue<List<Student>> studentsAsync) {
    final counts = studentsAsync.maybeWhen(
      data: (students) {
        final className = _selectedClass;
        if (className == null) return (0, 0, 0);
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
        _SummaryChip(
            label: 'Present', count: counts.$1, color: AppTheme.accent),
        const SizedBox(width: 12),
        _SummaryChip(
            label: 'Absent', count: counts.$2, color: AppTheme.secondary),
        const SizedBox(width: 12),
        _SummaryChip(
            label: 'Leave', count: counts.$3, color: AppTheme.warning),
        const Spacer(),
        if (_isLoadingAttendance)
          const Text('Loading...',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
      ],
    );
  }

  Widget _buildList(AsyncValue<List<Student>> studentsAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: studentsAsync.when(
        data: (students) {
          final className = _selectedClass;
          if (className == null) {
            return const Center(
              child: Text('Please select a class.',
                  style: TextStyle(color: AppTheme.textSecondary)),
            );
          }

          final filtered = students
              .where((s) => s.className == className)
              .toList()
            ..sort((a, b) => a.name.compareTo(b.name));

          if (filtered.isEmpty) {
            return Center(
              child: Text('No students registered in $className.',
                  style: const TextStyle(color: AppTheme.textSecondary)),
            );
          }

          return ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (ctx, i) {
              final s = filtered[i];
              final status = _statusByStudentId[s.id] ?? _AttStatus.present;
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primary.withOpacity(0.15),
                  child: Text(
                    s.name.isNotEmpty ? s.name[0] : '?',
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                title: Text(
                  s.name,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600),
                ),
                subtitle: Text(
                  s.studentCode,
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary),
                ),
                trailing: SegmentedButton<_AttStatus>(
                  segments: const [
                    ButtonSegment(
                        value: _AttStatus.present,
                        label: Text('P', style: TextStyle(fontSize: 11)),
                        icon: Icon(Icons.check, size: 14)),
                    ButtonSegment(
                        value: _AttStatus.absent,
                        label: Text('A', style: TextStyle(fontSize: 11)),
                        icon: Icon(Icons.close, size: 14)),
                    ButtonSegment(
                        value: _AttStatus.leave,
                        label: Text('L', style: TextStyle(fontSize: 11)),
                        icon: Icon(Icons.beach_access, size: 14)),
                  ],
                  selected: {status},
                  onSelectionChanged: (v) {
                    setState(() => _statusByStudentId[s.id] = v.first);
                  },
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
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

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) {
      setState(() => _selectedDate = d);
      _loadAttendance();
    }
  }

  Future<void> _loadAttendance() async {
    final className = _selectedClass;
    if (className == null) return;

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

  Future<void> _saveAttendance() async {
    final className = _selectedClass;
    if (className == null) return;

    final students = ref.read(studentsStreamProvider).maybeWhen(
          data: (s) => s.where((x) => x.className == className).toList(),
          orElse: () => <Student>[],
        );
    if (students.isEmpty) return;

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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
  const _SummaryChip({required this.label, required this.count, required this.color});

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
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
