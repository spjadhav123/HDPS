import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

// Available classes for the dropdown
const _classList = ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG', 'Not Assigned'];

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
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, size: 64, color: Colors.grey.shade300),
                          const SizedBox(height: 16),
                          const Text('No staff members found.',
                              style: TextStyle(color: AppTheme.textSecondary)),
                          const SizedBox(height: 8),
                          ElevatedButton.icon(
                            onPressed: () => _showAddStaffDialog(context),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add First Staff Member'),
                          ),
                        ],
                      ),
                    );
                  }
                  return LayoutBuilder(builder: (ctx, constraints) {
                    final cols = constraints.maxWidth > 800
                        ? 3
                        : constraints.maxWidth > 500
                            ? 2
                            : 1;
                    return GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 2.2,
                      ),
                      itemCount: teachers.length,
                      itemBuilder: (ctx, i) => _TeacherCard(
                        teacher: teachers[i],
                        index: i,
                        onTap: () => _showStaffDetailDialog(context, teachers[i]),
                      ),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Add Staff Dialog
  // ─────────────────────────────────────────────────────────────────────────
  void _showAddStaffDialog(BuildContext context) {
    final nameController = TextEditingController();
    final subjectController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final qualController = TextEditingController();
    final expController = TextEditingController();
    String? selectedClass = _classList.first;
    DateTime joiningDate = DateTime.now();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (builderContext, setDialogState) {
          // Derive credentials preview from current field values
          final nameTrimmed = nameController.text.trim();
          final phoneTrimmed = phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
          final previewUsername = nameTrimmed.isEmpty ? '—' : nameTrimmed;
          final previewPassword = phoneTrimmed.length >= 10
              ? phoneTrimmed.substring(phoneTrimmed.length - 10)
              : phoneTrimmed.isEmpty
                  ? '—'
                  : phoneTrimmed;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.badge_rounded, color: AppTheme.primary, size: 22),
                SizedBox(width: 10),
                Text('Add New Staff Member'),
              ],
            ),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Basic Info ──────────────────────────────
                    const _SectionLabel('Basic Information'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (_) => setDialogState(() {}),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subjectController,
                            decoration: const InputDecoration(
                              labelText: 'Subject / Role *',
                              prefixIcon: Icon(Icons.menu_book_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ── Class Dropdown ──────────────────────
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedClass,
                            decoration: const InputDecoration(
                              labelText: 'Assigned Class *',
                              prefixIcon: Icon(Icons.class_outlined),
                            ),
                            items: _classList
                                .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                                .toList(),
                            onChanged: (v) => setDialogState(() => selectedClass = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Contact ─────────────────────────────────
                    const _SectionLabel('Contact Details'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email Address',
                              prefixIcon: Icon(Icons.email_outlined),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Mobile Number *',
                              prefixIcon: Icon(Icons.phone_outlined),
                              hintText: '10-digit number',
                            ),
                            keyboardType: TextInputType.phone,
                            onChanged: (_) => setDialogState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ── Academic ────────────────────────────────
                    const _SectionLabel('Academic Background'),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qualController,
                            decoration: const InputDecoration(
                              labelText: 'Qualification',
                              prefixIcon: Icon(Icons.school_outlined),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: expController,
                            decoration: const InputDecoration(
                              labelText: 'Experience',
                              prefixIcon: Icon(Icons.history_edu_outlined),
                              hintText: 'e.g. 5 yrs',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final d = await showDatePicker(
                          context: builderContext,
                          initialDate: joiningDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime.now(),
                        );
                        if (d != null) setDialogState(() => joiningDate = d);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 18, color: AppTheme.textSecondary),
                            const SizedBox(width: 10),
                            Text('Joining Date: ${DateFormat('dd MMM yyyy').format(joiningDate)}',
                                style: const TextStyle(fontSize: 14)),
                            const Spacer(),
                            const Icon(Icons.arrow_drop_down, color: AppTheme.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Generated Credentials Preview ───────────
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.key_rounded, size: 16, color: AppTheme.primary),
                              SizedBox(width: 6),
                              Text('Auto-Generated Login Credentials',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                      color: AppTheme.primary)),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _CredRow(label: 'Username', value: previewUsername),
                          const SizedBox(height: 4),
                          _CredRow(label: 'Password', value: previewPassword),
                          const SizedBox(height: 6),
                          const Text(
                            'Share these credentials with the staff member for login.',
                            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
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
              ElevatedButton.icon(
                icon: const Icon(Icons.person_add_rounded, size: 16),
                onPressed: isSaving
                    ? null
                    : () async {
                        if (nameController.text.trim().isEmpty ||
                            phoneController.text.trim().isEmpty) {
                          ScaffoldMessenger.of(builderContext).showSnackBar(
                            const SnackBar(content: Text('Name and Mobile Number are required.')),
                          );
                          return;
                        }

                        setDialogState(() => isSaving = true);

                        try {
                          final teacher = Teacher(
                            id: '',
                            name: nameController.text.trim(),
                            subject: subjectController.text.trim(),
                            className: selectedClass ?? 'Not Assigned',
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
                            // Show credentials dialog after saving
                            _showCredentialsDialog(context, teacher);
                          }
                        } catch (e) {
                          if (builderContext.mounted) {
                            setDialogState(() => isSaving = false);
                            ScaffoldMessenger.of(builderContext).showSnackBar(
                              SnackBar(content: Text('Error: $e')),
                            );
                          }
                        }
                      },
                label: isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Add Staff'),
              ),
            ],
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Credentials Confirmation Dialog
  // ─────────────────────────────────────────────────────────────────────────
  void _showCredentialsDialog(BuildContext context, Teacher teacher) {
    final digits = teacher.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final password = digits.length > 10 ? digits.substring(digits.length - 10) : digits;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: AppTheme.accent, size: 22),
            SizedBox(width: 10),
            Text('Staff Added Successfully!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Login credentials for ${teacher.name}:',
                style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.accent.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.accent.withOpacity(0.25)),
              ),
              child: Column(
                children: [
                  _CredRow(label: 'Username', value: teacher.name, copyable: true),
                  const Divider(height: 20),
                  _CredRow(label: 'Password', value: password, copyable: true),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: AppTheme.warning),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Store these securely. Password is the mobile number.',
                      style: TextStyle(fontSize: 12, color: AppTheme.warning),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            onPressed: () => Navigator.pop(ctx),
            label: const Text('Done'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Staff Detail Dialog
  // ─────────────────────────────────────────────────────────────────────────
  void _showStaffDetailDialog(BuildContext context, Teacher teacher) {
    final digits = teacher.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final password = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
    final colors = [AppTheme.primary, AppTheme.accent, AppTheme.secondary, AppTheme.warning];
    final color = colors[teacher.name.length % colors.length];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: EdgeInsets.zero,
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header banner ─────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color, color.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.25),
                        child: Text(
                          teacher.name.split(' ').where((s) => s.isNotEmpty).map((p) => p[0]).take(2).join(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(teacher.name,
                                style: const TextStyle(
                                    color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
                            Text(teacher.subject,
                                style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(teacher.status,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Details ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DetailRow(icon: Icons.class_rounded, label: 'Assigned Class', value: teacher.className.isEmpty ? 'Not Assigned' : teacher.className),
                      _DetailRow(icon: Icons.email_outlined, label: 'Email', value: teacher.email.isEmpty ? '—' : teacher.email),
                      _DetailRow(icon: Icons.phone_outlined, label: 'Phone', value: teacher.phone.isEmpty ? '—' : teacher.phone),
                      _DetailRow(icon: Icons.school_outlined, label: 'Qualification', value: teacher.qualification.isEmpty ? '—' : teacher.qualification),
                      _DetailRow(icon: Icons.history_edu_outlined, label: 'Experience', value: teacher.experience.isEmpty ? '—' : teacher.experience),
                      _DetailRow(icon: Icons.calendar_today_rounded, label: 'Joining Date', value: DateFormat('dd MMM yyyy').format(teacher.joiningDate)),
                      const SizedBox(height: 16),

                      // ── Login Credentials ─────────────────────
                      const Text('Login Credentials',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppTheme.primary)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.primary.withOpacity(0.15)),
                        ),
                        child: Column(
                          children: [
                            _CredRow(label: 'Username', value: teacher.name, copyable: true),
                            const Divider(height: 16),
                            _CredRow(label: 'Password', value: password.isEmpty ? '—' : password, copyable: true),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
            onPressed: () async {
              Navigator.pop(ctx);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  title: const Text('Remove Staff Member?'),
                  content: Text('Are you sure you want to remove ${teacher.name}? This cannot be undone.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
                      onPressed: () => Navigator.pop(c, true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                await ref.read(teacherRepositoryProvider).deleteTeacher(teacher.id);
                if (context.mounted) {
                  AppToast.show(context, message: '${teacher.name} removed.', type: ToastType.info);
                }
              }
            },
            label: const Text('Remove', style: TextStyle(color: Colors.redAccent)),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.close, size: 16),
            onPressed: () => Navigator.pop(ctx),
            label: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Export
  // ─────────────────────────────────────────────────────────────────────────
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

      final excelFile = excel_pkg.Excel.createExcel();
      final sheet = excelFile['Teachers List'];
      excelFile.setDefaultSheet('Teachers List');

      if (excelFile['Sheet1'] != null && excelFile.tables.keys.length > 1) {
        excelFile.delete('Sheet1');
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

      final fileBytes = excelFile.encode();
      if (fileBytes != null) {
        final dateStr = DateFormat('yyyyMMdd').format(DateTime.now());
        await Share.shareXFiles(
          [
            XFile.fromData(
              Uint8List.fromList(fileBytes),
              mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
              name: 'Teachers_List_$dateStr.xlsx',
            )
          ],
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

// ──────────────────────────────────────────────────────────────────────────────
// Teacher Card
// ──────────────────────────────────────────────────────────────────────────────
class _TeacherCard extends StatelessWidget {
  final Teacher teacher;
  final int index;
  final VoidCallback onTap;

  const _TeacherCard({required this.teacher, required this.index, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isOnLeave = teacher.status == 'On Leave';
    final statusColor = isOnLeave ? AppTheme.warning : AppTheme.accent;
    final colors = [AppTheme.primary, AppTheme.accent, AppTheme.secondary, AppTheme.warning];
    final color = colors[index % colors.length];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
                  Text(teacher.name,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      overflow: TextOverflow.ellipsis),
                  Text('${teacher.subject} • ${teacher.className}',
                      style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(teacher.status,
                            style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(width: 6),
                      Text(teacher.experience,
                          style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                    ],
                  ),
                ],
              ),
            ),
            // Info tap indicator
            const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textSecondary),
          ],
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 60))
        .fadeIn(duration: 350.ms)
        .scale(begin: const Offset(0.95, 0.95));
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Helper Widgets
// ──────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.textSecondary,
            letterSpacing: 0.5));
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppTheme.textSecondary),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            child: Text(label,
                style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
          ),
        ],
      ),
    );
  }
}

class _CredRow extends StatelessWidget {
  final String label;
  final String value;
  final bool copyable;
  const _CredRow({required this.label, required this.value, this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        ),
        if (copyable)
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            icon: const Icon(Icons.copy_rounded, size: 15, color: AppTheme.primary),
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$label copied!'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              );
            },
          ),
      ],
    );
  }
}
