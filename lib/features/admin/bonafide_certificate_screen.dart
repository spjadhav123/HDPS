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
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';

class BonafideCertificateScreen extends ConsumerStatefulWidget {
  const BonafideCertificateScreen({super.key});

  @override
  ConsumerState<BonafideCertificateScreen> createState() => _BonafideCertificateScreenState();
}

class _BonafideCertificateScreenState extends ConsumerState<BonafideCertificateScreen> {
  String _search = '';
  Student? _selectedStudent;

  List<Student> _applyFilters(List<Student> students) {
    if (_search.isEmpty) return students;
    return students.where((s) => s.name.toLowerCase().contains(_search.toLowerCase())).toList();
  }

  Future<void> _generateAndPrintCertificate(Student student) async {
    final pdf = pw.Document();

    final dateStr = DateFormat('dd MMM yyyy').format(DateTime.now());

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
                  'BONAFIDE CERTIFICATE',
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
                  text: 'This is to certify that Master/Miss ${student.name}, '
                      'son/daughter of ${student.parent}, is a bonafide student of our school '
                      'currently studying in class ${student.className} for the academic year ${DateTime.now().year}-${DateTime.now().year + 1}.',
                  style: const pw.TextStyle(fontSize: 16, lineSpacing: 5),
                ),
                pw.SizedBox(height: 24),
                pw.Paragraph(
                  text: 'To the best of our knowledge and school records, their date of birth is recorded as per '
                      'the admission documents. Their behavior and conduct have been good during their '
                      'time at the school.',
                  style: const pw.TextStyle(fontSize: 16, lineSpacing: 5),
                ),
                pw.SizedBox(height: 24),
                pw.Paragraph(
                  text: 'This certificate is issued upon the request of the parent for their personal reference.',
                  style: const pw.TextStyle(fontSize: 16, lineSpacing: 5),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
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
      name: 'Bonafide_${student.name.replaceAll(' ', '_')}',
    );
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
            const PageHeader(
              title: 'Bonafide Certificate',
              subtitle: 'Search for a student to generate a bonafide certificate',
            ),
            const SizedBox(height: 20),
            
            // Search Box and Selected Student View side by side on large, stacked on small
            Expanded(
              child: ResponsiveLayout.isMobile(context)
                  ? Column(
                      children: [
                        Expanded(child: _buildSearchAndList(studentsAsync)),
                        if (_selectedStudent != null) ...[
                          const SizedBox(height: 16),
                          Expanded(child: _buildCertificatePreview(_selectedStudent!)),
                        ],
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 1, child: _buildSearchAndList(studentsAsync)),
                        const SizedBox(width: 24),
                        Expanded(
                          flex: 1,
                          child: _selectedStudent == null
                              ? _buildEmptyState()
                              : _buildCertificatePreview(_selectedStudent!),
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
          Icon(Icons.document_scanner_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Select a student to view details\nand generate certificate',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndList(AsyncValue<List<Student>> studentsAsync) {
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
                hintText: 'Search students by name...',
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
            child: studentsAsync.when(
              data: (students) {
                final filtered = _applyFilters(students);
                if (filtered.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }
                return ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                  itemBuilder: (context, index) {
                    final student = filtered[index];
                    final isSelected = _selectedStudent?.id == student.id;
                    return ListTile(
                      title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${student.className} • ${student.parent}'),
                      leading: CircleAvatar(
                        backgroundColor: isSelected ? AppTheme.primary : AppTheme.primary.withAlpha(38),
                        child: Text(
                          student.name.isNotEmpty ? student.name[0] : '?',
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
                          _selectedStudent = student;
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

  Widget _buildCertificatePreview(Student student) {
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
          const Text('Certificate Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          _buildDetailRow('Student Name', student.name),
          _buildDetailRow('Class', student.className),
          _buildDetailRow('Parent Name', student.parent),
          _buildDetailRow('Contact', student.phone),
          _buildDetailRow('Status', student.status),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _generateAndPrintCertificate(student),
              icon: const Icon(Icons.print_rounded),
              label: const Text('Generate & Print Certificate'),
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
