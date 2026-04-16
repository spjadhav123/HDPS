import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';
import '../../core/models/teacher_model.dart';
import '../../core/providers/teacher_provider.dart';
import 'package:excel/excel.dart' as excel_pkg;
import 'package:share_plus/share_plus.dart';
import 'dart:typed_data';

class TeachersScreen extends ConsumerStatefulWidget {
  const TeachersScreen({super.key});

  @override
  ConsumerState<TeachersScreen> createState() => _TeachersScreenState();
}

class _TeachersScreenState extends ConsumerState<TeachersScreen> {
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
            PageHeader(
              title: 'Teachers & Staff',
              subtitle: teachersAsync.maybeWhen(
                data: (t) => '${t.length} staff members',
                orElse: () => 'Staff Management',
              ),
              action: Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _exportTeachers(ref),
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: const Text('Export List'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: () => _showAddStaffDialog(context),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Staff'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: teachersAsync.when(
                data: (teachers) {
                  if (teachers.isEmpty) {
                    return const Center(child: Text('No staff members found. Add one to get started.'));
                  }
                  return LayoutBuilder(builder: (ctx, constraints) {
                    final cols = constraints.maxWidth > 800 ? 3 : constraints.maxWidth > 500 ? 2 : 1;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: teachers.length,
                      itemBuilder: (ctx, i) => _TeacherCard(teacher: teachers[i], index: i),
                    );
                  });
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

  void _showAddStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final classController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final qualController = TextEditingController();
    final expController = TextEditingController();
    DateTime joiningDate = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add New Staff Member'),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Full Name'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: subjectController,
                          decoration: const InputDecoration(labelText: 'Subject/Role'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: classController,
                          decoration: const InputDecoration(labelText: 'Class (e.g. Jr. KG)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: emailController,
                          decoration: const InputDecoration(labelText: 'Email Address'),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneController,
                          decoration: const InputDecoration(labelText: 'Phone Number'),
                          keyboardType: TextInputType.phone,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: qualController,
                          decoration: const InputDecoration(labelText: 'Qualification'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: expController,
                          decoration: const InputDecoration(labelText: 'Experience (e.g. 5 yrs)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ListTile(
                    title: const Text('Joining Date', style: TextStyle(fontSize: 14)),
                    subtitle: Text(DateFormat('dd MMM yyyy').format(joiningDate)),
                    trailing: const Icon(Icons.calendar_today_rounded, size: 20),
                    onTap: () async {
                      final d = await showDatePicker(
                        context: builderContext,
                        initialDate: joiningDate,
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (d != null) setDialogState(() => joiningDate = d);
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
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;
                      
                      setDialogState(() => isSaving = true);
                      
                      try {
                        final teacher = Teacher(
                          id: '',
                          name: nameController.text.trim(),
                          subject: subjectController.text.trim(),
                          className: classController.text.trim(),
                          email: emailController.text.trim(),
                          phone: phoneController.text.trim(),
                          qualification: qualController.text.trim(),
                          experience: expController.text.trim(),
                          status: 'Active',
                          joiningDate: joiningDate,
                          createdAt: DateTime.now(),
                        );
                        
                        await ref.read(teacherRepositoryProvider).addTeacher(teacher);
                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Staff member added successfully')),
                          );
                        }
                      } catch (e) {
                        if (builderContext.mounted) {
                          setDialogState(() => isSaving = false);
                          ScaffoldMessenger.of(builderContext).showSnackBar(
                            SnackBar(content: Text('Error adding staff: $e')),
                          );
                        }
                      }
                    },
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Add Staff'),
            ),
          ],
        ),
      ),
    );
  }

  void _exportTeachers(WidgetRef ref) async {
    final teachersList = await ref.read(teacherRepositoryProvider).getAllTeachersFuture();
    if (teachersList.isEmpty) {
      if (mounted) {
        AppToast.show(context, message: 'No staff members to export', type: ToastType.warning);
      }
      return;
    }

    try {
      if (mounted) {
        AppToast.show(context, message: 'Generating Excel file...', type: ToastType.info);
      }
      
      final excel = excel_pkg.Excel.createExcel();
      final sheet = excel['Teachers List'];
      excel.setDefaultSheet('Teachers List');
      
      if (excel['Sheet1'] != null && excel.tables.keys.length > 1) {
        excel.delete('Sheet1');
      }

      sheet.appendRow([
        excel_pkg.TextCellValue('ID'),
        excel_pkg.TextCellValue('Name'),
        excel_pkg.TextCellValue('Role/Subject'),
        excel_pkg.TextCellValue('Class'),
        excel_pkg.TextCellValue('Email'),
        excel_pkg.TextCellValue('Phone'),
        excel_pkg.TextCellValue('Qualification'),
        excel_pkg.TextCellValue('Experience'),
        excel_pkg.TextCellValue('Joining Date'),
      ]);

      for (var t in teachersList) {
        sheet.appendRow([
          excel_pkg.TextCellValue(t.id),
          excel_pkg.TextCellValue(t.name),
          excel_pkg.TextCellValue(t.subject),
          excel_pkg.TextCellValue(t.className),
          excel_pkg.TextCellValue(t.email),
          excel_pkg.TextCellValue(t.phone),
          excel_pkg.TextCellValue(t.qualification),
          excel_pkg.TextCellValue(t.experience),
          excel_pkg.TextCellValue(DateFormat('yyyy-MM-dd').format(t.joiningDate)),
        ]);
      }

      final fileBytes = excel.encode();
      if (fileBytes != null) {
        final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
        await Share.shareXFiles(
          [XFile.fromData(
            Uint8List.fromList(fileBytes),
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
            name: 'Teachers_List_$dateStr.xlsx'
          )],
          text: 'Preschool Teachers Export',
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Export failed: $e', type: ToastType.error);
      }
    }
  }
}

class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final int index;
  const _TeacherCard({required this.teacher, required this.index});

  @override
  Widget build(BuildContext context) {
    final isOnLeave = teacher.status == 'On Leave';
    final statusColor = isOnLeave ? AppTheme.warning : AppTheme.accent;
    final colors = [AppTheme.primary, AppTheme.accent, AppTheme.secondary, AppTheme.warning];
    final color = colors[index % colors.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Text(
              teacher.name.split(' ').where((s) => s.isNotEmpty).map((p) => p[0]).take(2).join(),
              style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(teacher.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13), overflow: TextOverflow.ellipsis),
                Text('${teacher.subject} • ${teacher.className}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary), overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(teacher.status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                    ),
                    const SizedBox(width: 6),
                    Text(teacher.experience, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}
