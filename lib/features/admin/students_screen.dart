import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';
import 'package:intl/intl.dart';

import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';

class StudentsScreen extends ConsumerStatefulWidget {
  const StudentsScreen({super.key});

  @override
  ConsumerState<StudentsScreen> createState() => _StudentsScreenState();
}

class _StudentsScreenState extends ConsumerState<StudentsScreen> {
  String _search = '';
  String _classFilter = 'All';

  List<Student> _applyFilters(List<Student> students) {
    return students.where((s) {
      final matchName = s.name.toLowerCase().contains(_search.toLowerCase());
      final matchClass = _classFilter == 'All' || s.className.startsWith(_classFilter);
      return matchName && matchClass;
    }).toList();
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
              title: 'Students',
              subtitle: studentsAsync.maybeWhen(
                data: (s) => '${s.length} students enrolled',
                orElse: () => 'Student Management',
              ),
              action: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _exportStudents(ref),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Export List'),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: () => context.push('/admin/students/bulk'),
                    icon: const Icon(Icons.group_add_rounded, size: 18),
                    label: const Text('Bulk Add'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () async {
                      AppToast.show(context, message: 'Rebuilding missing credentials...', type: ToastType.info);
                      await ref.read(studentRepositoryProvider).repairAllCredentials();
                      if (context.mounted) {
                        AppToast.show(context, message: 'All missing credentials regenerated!', type: ToastType.success);
                      }
                    },
                    icon: const Icon(Icons.build_circle_outlined, size: 18, color: Colors.white),
                    label: const Text('Repair Logins'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade600),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStudentDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Student'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildFilters(),
            const SizedBox(height: 16),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  final filtered = _applyFilters(students);
                  return _buildTable(filtered);
                },
                loading: () => const Padding(
                  padding: EdgeInsets.all(8),
                  child: ShimmerListView(itemCount: 6, itemHeight: 60),
                ),
                error: (err, _) => Center(child: Text('Error: $err')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: const InputDecoration(
              hintText: 'Search students...',
              prefixIcon: Icon(Icons.search, size: 20),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 12),
        DropdownButton<String>(
          value: _classFilter,
          onChanged: (v) => setState(() => _classFilter = v!),
          items: ['All', 'Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG']
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          underline: const SizedBox(),
        ),
      ],
    );
  }

  Widget _buildTable(List<Student> filtered) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        children: [
          _buildTableHeader(),
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (context, i) => _buildStudentRow(filtered[i], i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: const Row(
        children: [
          Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 2, child: Text('Class', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 3, child: Text('Parent', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 2, child: Text('Fees', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
          SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildStudentRow(Student student, int index) {
    return AnimatedListItem(
      index: index,
      child: _buildStudentRowContent(student, index),
    );
  }

  Widget _buildStudentRowContent(Student student, int index) {
    final statusColor = student.status == 'Active'
        ? AppTheme.accent
        : student.status == 'Pending'
            ? AppTheme.warning
            : AppTheme.secondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: AppTheme.primary.withAlpha(38),
                  child: Text(
                    student.name.isNotEmpty ? student.name[0] : '?',
                    style: const TextStyle(
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(student.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                      Text(
                          student.studentCode.isNotEmpty
                              ? student.studentCode
                              : (student.id.length > 8 ? student.id.substring(0, 8) : student.id),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(student.className,
                style: const TextStyle(fontSize: 13)),
          ),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.parent,
                    style: const TextStyle(fontSize: 12)),
                Text(student.phone,
                    style: const TextStyle(
                        fontSize: 11, color: AppTheme.textSecondary)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '₹${student.feesPaid.toStringAsFixed(0)} / ₹${student.feesTotal.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                AnimatedProgressBar(
                  value: student.feesTotal > 0 ? student.feesPaid / student.feesTotal : 0.0,
                  color: (student.feesTotal > 0 && student.feesPaid >= student.feesTotal)
                      ? AppTheme.accent
                      : AppTheme.warning,
                  height: 5,
                  duration: Duration(milliseconds: 600 + index * 60),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withAlpha(25),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                student.status,
                style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          SizedBox(
            width: 80,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.primary),
                  onPressed: () => _showEditStudentDialog(context, student),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Edit Student',
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                  onPressed: () => _confirmDelete(context, student),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete Student',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _exportStudents(WidgetRef ref) async {
    final studentsList = await ref.read(studentRepositoryProvider).getAllStudentsFuture();
    if (studentsList.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No students to export')));
      }
      return;
    }

    try {
      if (mounted) {
        AppToast.show(context, message: 'Generating Excel file...', type: ToastType.info);
      }
      
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Students List'];
      excel.setDefaultSheet('Students List');
      
      if (excel['Sheet1'] != null && excel.tables.keys.length > 1) {
        excel.delete('Sheet1');
      }

      sheet.appendRow([
        excel_pkg.TextCellValue('ID'),
        excel_pkg.TextCellValue('Registration Number'),
        excel_pkg.TextCellValue('Name'),
        excel_pkg.TextCellValue('Class'),
        excel_pkg.TextCellValue('Parent Name'),
        excel_pkg.TextCellValue('Parent Email'),
        excel_pkg.TextCellValue('Phone'),
        excel_pkg.TextCellValue('Fees Paid'),
        excel_pkg.TextCellValue('Fees Total'),
        excel_pkg.TextCellValue('Status'),
        excel_pkg.TextCellValue('Registration Date'),
      ]);

      for (var s in studentsList) {
        sheet.appendRow([
          excel_pkg.TextCellValue(s.id),
          excel_pkg.TextCellValue(s.studentCode),
          excel_pkg.TextCellValue(s.name),
          excel_pkg.TextCellValue(s.className),
          excel_pkg.TextCellValue(s.parent),
          excel_pkg.TextCellValue(s.parentEmail),
          excel_pkg.TextCellValue(s.phone),
          excel_pkg.DoubleCellValue(s.feesPaid),
          excel_pkg.DoubleCellValue(s.feesTotal),
          excel_pkg.TextCellValue(s.status),
          excel_pkg.TextCellValue(DateFormat('yyyy-MM-dd').format(s.createdAt)),
        ]);
      }

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
        await Share.shareXFiles(
          [XFile.fromData(
            Uint8List.fromList(fileBytes),
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'Students_List_$dateStr.xlsx'
          )],
          text: 'Preschool Students Export',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Export failed: $e', type: ToastType.error);
      }
    }
  }

  void _showAddStudentDialog(BuildContext context) {
    final nameController = TextEditingController();
    final parentController = TextEditingController();
    final parentEmailController = TextEditingController();
    final phoneController = TextEditingController();
    String selectedClass = 'Playgroup';
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Add New Student'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedFocusField(
                    controller: nameController,
                    labelText: 'Full Name',
                    hintText: 'Enter student\'s full name',
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFocusField(
                    controller: parentController,
                    labelText: 'Parent Name',
                    hintText: 'Father or Mother name',
                    prefixIcon: const Icon(Icons.family_restroom_outlined, size: 18),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFocusField(
                    controller: parentEmailController,
                    labelText: 'Parent Email',
                    hintText: 'Email parent will use to sign in',
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFocusField(
                    controller: phoneController,
                    labelText: 'Phone',
                    hintText: 'Contact number',
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(
                      labelText: 'Class',
                      prefixIcon: Icon(Icons.school_outlined, size: 18),
                    ),
                    items: ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setDialogState(() => selectedClass = v);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            AppButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) {
                        AppToast.show(
                          builderContext,
                          message: 'Please enter student name',
                          type: ToastType.warning,
                        );
                        return;
                      }

                      setDialogState(() => isSaving = true);

                      try {
                        final className = selectedClass;
                        final studentName = nameController.text.trim();
                        final phoneNumber = phoneController.text.trim();

                        final studentCode = await ref
                            .read(studentRepositoryProvider)
                            .generateStudentCode(className, studentName, phoneNumber);

                        double calculateFees(String selected) {
                          if (selected == 'Playgroup') return 12000;
                          if (selected == 'Nursery') return 15000;
                          if (selected == 'Jr. KG') return 16000;
                          if (selected == 'Sr. KG') return 17000;
                          return 12000;
                        }

                        final student = Student(
                          id: '',
                          studentCode: studentCode,
                          name: studentName,
                          className: className,
                          parent: parentController.text.trim(),
                          parentEmail: parentEmailController.text.trim(),
                          phone: phoneController.text.trim(),
                          feesPaid: 0,
                          feesTotal: calculateFees(className),
                          status: 'Active',
                          createdAt: DateTime.now(),
                        );

                        final creds = await ref.read(studentRepositoryProvider).addStudent(student);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          _showCredentialsConfirmation(context, creds);
                        }
                      } catch (e) {
                        if (builderContext.mounted) {
                          setDialogState(() => isSaving = false);
                          AppToast.show(
                            builderContext,
                            message: 'Error adding student: $e',
                            type: ToastType.error,
                          );
                        }
                      }
                    },
              isLoading: isSaving,
              child: const Text('Add Student'),
            ),
          ],
        ),
      ),
    );
  }
  void _showCredentialsConfirmation(BuildContext context, ParentCredentials creds) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.green, size: 28),
            SizedBox(width: 12),
            Text('Student Added!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Credentials generated for ${creds.studentName}\'s parent:'),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  _buildCredentialRow('Username', creds.username, Icons.person_outline),
                  const Divider(height: 24),
                  _buildCredentialRow('Password', creds.password, Icons.lock_outline),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Please share these credentials with the parent. They will be required to change their password on first login.',
              style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Close & Finish'),
          ),
        ],
      ),
    );
  }

  Widget _buildCredentialRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1.1)),
          ],
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.copy_rounded, size: 18),
          onPressed: () {
            // Copy to clipboard functionality removed for cross-platform compatibility
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copy functionality is not available in this version')),
            );
          },
        ),
      ],
    );
  }
  void _showEditStudentDialog(BuildContext context, Student student) {
    final nameController = TextEditingController(text: student.name);
    final parentController = TextEditingController(text: student.parent);
    final parentEmailController = TextEditingController(text: student.parentEmail);
    final phoneController = TextEditingController(text: student.phone);
    String selectedClass = student.className;
    String selectedStatus = student.status;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Edit Student: ${student.name}'),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedFocusField(
                    controller: nameController,
                    labelText: 'Full Name',
                    prefixIcon: const Icon(Icons.person_outline, size: 18),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFocusField(
                    controller: parentController,
                    labelText: 'Parent Name',
                    prefixIcon: const Icon(Icons.family_restroom_outlined, size: 18),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFocusField(
                    controller: parentEmailController,
                    labelText: 'Parent Email',
                    prefixIcon: const Icon(Icons.email_outlined, size: 18),
                  ),
                  const SizedBox(height: 16),
                  AnimatedFocusField(
                    controller: phoneController,
                    labelText: 'Phone',
                    prefixIcon: const Icon(Icons.phone_outlined, size: 18),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedClass,
                    decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.school_outlined, size: 18)),
                    items: ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => v != null ? setDialogState(() => selectedClass = v) : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
              value: selectedStatus,
                    decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.info_outline_rounded, size: 18)),
                    items: ['Active', 'Pending', 'Inactive'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (v) => v != null ? setDialogState(() => selectedStatus = v) : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            AppButton(
              onPressed: isSaving ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  final updatedStudent = student.copyWith(
                    name: nameController.text.trim(),
                    parent: parentController.text.trim(),
                    parentEmail: parentEmailController.text.trim(),
                    phone: phoneController.text.trim(),
                    className: selectedClass,
                    status: selectedStatus,
                  );
                  
                  await ref.read(studentRepositoryProvider).updateStudent(student, updatedStudent);
                  if (dialogContext.mounted) {
                    Navigator.pop(dialogContext);
                    AppToast.show(context, message: 'Student updated successfully!', type: ToastType.success);
                  }
                } catch (e) {
                  if (builderContext.mounted) {
                    setDialogState(() => isSaving = false);
                    AppToast.show(builderContext, message: 'Update failed: $e', type: ToastType.error);
                  }
                }
              },
              isLoading: isSaving,
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Student student) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Student'),
        content: Text('Are you sure you want to delete ${student.name}? This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(studentRepositoryProvider).deleteStudent(student.id);
              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                AppToast.show(context, message: 'Student deleted.', type: ToastType.success);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
