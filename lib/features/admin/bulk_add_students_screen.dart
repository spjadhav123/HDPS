// lib/features/admin/bulk_add_students_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'dart:convert';
import 'dart:typed_data';
import '../../core/theme/app_theme.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_card.dart';

class _PreviewRow {
  Student student;
  bool isValid;
  String errorMessage;
  
  _PreviewRow(this.student, {this.isValid = true, this.errorMessage = ''});
}

class BulkAddStudentsScreen extends ConsumerStatefulWidget {
  const BulkAddStudentsScreen({super.key});

  @override
  ConsumerState<BulkAddStudentsScreen> createState() => _BulkAddStudentsScreenState();
}

class _BulkAddStudentsScreenState extends ConsumerState<BulkAddStudentsScreen> {
  List<_PreviewRow> _parsedRows = [];
  bool _isProcessing = false;
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _error;
  List<ParentCredentials> _generatedCredentials = [];

  double _calculateFees(String clz) {
    if (clz.contains('Playgroup')) return 12000;
    if (clz.contains('Nursery')) return 15000;
    if (clz.contains('Jr')) return 16000;
    if (clz.contains('Sr')) return 17000;
    return 12000;
  }
  
  void _downloadTemplate() {
    // Create CSV template with sample data
    final headers = ['Student Name', 'Aadhaar Number', 'Parent Name', 'Parent Email', 'Phone Number', 'Class'];
    
    // Sample data rows
    final sampleData = [
      ['John Doe', '123456789012', 'Jane Doe', 'jane.doe@example.com', '9876543210', 'Nursery'],
      ['Alice Smith', '234567890123', 'Bob Smith', 'bob.smith@example.com', '8765432109', 'Jr KG'],
      ['Charlie Brown', '345678901234', 'Lucy Brown', 'lucy.brown@example.com', '7654321098', 'Sr KG'],
    ];
    
    // Combine headers and sample data
    final csvData = [headers, ...sampleData];
    
    // Convert to CSV string manually
    final csvString = csvData.map((row) => row.map((cell) => '"$cell"').join(',')).join('\n');
    
    // Share the CSV file
    Share.shareXFiles(
      [XFile.fromData(
        Uint8List.fromList(utf8.encode(csvString)),
        mimeType: 'text/csv',
        name: 'student_import_template.csv'
      )],
      text: 'Student Import Template',
    );
  }

  Future<void> _pickAndParseFile() async {
    setState(() {
      _isProcessing = true;
      _error = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isProcessing = false);
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;
      if (bytes == null) {
        setState(() {
          _isProcessing = false;
          _error = 'Could not read file data.';
        });
        return;
      }

      final List<_PreviewRow> rows = [];

      if (file.extension == 'csv' || file.name.endsWith('.csv')) {
        final content = String.fromCharCodes(bytes);
        await _parseTextData(content, rows);
      } else {
        final excel = excel_pkg.Excel.decodeBytes(bytes);
        for (var table in excel.tables.keys) {
          final sheet = excel.tables[table]!;
          // Assume row 0 is header
          bool isHeader = true;
          for (var i = 0; i < sheet.maxRows; i++) {
            final row = sheet.rows[i];
            if (row.length < 5) continue;

            final name = row[0]?.value?.toString().trim() ?? '';
            final aadhaar = row[1]?.value?.toString().trim() ?? '';
            final parent = row[2]?.value?.toString().trim() ?? '';
            final email = row[3]?.value?.toString().trim() ?? '';
            final phone = row[4]?.value?.toString().trim() ?? '';
            final className = row.length > 5 ? row[5]?.value?.toString().trim() ?? 'Playgroup' : 'Playgroup';

            if (isHeader) {
               if (name.toLowerCase().contains('name') || name.toLowerCase().contains('full')) {
                 isHeader = false;
                 continue;
               }
               isHeader = false;
            }

            if (name.isEmpty && aadhaar.isEmpty) continue;

            await _addPreviewRow(name, aadhaar, parent, email, phone, className, rows);
          }
        }
      }

      setState(() {
        _parsedRows = rows;
        _isProcessing = false;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _error = 'Error processing file: $e';
      });
    }
  }

  Future<void> _parseTextData(String input, List<_PreviewRow> rows) async {
    final lines = input.split('\n');
    bool isHeader = true;
    for (var line in lines) {
      if (line.trim().isEmpty) continue;
      final parts = line.contains('\t') ? line.split('\t') : line.split(',');
      
      if (isHeader) {
        if (parts[0].trim().toLowerCase().contains('name') || parts[0].trim().toLowerCase().contains('full')) {
          isHeader = false;
          continue;
        }
        isHeader = false;
      }
      
      if (parts.length < 5) continue;

      final name = parts[0].trim();
      final aadhaar = parts[1].trim();
      final parent = parts[2].trim();
      final email = parts[3].trim();
      final phone = parts[4].trim();
      final className = parts.length > 5 ? parts[5].trim() : 'Playgroup';

      if (name.isEmpty && aadhaar.isEmpty) continue;

      await _addPreviewRow(name, aadhaar, parent, email, phone, className, rows);
    }
  }
  
