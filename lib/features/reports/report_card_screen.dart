// lib/features/reports/report_card_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/report_card_model.dart';
import '../../core/providers/report_card_provider.dart';
import '../../core/providers/student_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/empty_state.dart';
import '../../shared/widgets/app_card.dart';

class ReportCardScreen extends ConsumerWidget {
  const ReportCardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final childAsync = ref.watch(parentChildStudentProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const PageHeader(
              title: 'Academic Reports',
              subtitle: 'Digital report cards and performance tracking',
            ),
            const SizedBox(height: 20),
            Expanded(
              child: childAsync.when(
                data: (student) {
                  if (student == null) {
                    return const EmptyState(
                      emoji: '🎓',
                      title: 'No Student Found',
                      subtitle: 'Please contact admin to link your child to this account.',
                    );
                  }
                  return _ReportCardList(studentId: student.id);
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

class _ReportCardList extends ConsumerWidget {
  final String studentId;
  const _ReportCardList({required this.studentId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(studentReportCardsProvider(studentId));

    return reportsAsync.when(
      data: (reports) {
        if (reports.isEmpty) {
          return const EmptyState(
            emoji: '📝',
            title: 'No Reports Yet',
            subtitle: 'Academic reports will appear here once published by the teacher.',
          );
        }

        return ListView.builder(
          itemCount: reports.length,
          itemBuilder: (ctx, i) => _ReportCardTile(report: reports[i]),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }
}

class _ReportCardTile extends StatelessWidget {
  final ReportCard report;
  const _ReportCardTile({required this.report});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: AppCard(
        child: ExpansionTile(
          title: Text('${report.term} - ${report.academicYear}',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          subtitle: Text('Status: ${report.status} • Marks: ${report.totalMarks}/${report.maxMarks}'),
          leading: const Icon(Icons.assignment_rounded, color: AppTheme.primary),
          tilePadding: EdgeInsets.zero,
          children: [
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Subject-wise Performance', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  ...report.grades.map((g) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(g.subject)),
                            Text('${g.marks}/${g.maxMarks}', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getGradeColor(g.grade).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(g.grade, style: TextStyle(color: _getGradeColor(g.grade), fontWeight: FontWeight.bold, fontSize: 12)),
                            ),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  const Text('Teacher Remarks', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(report.teacherRemarks, style: const TextStyle(color: AppTheme.textSecondary, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    if (grade.startsWith('A')) return Colors.green;
    if (grade.startsWith('B')) return Colors.blue;
    if (grade.startsWith('C')) return Colors.orange;
    return Colors.red;
  }
}
