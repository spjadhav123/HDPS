// lib/features/admin/fee_structure_setup_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/models/fee_structure_model.dart';
import '../../core/providers/fee_structure_provider.dart';

class FeeStructureSetupScreen extends ConsumerStatefulWidget {
  const FeeStructureSetupScreen({super.key});

  @override
  ConsumerState<FeeStructureSetupScreen> createState() => _FeeStructureSetupScreenState();
}

class _FeeStructureSetupScreenState extends ConsumerState<FeeStructureSetupScreen> {
  @override
  Widget build(BuildContext context) {
    final structuresAsync = ref.watch(allFeeStructuresProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Fee Structure Setup',
              subtitle: 'Define class-wise fee structures and amounts.',
              action: ElevatedButton.icon(
                onPressed: () => _showAddDialog(),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Add Fee Structure'),
              ),
            ),
            const SizedBox(height: 24),
            structuresAsync.when(
              data: (structures) {
                if (structures.isEmpty) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No fee structures defined yet.', style: TextStyle(color: AppTheme.textSecondary)),
                  ));
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: structures.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final struct = structures[i];
                    return _buildStructureCard(struct);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStructureCard(FeeStructure struct) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Class: ${struct.className}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.primary),
              ),
              IconButton(
                icon: const Icon(Icons.edit_rounded, color: AppTheme.secondary, size: 20),
                onPressed: () => _showAddDialog(struct: struct),
                tooltip: 'Edit Structure',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 24,
            runSpacing: 16,
            children: [
              _FeeItem(label: 'Tuition Fee', amount: struct.tuitionFee),
              _FeeItem(label: 'Term Fee', amount: struct.termFee),
              _FeeItem(label: 'Transport Fee', amount: struct.transportFee),
              _FeeItem(label: 'Exam Fee', amount: struct.examFee),
              _FeeItem(label: 'Other Fees', amount: struct.otherFees),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Fee Payable:', style: TextStyle(fontWeight: FontWeight.w700)),
              Text('₹${struct.totalFee.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppTheme.accent)),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddDialog({FeeStructure? struct}) {
    showDialog(context: context, builder: (_) => _AddFeeStructureDialog(struct: struct));
  }
}

class _FeeItem extends StatelessWidget {
  final String label;
  final double amount;
  const _FeeItem({required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w600)),
        const SizedBox(height: 2),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
      ],
    );
  }
}

class _AddFeeStructureDialog extends ConsumerStatefulWidget {
  final FeeStructure? struct;
  const _AddFeeStructureDialog({this.struct});

  @override
  ConsumerState<_AddFeeStructureDialog> createState() => _AddFeeStructureDialogState();
}

class _AddFeeStructureDialogState extends ConsumerState<_AddFeeStructureDialog> {
  final _formKey = GlobalKey<FormState>();
  final _classCtrl = TextEditingController();
  final _tuitionCtrl = TextEditingController();
  final _termCtrl = TextEditingController();
  final _transportCtrl = TextEditingController();
  final _examCtrl = TextEditingController();
  final _otherCtrl = TextEditingController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.struct != null) {
      _classCtrl.text = widget.struct!.className;
      _tuitionCtrl.text = widget.struct!.tuitionFee.toString();
      _termCtrl.text = widget.struct!.termFee.toString();
      _transportCtrl.text = widget.struct!.transportFee.toString();
      _examCtrl.text = widget.struct!.examFee.toString();
      _otherCtrl.text = widget.struct!.otherFees.toString();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    
    final struct = FeeStructure(
      id: widget.struct?.id ?? _classCtrl.text.trim(), // Use class name as document ID if new
      className: _classCtrl.text.trim(),
      tuitionFee: double.tryParse(_tuitionCtrl.text) ?? 0,
      termFee: double.tryParse(_termCtrl.text) ?? 0,
      transportFee: double.tryParse(_transportCtrl.text) ?? 0,
      examFee: double.tryParse(_examCtrl.text) ?? 0,
      otherFees: double.tryParse(_otherCtrl.text) ?? 0,
      updatedAt: DateTime.now(),
    );

    try {
      await ref.read(feeStructureRepositoryProvider).saveFeeStructure(struct);
      
      // Auto assign updated total to students in this class
      await ref.read(feeAssignmentServiceProvider).updateStudentsFeeByClass(struct.className, struct.totalFee);
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Saved Successfully')));
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
      title: Text(widget.struct == null ? 'Add Fee Structure' : 'Edit Fee Structure'),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 400,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _classCtrl,
                  decoration: const InputDecoration(labelText: 'Class Name (e.g. Nursery, LKG)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                  enabled: widget.struct == null, // Class name shouldn't change for an existing doc unless handled differently
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _tuitionCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tuition Fee (₹)'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _termCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Term Fee (₹)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _transportCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Transport Fee (₹)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _examCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Exam Fee (₹)'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _otherCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Other Fees (₹)'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const CircularProgressIndicator() : const Text('Save Setup'),
        ),
      ],
    );
  }
}