  Future<void> _addPreviewRow(String name, String aadhaar, String parent, String email, String phone, String className, List<_PreviewRow> rows) async {
    final studentCode = await ref.read(studentRepositoryProvider).generateStudentCode(className, name, aadhaar);
    
    // Validate
    List<String> errors = [];
    if (name.isEmpty) errors.add("Name required");
    if (aadhaar.isEmpty) {
      errors.add("Aadhaar required");
    } else if (aadhaar.length != 12 || int.tryParse(aadhaar) == null) errors.add("Aadhaar must be 12 digits");
    if (phone.isEmpty) {
      errors.add("Phone required");
    } else if (phone.length < 10) errors.add("Invalid phone");
    
    final student = Student(
      id: '',
      studentCode: studentCode,
      name: name,
      className: className.isEmpty ? 'Playgroup' : className,
      aadhaarNumber: aadhaar,
      parent: parent,
      parentEmail: email,
      phone: phone,
      feesPaid: 0,
      feesTotal: _calculateFees(className),
      status: 'Active',
      createdAt: DateTime.now(),
    );
    
    rows.add(_PreviewRow(
      student,
      isValid: errors.isEmpty,
      errorMessage: errors.join(", "),
    ));
  }

  Future<void> _uploadStudents() async {
    final validRows = _parsedRows.where((r) => r.isValid).toList();
    if (validRows.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });
    
    int successCount = 0;
    int failCount = 0;
    
