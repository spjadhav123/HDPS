import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';
import '../../shared/widgets/responsive_layout.dart';
import '../../core/models/teacher_model.dart';
import '../../core/providers/teacher_provider.dart';

class ExperienceLetterScreen extends ConsumerStatefulWidget {
  const ExperienceLetterScreen({super.key});

  @override
  ConsumerState<ExperienceLetterScreen> createState() => _ExperienceLetterScreenState();
}

class _ExperienceLetterScreenState extends ConsumerState<ExperienceLetterScreen> {
  String _search = '';
  Teacher? _selectedTeacher;

  List<Teacher> _applyFilters(List<Teacher> teachers) {
    if (_search.isEmpty) return teachers;
    return teachers.where((t) => t.name.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  Future<void> _generateAndPrintCertificate(Teacher teacher) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());
    final joiningDateStr = DateFormat('dd MMM yyyy').format(teacher.joiningDate);

    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(32),
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.blue900, width: 4),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  'HUMPTY DUMPTY PRESCHOOL',
                  style: pw.TextStyle(
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '123 Education Lane, Learning City, State 400001',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.Text(
                  'Contact: +91 9876543210 | Email: info@hdpreschool.com',
                  style: const pw.TextStyle(fontSize: 12),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(thickness: 2, color: PdfColors.blue900),
                pw.SizedBox(height: 32),
                pw.Text(
                  'EXPERIENCE LETTER',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    decoration: pw.TextDecoration.underline,
                  ),
                ),
                pw.SizedBox(height: 32),
                pw.Container(
                  alignment: pw.Alignment.centerRight,
                  child: pw.Text('Date: $dateStr', style: const pw.TextStyle(fontSize: 14)),
                ),
                pw.SizedBox(height: 48),
                pw.Paragraph(
                  text: 'TO WHOMSOEVER IT MAY CONCERN',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 24),
                pw.Paragraph(
                  text: 'This is to certify that ${teacher.name} has worked in our institution as a '
                      '${teacher.subject} teacher. They joined us on $joiningDateStr and have been '
                      'an integral part of our faculty.',
                  style: const pw.TextStyle(fontSize: 16, lineSpacing: 5),
                ),
                pw.SizedBox(height: 24),
                pw.Paragraph(
                  text: 'During their tenure, we found their character, conduct, and professional '
                      'competence to be excellent. They demonstrated great dedication to their duties '
                      'and contributed positively to the preschool environment.',
                  style: const pw.TextStyle(fontSize: 16, lineSpacing: 5),
                ),
                pw.SizedBox(height: 24),
                pw.Paragraph(
                  text: 'We wish them all the best in their future endeavors.',
                  style: const pw.TextStyle(fontSize: 16, lineSpacing: 5),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.SizedBox(height: 40),
                        pw.Text('Date: $dateStr'),
                        pw.Text('Place: Learning City'),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: [
                        pw.Container(height: 40, width: 100), // Placeholder for signature
                        pw.Container(width: 150, child: pw.Divider()),
                        pw.Text('Principal\'s Signature', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        pw.Text('Humpty Dumpty Preschool'),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Experience_Letter_${teacher.name.replaceAll(' ', '_')}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final teachersAsync = ref.watch(teachersStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Experience Letter',
              subtitle: 'Search for a staff member to generate an experience letter',
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: ResponsiveLayout.isMobile(context)
                  ? Column(
                      children: [
                        Expanded(child: _buildSearchAndList(teachersAsync)),
                        if (_selectedTeacher != null) ...[
                          const SizedBox(height: 16),
                          Expanded(child: _buildLetterPreview(_selectedTeacher!)),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildSearchAndList(teachersAsync)),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _selectedTeacher == null
                              ? _buildEmptyState()
                              : _buildLetterPreview(_selectedTeacher!),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Select a teacher to view details\nand generate letter',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndList(AsyncValue<List<Teacher>> teachersAsync) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search staff by name...',
                prefixIcon: const Icon(Icons.search, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          ),
          Expanded(
            child: teachersAsync.when(
              data: (teachers) {
                final filtered = _applyFilters(teachers);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No staff found.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final teacher = filtered[index];
                    final isSelected = _selectedTeacher?.id == teacher.id;
                    return ListTile(
                      title: Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${teacher.subject} • ${teacher.experience}'),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppTheme.primary : AppTheme.primary.withAlpha(38),
                        child: Text(
                          teacher.name.isNotEmpty ? teacher.name[0] : '?',
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppTheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      selected: isSelected,
                      selectedTileColor: AppTheme.primary.withAlpha(15),
                      onTap: () {
                        setState(() {
                          _selectedTeacher = teacher;
                        });
                      },
                    );
                  },
                );
              },
              loading: () => const Center(child: SpinningLoader()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLetterPreview(Teacher teacher) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildDetailRow('Name', teacher.name),
          _buildDetailRow('Designation', teacher.subject),
          _buildDetailRow('Experience', teacher.experience),
          _buildDetailRow('Joining Date', DateFormat('dd MMM yyyy').format(teacher.joiningDate)),
          _buildDetailRow('Status', teacher.status),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateAndPrintCertificate(teacher),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Generate Experience Letter'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}
