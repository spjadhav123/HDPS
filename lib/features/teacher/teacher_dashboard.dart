import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';
import '../../core/providers/student_provider.dart';
import '../../core/models/student_model.dart';
import '../../shared/widgets/responsive_layout.dart';

class TeacherDashboard extends ConsumerWidget {
  const TeacherDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<Student>> studentsAsync =
        ref.watch(studentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Teacher Dashboard',
              subtitle: 'Class: Nursery A | Today: Monday, 3 Mar 2026',
            ),
            const SizedBox(height: 24),
            LayoutBuilder(builder: (ctx, c) {
              final cols = c.maxWidth > 700 ? 3 : 1;
              return GridView.count(
                crossAxisCount: cols,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.8,
                children: [
                  StatCard(
                    title: 'Students (All)',
                    value: studentsAsync.maybeWhen(
                      data: (s) => '${s.length}',
                      orElse: () => '--',
                    ),
                    icon: Icons.people_rounded,
                    color: AppTheme.primary,
                    trend: 'From admin registrations',
                    animDelay: 0,
                  ),
                  const StatCard(
                    title: 'Present Today',
                    value: '--',
                    icon: Icons.how_to_reg_rounded,
                    color: AppTheme.accent,
                    trend: 'Attendance not wired yet',
                    animDelay: 100,
                  ),
                  const StatCard(
                    title: 'Absent Today',
                    value: '--',
                    icon: Icons.person_off_rounded,
                    color: AppTheme.secondary,
                    trend: 'Attendance not wired yet',
                    animDelay: 200,
                  ),
                ],
              );
            }),
            const SizedBox(height: 24),
            ResponsiveLayout(
              mobile: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTodaySchedule(),
                  const SizedBox(height: 24),
                  _buildStudentsList(studentsAsync),
                ],
              ),
              desktop: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildTodaySchedule()),
                  const SizedBox(width: 24),
                  Expanded(flex: 3, child: _buildStudentsList(studentsAsync)),
                ],
              ),
            ),
          ],
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
          const Text("Today's Schedule", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
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
          SizedBox(width: 68, child: Text(s.$1, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600))),
          Container(width: 2, height: 36, color: s.$4.withOpacity(0.3)),
          const SizedBox(width: 12),
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(color: s.$4.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(s.$3, color: s.$4, size: 16),
          ),
          const SizedBox(width: 10),
          Text(s.$2, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildStudentsList(AsyncValue<List<Student>> studentsAsync) {
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
          const Text(
            'Registered Students',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          studentsAsync.when(
            data: (List<Student> students) {
              if (students.isEmpty) {
                return const Text(
                  'No students registered yet.',
                  style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: students.map<Widget>((Student s) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundColor: AppTheme.primary.withOpacity(0.2),
                      child: Text(
                        s.name.isNotEmpty ? s.name[0] : '?',
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    label: Text(
                      '${s.studentCode} • ${s.name} • ${s.className}',
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