    try {
      final existingStudents = await ref.read(studentRepositoryProvider).getAllStudentsFuture();
      final existingAadhaars = existingStudents.map((e) => e.aadhaarNumber).toSet();
      
      final List<ParentCredentials> allCreds = [];
      for (int i = 0; i < validRows.length; i++) {
        final row = validRows[i];
        try {
          if (existingAadhaars.contains(row.student.aadhaarNumber)) {
            failCount++;
            continue;
          }
          final creds = await ref.read(studentRepositoryProvider).addStudent(row.student);
          allCreds.add(creds);
          existingAadhaars.add(row.student.aadhaarNumber); // Prevent duplicates within batch
          successCount++;
        } catch (e) {
          failCount++;
        }
        setState(() {
          _uploadProgress = (i + 1) / validRows.length;
          _generatedCredentials = allCreds;
        });
      }
      
      if (mounted) {
        _showSummaryDialog(validRows.length, successCount, failCount);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  void _showSummaryDialog(int total, int success, int failed) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Upload Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total Processed: $total', style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20), const SizedBox(width: 8), Text('Successful: $success', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600, fontSize: 16))]),
            const SizedBox(height: 8),
            Row(children: [const Icon(Icons.error_rounded, color: Colors.red, size: 20), const SizedBox(width: 8), Text('Failed/Duplicates: $failed', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 16))]),
            if (success > 0) ...[
              const SizedBox(height: 20),
              const Text('Parent login credentials have been generated for all successful entries.', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: _downloadCredentials,
                icon: const Icon(Icons.vpn_key_rounded, size: 18),
                label: const Text('Download Credentials CSV'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to students screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent, foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      )
    );
  }

  void _downloadCredentials() {
    if (_generatedCredentials.isEmpty) return;

    const header = "Student_Name,Username,Password\n";
    final rows = _generatedCredentials.map((c) => '"${c.studentName}","${c.username}","${c.password}"').join('\n');
    final csv = "$header$rows";

    // Share the credentials CSV file
    Share.shareXFiles(
      [XFile.fromData(
        Uint8List.fromList(utf8.encode(csv)),
        mimeType: 'text/csv',
        name: 'parent_credentials.csv'
      )],
      text: 'Parent Login Credentials',
    );
  }

  void _editRow(int index) {
    final row = _parsedRows[index];
    final ctrlName = TextEditingController(text: row.student.name);
    final ctrlAadhaar = TextEditingController(text: row.student.aadhaarNumber);
    final ctrlPhone = TextEditingController(text: row.student.phone);
    final ctrlEmail = TextEditingController(text: row.student.parentEmail);
    final ctrlClass = TextEditingController(text: row.student.className);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Student Row'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: ctrlName, decoration: const InputDecoration(labelText: 'Name')),
              TextField(controller: ctrlAadhaar, decoration: const InputDecoration(labelText: 'Aadhaar')),
              TextField(controller: ctrlPhone, decoration: const InputDecoration(labelText: 'Phone')),
              TextField(controller: ctrlEmail, decoration: const InputDecoration(labelText: 'Email')),
              TextField(controller: ctrlClass, decoration: const InputDecoration(labelText: 'Class')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              int errors = 0;
              List<String> errText = [];
              if (ctrlName.text.isEmpty) { errors++; errText.add("Name required"); }
              if (ctrlAadhaar.text.isEmpty || ctrlAadhaar.text.length != 12 || int.tryParse(ctrlAadhaar.text) == null) { errors++; errText.add("Aadhaar must be 12 digits"); }
              if (ctrlPhone.text.isEmpty || ctrlPhone.text.length < 10) { errors++; errText.add("Invalid phone"); }
              
              row.student = row.student.copyWith(
                name: ctrlName.text,
                aadhaarNumber: ctrlAadhaar.text,
                phone: ctrlPhone.text,
                parentEmail: ctrlEmail.text,
                className: ctrlClass.text,
              );
              row.isValid = errors == 0;
              row.errorMessage = errText.join(", ");
              setState(() {});
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
            child: const Text('Save Changes', style: TextStyle(color: Colors.white)),
          )
        ],
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    int validCount = _parsedRows.where((r) => r.isValid).length;
    int invalidCount = _parsedRows.length - validCount;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            PageHeader(
              title: 'Bulk Add Students',
              subtitle: 'Upload Excel/CSV to import students',
              action: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: _downloadTemplate,
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Download Sample Template'),
                    style: OutlinedButton.styleFrom(backgroundColor: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_isUploading)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.accent.withOpacity(0.5)),
                  boxShadow: [
                    BoxShadow(color: AppTheme.accent.withOpacity(0.1), blurRadius: 10, spreadRadius: 2)
                  ]
                ),
                child: Column(
                  children: [
                    const Text('Importing students, please wait...', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(value: _uploadProgress, color: AppTheme.accent, minHeight: 8, borderRadius: BorderRadius.circular(4)),
                    const SizedBox(height: 8),
                    Text('${(_uploadProgress * 100).toStringAsFixed(0)}% Completed', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            Expanded(
              child: Column(
                children: [
                  AppCard(
                    title: '1. Upload Data File',
                    subtitle: 'Supports .csv, .xls, .xlsx files',
                    trailing: ElevatedButton.icon(
                      onPressed: _isProcessing || _isUploading ? null : _pickAndParseFile,
                      icon: const Icon(Icons.upload_file_rounded),
                      label: _isProcessing ? const Text('Processing...') : const Text('Select File'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary.withOpacity(0.1),
                        foregroundColor: AppTheme.primary,
                        elevation: 0,
                      ),
                    ),
                    child: _error != null
                      ? Text(_error!, style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600))
                      : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: AppCard(
                      title: '2. Preview & Edit Data',
                      subtitle: '${_parsedRows.length} total • $validCount valid • $invalidCount invalid',
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (invalidCount > 0)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _parsedRows.removeWhere((r) => !r.isValid);
                                });
                              },
                              icon: const Icon(Icons.delete_sweep, color: Colors.red),
                              label: const Text('Remove Invalid', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                            ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: validCount == 0 || _isUploading ? null : _uploadStudents,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.accent, 
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)
                            ),
                            child: Text('Confirm Import ($validCount)'),
                          ),
                        ],
                      ),
                      child: _parsedRows.isEmpty
                          ? const Center(child: Text('No data loaded. Please upload a file to preview.', style: TextStyle(color: Colors.grey, fontSize: 16)))
                          : _buildPreviewTable(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.background,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Student Name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Aadhaar', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary))),
                Expanded(flex: 3, child: Text('Status/Error', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary))),
                SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: _parsedRows.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade200),
              itemBuilder: (context, i) {
                final row = _parsedRows[i];
                final bgColor = row.isValid ? Colors.white : Colors.red.shade50;
                
                return Container(
                  color: bgColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(flex: 3, child: Text(row.student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14))),
                      Expanded(flex: 2, child: Text(row.student.aadhaarNumber, style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(row.student.className, style: const TextStyle(fontSize: 13))),
                      Expanded(flex: 2, child: Text(row.student.phone, style: const TextStyle(fontSize: 13))),
                      Expanded(
                        flex: 3,
                        child: row.isValid 
                          ? const Row(children: [Icon(Icons.check_circle_rounded, color: Colors.green, size: 16), SizedBox(width: 4), Text('Ready', style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold))])
                          : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16), const SizedBox(width: 4), Expanded(child: Text(row.errorMessage, style: const TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.bold)))]),
                      ),
                      SizedBox(
                        width: 80,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: () => _editRow(i),
                              tooltip: 'Edit Row',
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                              constraints: const BoxConstraints(),
                              padding: const EdgeInsets.all(4),
                              onPressed: () => setState(() => _parsedRows.removeAt(i)),
                              tooltip: 'Remove Row',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
