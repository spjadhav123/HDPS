// lib/features/accountant/fees_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';
import '../../core/utils/pdf_receipt_generator.dart';

class FeesScreen extends ConsumerStatefulWidget {
  final bool showHeader;
  const FeesScreen({super.key, this.showHeader = true});

  @override
  ConsumerState<FeesScreen> createState() => _FeesScreenState();
}

class _FeesScreenState extends ConsumerState<FeesScreen> {
  String _filter = 'All';

  String _getFeeStatus(Student student) {
    if (student.feesTotal <= 0) return 'No Fee Assgd'; // Default when zero
    if (student.feesPaid >= student.feesTotal) return 'Cleared';
    if (student.feesPaid > 0) return 'Partial';
    return 'Pending';
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: widget.showHeader ? const EdgeInsets.all(24) : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.showHeader) ...[
              PageHeader(
                title: 'Fee Management',
                subtitle: 'Monitor student fees, pending balances, and record payments.',
                action: ElevatedButton.icon(
                  onPressed: () => _showAddPaymentDialog(null),
                  icon: const Icon(Icons.add_card_rounded, size: 18),
                  label: const Text('Record Payment'),
                ),
              ),
              const SizedBox(height: 20),
            ] else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Students Fee Status', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                  ElevatedButton.icon(
                    onPressed: () => _showAddPaymentDialog(null),
                    icon: const Icon(Icons.add_card_rounded, size: 16),
                    label: const Text('Record Payment'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
            _buildFilterRow(),
            const SizedBox(height: 16),
            Expanded(
              child: studentsAsync.when(
                data: (students) {
                  final filtered = _filter == 'All' 
                    ? students 
                    : students.where((s) => _getFeeStatus(s) == _filter).toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text('No students found for this filter.'));
                  }

                  return _buildTable(filtered);
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

  Widget _buildFilterRow() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: ['All', 'Cleared', 'Partial', 'Pending', 'No Fee Assgd'].map((f) {
        final isSelected = _filter == f;
        return FilterChip(
          selected: isSelected,
          label: Text(f),
          onSelected: (_) => setState(() => _filter = f),
          selectedColor: AppTheme.primary.withOpacity(0.15),
          checkmarkColor: AppTheme.primary,
          labelStyle: TextStyle(
            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTable(List<Student> students) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: isMobile ? 800 : constraints.maxWidth,
              child: Column(
                children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppTheme.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Total Fee', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Paid', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Balance', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 2, child: Text('Status', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.right)),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: students.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
              itemBuilder: (_, i) {
                final student = students[i];
                final status = _getFeeStatus(student);
                final statusColor = status == 'Cleared' ? AppTheme.accent : status == 'Partial' ? AppTheme.warning : status == 'Pending' ? Colors.redAccent : AppTheme.textSecondary;
                final balance = student.feesTotal - student.feesPaid;

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(student.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Text('Class: ${student.className}', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('₹${NumberFormat('#,##0').format(student.feesTotal)}', style: const TextStyle(fontSize: 13)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text('₹${NumberFormat('#,##0').format(student.feesPaid)}', style: const TextStyle(fontSize: 13, color: Color(0xFF22C55E), fontWeight: FontWeight.w600)),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₹${NumberFormat('#,##0').format(balance.clamp(0, double.infinity))}',
                          style: TextStyle(
                            fontSize: 13,
                            color: balance > 0 ? AppTheme.secondary : AppTheme.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: Text(status, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment.centerRight,
                          child: IconButton(
                            icon: const Icon(Icons.payment_rounded, size: 20, color: AppTheme.primary),
                            onPressed: () => _showAddPaymentDialog(student),
                            tooltip: 'Record Payment',
                          ),
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
            ),
          ),
        );
      }
    );
  }

  void _showAddPaymentDialog(Student? initialStudent) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AddPaymentDialog(initialStudent: initialStudent),
    );
  }
}

class _AddPaymentDialog extends ConsumerStatefulWidget {
  final Student? initialStudent;
  const _AddPaymentDialog({this.initialStudent});

  @override
  ConsumerState<_AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends ConsumerState<_AddPaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _transactionIdCtrl = TextEditingController();
  final _parentNameCtrl = TextEditingController();
  String _selectedMode = 'Cash';
  String _selectedInstallment = '1st Installment';
  Student? _selectedStudent;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedStudent = widget.initialStudent;
    if (_selectedStudent != null) {
      _parentNameCtrl.text = _selectedStudent!.parent;
      _amountCtrl.text = (_selectedStudent!.feesTotal - _selectedStudent!.feesPaid).toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _transactionIdCtrl.dispose();
    _parentNameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amountCtrl.text);
    if (_selectedStudent == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a student and enter a valid amount.')));
      return;
    }

    setState(() => _isSaving = true);
    final receiptNo = 'HD-RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
    
    try {
      final newPaid = _selectedStudent!.feesPaid + amount;
      final balance = _selectedStudent!.feesTotal - newPaid;

      // Update student document
      await FirebaseFirestore.instance.collection('students').doc(_selectedStudent!.id).update({
        'feesPaid': newPaid,
      });

      // Insert receipt document
      await FirebaseFirestore.instance.collection('receipts').doc().set({
        'receiptNo': receiptNo,
        'studentId': _selectedStudent!.id,
        'studentName': _selectedStudent!.name,
        'className': _selectedStudent!.className,
        'amount': amount,
        'paymentMode': _selectedMode,
        'transactionId': _transactionIdCtrl.text.trim(),
        'date': FieldValue.serverTimestamp(),
        'receivedFrom': _parentNameCtrl.text.trim(),
        'installment': _selectedInstallment,
        'description': 'Fee Payment: $_selectedInstallment via $_selectedMode',
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment recorded successfully.')));

        // Generate and view PDF
        final pdfBytes = await PdfReceiptGenerator.generateReceipt(
          receiptNo: receiptNo,
          studentName: _selectedStudent!.name,
          className: _selectedStudent!.className,
          amount: amount,
          balance: balance.clamp(0, double.infinity),
          paymentMode: _selectedMode,
          date: DateTime.now(),
          parentName: _parentNameCtrl.text.trim(),
          transactionId: _transactionIdCtrl.text.trim(),
          installment: _selectedInstallment,
        );

        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'Receipt_$receiptNo',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return AlertDialog(
      title: const Text('Record Fee Payment'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget.initialStudent != null) ...[
                Text('Student: ${_selectedStudent!.name} (${_selectedStudent!.className})'),
                const SizedBox(height: 8),
                Text('Balance Due: ₹${(_selectedStudent!.feesTotal - _selectedStudent!.feesPaid).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning)),
              ] else ...[
                studentsAsync.when(
                  data: (students) {
                    return DropdownButtonFormField<Student>(
                      value: _selectedStudent != null ? students.firstWhere((s) => s.id == _selectedStudent!.id, orElse: () => _selectedStudent!) : null,
                      decoration: const InputDecoration(labelText: 'Select Student', prefixIcon: Icon(Icons.person_rounded)),
                      items: students.map((s) => DropdownMenuItem(value: s, child: Text('${s.name} (${s.className})'))).toList(),
                      onChanged: (s) {
                        setState(() {
                          _selectedStudent = s;
                          if (s != null) {
                            _parentNameCtrl.text = s.parent;
                            _amountCtrl.text = (s.feesTotal - s.feesPaid).toStringAsFixed(0);
                          }
                        });
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Text('Error loading students: $e'),
                ),
                if (_selectedStudent != null) ...[
                  const SizedBox(height: 8),
                  Text('Balance Due: ₹${(_selectedStudent!.feesTotal - _selectedStudent!.feesPaid).toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.warning)),
                ],
              ],
              const SizedBox(height: 16),
              TextField(
                controller: _parentNameCtrl,
                decoration: const InputDecoration(labelText: 'Received From (Mr./Mrs.)', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedInstallment,
                decoration: const InputDecoration(labelText: 'Installment', prefixIcon: Icon(Icons.event_repeat_rounded)),
                items: ['1st Installment', '2nd Installment', 'Full Payment'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedInstallment = v ?? '1st Installment'),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedMode,
                decoration: const InputDecoration(labelText: 'Payment Mode', prefixIcon: Icon(Icons.payment_rounded)),
                items: ['Cash', 'UPI', 'Bank Transfer', 'Card', 'Cheque', 'D.D.'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedMode = v ?? 'Cash'),
              ),
              if (_selectedMode != 'Cash') ...[
                const SizedBox(height: 16),
                TextField(
                  controller: _transactionIdCtrl,
                  decoration: const InputDecoration(labelText: 'Transaction/Cheque/Ref ID', prefixIcon: Icon(Icons.numbers_rounded)),
                ),
              ]
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Record & Generate Receipt'),
        ),
      ],
    );
  }
}
