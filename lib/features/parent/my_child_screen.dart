// lib/features/parent/my_child_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/providers/student_provider.dart';

class MyChildScreen extends ConsumerWidget {
  const MyChildScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildStudentProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: childAsync.when(
          data: (student) {
            if (student == null) {
              return const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PageHeader(
                    title: "My Child's Progress",
                    subtitle:
                        'No student record is linked to your account yet.',
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Please ask the school admin to register your child '
                    'using your email address.',
                    style: TextStyle(
                        fontSize: 13, color: AppTheme.textSecondary),
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: "My Child's Progress",
                  subtitle: '${student.name} • ${student.className}',
                ),
                const SizedBox(height: 24),
                _buildProgressCards(),
                const SizedBox(height: 24),
                _buildSubjectGrades(),
                const SizedBox(height: 24),
                _buildAttendanceSummary(),
              ],
            );
          },
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(
            child: Text('Error loading child: $err'),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressCards() {
    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 600 ? 3 : 1;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.8,
        children: const [
          _ProgressCard(label: 'Attendance', value: '88%', icon: Icons.how_to_reg_rounded, color: AppTheme.accent, delay: 0),
          _ProgressCard(label: 'Overall Grade', value: 'A', icon: Icons.star_rounded, color: AppTheme.primary, delay: 100),
          _ProgressCard(label: 'Rank in Class', value: '#4', icon: Icons.emoji_events_rounded, color: AppTheme.warning, delay: 200),
        ],
      );
    });
  }

  Widget _buildSubjectGrades() {
    final subjects = [
      ('English', 90, AppTheme.primary),
      ('Mathematics', 92, AppTheme.accent),
      ('Science Activity', 88, const Color(0xFF8B5CF6)),
      ('Art & Craft', 96, AppTheme.secondary),
      ('Physical Ed', 85, AppTheme.warning),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Subject-wise Performance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...subjects.asMap().entries.map((e) {
            final s = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(s.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                      Text('${s.$2}/100', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: s.$3)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: s.$2 / 100,
                    backgroundColor: s.$3.withOpacity(0.1),
                    valueColor: AlwaysStoppedAnimation(s.$3),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildAttendanceSummary() {
    final months = [
      ('June', 18, 20),
      ('July', 20, 22),
      ('August', 16, 20),
      ('September', 19, 20),
      ('October', 17, 21),
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monthly Attendance', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...months.map((m) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(width: 80, child: Text(m.$1, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
                Expanded(
                  child: LinearProgressIndicator(
                    value: m.$2 / m.$3,
                    backgroundColor: AppTheme.accent.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 10),
                Text('${m.$2}/${m.$3}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          )),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms);
  }
}

class _ProgressCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final int delay;
  const _ProgressCard({required this.label, required this.value, required this.icon, required this.color, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
              Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: delay)).fadeIn().slideY(begin: 0.1);
  }
}
