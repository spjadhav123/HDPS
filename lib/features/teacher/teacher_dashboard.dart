// lib/features/teacher/teacher_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';
import '../../core/providers/student_provider.dart';
import '../../core/providers/teacher_provider.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/models/student_model.dart';
import '../../core/models/attendance_model.dart';
import '../../shared/widgets/responsive_layout.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final teacherAsync = ref.watch(currentTeacherProvider);
    final studentsAsync = ref.watch(studentsStreamProvider);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayFormatted = DateFormat('EEEE, d MMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: teacherAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (teacher) {
            final className = teacher?.className ?? 'No Class Assigned';
            final isAssigned = teacher != null;

            // Filter students only for teacher's class
            final classStudents = studentsAsync.maybeWhen(
              data: (students) => students
                  .where((s) => s.className == className)
                  .toList(),
              orElse: () => <Student>[],
            );

            // Watch live attendance for today
            final AsyncValue<List<AttendanceRecord>> attendanceAsync = isAssigned
                ? ref.watch(attendanceByClassDateProvider(
                    (className: className, date: today)))
                : const AsyncData(<AttendanceRecord>[]);

            final presentCount = attendanceAsync.maybeWhen(
              data: (records) => records
                  .where((r) => r.status == AttendanceStatus.present)
                  .length,
              orElse: () => 0,
            );

            final totalStudents = classStudents.length;
            final attendancePct = totalStudents > 0
                ? ((presentCount / totalStudents) * 100).toStringAsFixed(0)
                : '—';

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: 'Teacher Dashboard',
                  subtitle: isAssigned
                      ? 'Class: $className | $todayFormatted'
                      : 'No class assigned — contact administrator',
                ),
                const SizedBox(height: 24),

                // ── Stat Cards ─────────────────────────────────
                GridView(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 320,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.6,
                  ),
                  children: [
                    StatCard(
                      title: 'My Students',
                      value: studentsAsync.maybeWhen(
                        data: (_) => totalStudents.toString(),
                        orElse: () => '...',
                      ),
                      icon: Icons.people_rounded,
                      color: AppTheme.primary,
                      trend: isAssigned ? className : 'No class',
                      animDelay: 0,
                    ),
                    StatCard(
                      title: 'Present Today',
                      value: attendanceAsync.when(
                        data: (_) => presentCount.toString(),
                        loading: () => '...',
                        error: (_, __) => '?',
                      ),
                      icon: Icons.how_to_reg_rounded,
                      color: AppTheme.accent,
                      trend: isAssigned
                          ? '$attendancePct% attendance'
                          : '—',
                      animDelay: 100,
                    ),
                    const StatCard(
                      title: 'Pending Homework',
                      value: '4',
                      icon: Icons.assignment_rounded,
                      color: AppTheme.warning,
                      trend: 'Requires review',
                      animDelay: 200,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Body ───────────────────────────────────────
                ResponsiveLayout(
                  mobile: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildTodaySchedule(),
                      const SizedBox(height: 24),
                      _buildStudentsList(studentsAsync, className),
                    ],
                  ),
                  desktop: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildTodaySchedule(),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        flex: 3,
                        child: _buildStudentsList(studentsAsync, className),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildTodaySchedule() {
    final schedule = [
      ('8:30 AM', 'Circle Time', Icons.circle_rounded, AppTheme.primary),
      ('9:00 AM', 'English Literacy', Icons.menu_book_rounded, AppTheme.accent),
      ('10:00 AM', 'Math Activity', Icons.calculate_rounded, AppTheme.warning),
      ('11:00 AM', 'Snack Break', Icons.lunch_dining_rounded, AppTheme.secondary),
      ('11:30 AM', 'Art & Craft', Icons.palette_rounded, const Color(0xFF8B5CF6)),
      ('12:30 PM', 'Story Time & Dismissal', Icons.auto_stories_rounded, AppTheme.accent),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Today's Schedule",
              style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...schedule.asMap().entries.map((e) => AnimatedListItem(
                index: e.key,
                maxDelay: 500,
                child: _buildScheduleRow(e.value, e.key),
              )),
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.medium);
  }

  Widget _buildScheduleRow((String, String, IconData, Color) s, int i) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
              width: 68,
              child: Text(s.$1,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                      fontWeight: FontWeight.w600))),
          Container(width: 2, height: 36, color: s.$4.withOpacity(0.3)),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: s.$4.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(s.$3, color: s.$4, size: 16),
          ),
          const SizedBox(width: 10),
          Text(s.$2,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStudentsList(
      AsyncValue<List<Student>> studentsAsync, String className) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Class Students',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppTheme.textPrimary),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  className,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          studentsAsync.when(
            data: (List<Student> students) {
              final filtered = students
                  .where((s) => s.className == className)
                  .toList()
                ..sort((a, b) => a.name.compareTo(b.name));

              if (filtered.isEmpty) {
                return Text(
                  'No students registered in $className yet.',
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: filtered.map<Widget>((Student s) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.2),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0] : '?',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppTheme.primary,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    label: Text(
                      '${s.studentCode} • ${s.name}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    backgroundColor: Colors.white,
                    side: BorderSide(color: Colors.grey.shade200),
                  );
                }).toList(),
              );
            },
            loading: () => const ShimmerListView(itemCount: 3, itemHeight: 60),
            error: (err, _) => Text(
              'Error loading students: $err',
              style: const TextStyle(fontSize: 13, color: Colors.redAccent),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.slow);
  }
}
