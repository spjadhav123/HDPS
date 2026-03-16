// lib/features/teacher/gradebook_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/student_provider.dart';
import '../../core/models/student_model.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_card.dart';
import 'manage_report_cards_screen.dart';

class GradebookScreen extends ConsumerWidget {
  const GradebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Gradebook & Reports',
              subtitle: 'Manage student marks and publish digital report cards',
            ),
            const SizedBox(height: 24),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  if (students.isEmpty) {
                    return const Center(child: Text('No students found.'));
                  }
                  
                  // Simple grouping by class for teacher view
                  final classes = students.map((s) => s.className).toSet().toList()..sort();

                  return ListView.builder(
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final className = classes[index];
                      final classStudents = students.where((s) => s.className == className).toList()
                        ..sort((a, b) => a.name.compareTo(b.name));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                            child: Text(
                              className,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primary),
                            ),
                          ),
                          ...classStudents.map((student) => _StudentGradeTile(student: student)),
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StudentGradeTile extends StatelessWidget {
  final Student student;
  const _StudentGradeTile({required this.student});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(student.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
          ),
          title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('ID: ${student.studentCode}'),
          trailing: ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ManageReportCardsScreen(student: student)),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            ),
            child: const Text('Manage Report', style: TextStyle(fontSize: 12)),
          ),
        ),
      ),
    );
  }
}
