// lib/features/teacher/manage_report_cards_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/student_model.dart';
import '../../core/models/report_card_model.dart';
import '../../core/providers/report_card_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_card.dart';

class ManageReportCardsScreen extends ConsumerStatefulWidget {
  final Student student;
  const ManageReportCardsScreen({super.key, required this.student});

  @override
  ConsumerState<ManageReportCardsScreen> createState() => _ManageReportCardsScreenState();
}

class _ManageReportCardsScreenState extends ConsumerState<ManageReportCardsScreen> {
  final _termController = TextEditingController(text: 'Term 2');
  final _yearController = TextEditingController(text: '2025-26');
  final _remarksController = TextEditingController();
  
  final List<SubjectGrade> _grades = [
    SubjectGrade(subject: 'English', marks: 0, maxMarks: 100, grade: 'A'),
    SubjectGrade(subject: 'Mathematics', marks: 0, maxMarks: 100, grade: 'A'),
    SubjectGrade(subject: 'Environmental Science', marks: 0, maxMarks: 100, grade: 'A'),
    SubjectGrade(subject: 'Art & Craft', marks: 0, maxMarks: 50, grade: 'A'),
  ];

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(title: Text('Report Card: ${widget.student.name}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            AppCard(
              title: 'General Information',
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _termController,
                          decoration: const InputDecoration(labelText: 'Term (e.g. Term 2)'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _yearController,
                          decoration: const InputDecoration(labelText: 'Academic Year'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              title: 'Subject Grades',
              child: Column(
                children: [
                  ..._grades.asMap().entries.map((entry) {
                    final i = entry.key;
                    final g = entry.value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Expanded(flex: 3, child: Text(g.subject, style: const TextStyle(fontWeight: FontWeight.w600))),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              decoration: const InputDecoration(labelText: 'Marks'),
                              keyboardType: TextInputType.number,
                              onChanged: (v) {
                                final m = int.tryParse(v) ?? 0;
                                _grades[i] = g.copyWith(marks: m, grade: _calculateGrade(m, g.maxMarks));
                                setState(() {});
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text('/ ${g.maxMarks}'),
                          const SizedBox(width: 12),
                          Container(
                            width: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                _grades[i].grade,
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primary),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppCard(
              title: 'Teacher Remarks',
              child: TextField(
                controller: _remarksController,
                maxLines: 3,
                decoration: const InputDecoration(hintText: 'Enter overall performance remarks...'),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveReport,
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save & Publish Report Card'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateGrade(int marks, int max) {
    final pct = (marks / max) * 100;
    if (pct >= 90) return 'A+';
    if (pct >= 80) return 'A';
    if (pct >= 70) return 'B+';
    if (pct >= 60) return 'B';
    if (pct >= 50) return 'C';
    return 'D';
  }

  Future<void> _saveReport() async {
    setState(() => _isSaving = true);
    try {
      final totalMarks = _grades.fold<int>(0, (sum, g) => sum + g.marks);
      final totalMax = _grades.fold<int>(0, (sum, g) => sum + g.maxMarks);

      final report = ReportCard(
        id: '',
        studentId: widget.student.id,
        term: _termController.text.trim(),
        academicYear: _yearController.text.trim(),
        grades: _grades,
        totalMarks: totalMarks,
        maxMarks: totalMax,
        teacherRemarks: _remarksController.text.trim(),
        status: 'Published',
        createdAt: DateTime.now(),
      );

      await ref.read(reportCardRepositoryProvider).addReportCard(report);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report card published successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
