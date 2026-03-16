// lib/features/admin/student_fee_assignment_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';
import '../../core/providers/fee_structure_provider.dart';

class StudentFeeAssignmentScreen extends ConsumerStatefulWidget {
  const StudentFeeAssignmentScreen({super.key});

  @override
  ConsumerState<StudentFeeAssignmentScreen> createState() => _StudentFeeAssignmentScreenState();
}

class _StudentFeeAssignmentScreenState extends ConsumerState<StudentFeeAssignmentScreen> {
  String _searchQuery = '';
  
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
              title: 'Student Fee Assignment',
              subtitle: 'Manually adjust fees for individual students.',
            ),
            const SizedBox(height: 20),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by Student Name or Class',
                prefixIcon: Icon(Icons.search_rounded),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  final filtered = students.where((s) => s.name.toLowerCase().contains(_searchQuery) || s.className.toLowerCase().contains(_searchQuery)).toList();
                  
                  if (filtered.isEmpty) return const Center(child: Text('No students found.'));

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final student = filtered[i];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                          leading: CircleAvatar(
                            backgroundColor: AppTheme.primary.withAlpha(25),
                            child: Text(student.name[0], style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold)),
                          ),
                          title: Text(student.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                          subtitle: Text('Class: ${student.className} • Total Fees: ₹${student.feesTotal.toStringAsFixed(0)}'),
                          trailing: ElevatedButton.icon(
                            onPressed: () => _showAdjustmentDialog(student),
                            icon: const Icon(Icons.edit_rounded, size: 16),
                            label: const Text('Adjust'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAdjustmentDialog(Student student) {
    showDialog(context: context, builder: (_) => _AdjustFeeDialog(student: student));
  }
}

class _AdjustFeeDialog extends ConsumerStatefulWidget {
  final Student student;
  const _AdjustFeeDialog({required this.student});

  @override
  ConsumerState<_AdjustFeeDialog> createState() => _AdjustFeeDialogState();
}

class _AdjustFeeDialogState extends ConsumerState<_AdjustFeeDialog> {
  final _totalCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _totalCtrl.text = widget.student.feesTotal.toStringAsFixed(0);
  }

  Future<void> _save() async {
    final amt = double.tryParse(_totalCtrl.text);
    if (amt == null || amt < widget.student.feesPaid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid amount or less than already paid.')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      await ref.read(feeAssignmentServiceProvider).assignFeeToStudent(widget.student, amt);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fee assigned successfully.')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Adjust Fee for ${widget.student.name}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Already Paid: ₹${widget.student.feesPaid.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accent)),
          const SizedBox(height: 16),
          TextField(
            controller: _totalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'New Total Payable Fee (₹)'),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Assign Fee'),
        ),
      ],
    );
  }
}
