// lib/features/admin/book_payments_view.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/student_model.dart';
import '../../core/providers/student_provider.dart';
import '../../core/utils/pdf_receipt_generator.dart';

class BookPaymentsView extends ConsumerStatefulWidget {
  const BookPaymentsView({super.key});

  @override
  ConsumerState<BookPaymentsView> createState() => _BookPaymentsViewState();
}

class _BookPaymentsViewState extends ConsumerState<BookPaymentsView> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Books Distribution & Payments', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            ElevatedButton.icon(
              onPressed: () => _showRecordBookPaymentDialog(),
              icon: const Icon(Icons.menu_book_rounded, size: 16),
              label: const Text('Record Book Payment'),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('book_receipts').orderBy('date', descending: true).snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              
              final filtered = docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name = (data['studentName'] ?? '').toString().toLowerCase();
                final className = (data['className'] ?? '').toString().toLowerCase();
                return name.contains(_searchQuery) || className.contains(_searchQuery);
              }).toList();

              if (filtered.isEmpty) {
                return const Center(child: Text('No book payment receipts found.'));
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade100),
                ),
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
                          Expanded(flex: 2, child: Text('Receipt No.', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 3, child: Text('Student', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 2, child: Text('Book Details', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 1, child: Text('Print', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (ctx, i) {
                          final doc = filtered[i];
                          final data = doc.data() as Map<String, dynamic>;
                          
                          final receiptNo = data['receiptNo'] ?? '';
                          final studentName = data['studentName'] ?? '';
                          final className = data['className'] ?? '';
                          final booksDetails = data['booksDetails'] ?? 'Book Set';
                          final amount = (data['amount'] ?? 0.0).toDouble();
                          final paymentMode = data['paymentMode'] ?? 'Cash';
                          final transactionId = data['transactionId'] ?? '';
                          final parentName = data['receivedFrom'] ?? '';
                          final distributionStatus = data['distributionStatus'] ?? 'Partially Distributed';
                          
                          final timestamp = data['date'] as Timestamp?;
                          final date = timestamp != null ? timestamp.toDate() : DateTime.now();
                          final formattedDate = DateFormat('dd MMM yyyy').format(date);

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Expanded(flex: 2, child: Text(receiptNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary))),
                                Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                  Text(className, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                ])),
                                Expanded(flex: 2, child: Text(booksDetails, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
                                Expanded(flex: 2, child: Text('₹${NumberFormat('#,##0').format(amount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                Expanded(flex: 2, child: Text(formattedDate, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                                Expanded(flex: 1, child: Center(child: IconButton(
                                  icon: const Icon(Icons.print_rounded, color: AppTheme.primary, size: 20),
                                  onPressed: () async {
                                    try {
                                      final pdfBytes = await PdfReceiptGenerator.generateReceipt(
                                        receiptNo: receiptNo,
                                        studentName: studentName,
                                        className: className,
                                        amount: amount,
                                        balance: 0.0,
                                        paymentMode: paymentMode,
                                        date: date,
                                        parentName: parentName.isNotEmpty ? parentName : null,
                                        transactionId: transactionId.isNotEmpty ? transactionId : null,
                                        isBookReceipt: true,
                                        booksDetails: booksDetails,
                                        distributionStatus: distributionStatus,
                                      );

                                      await Printing.layoutPdf(
                                        onLayout: (PdfPageFormat format) async => pdfBytes,
                                        name: 'BookReceipt_$receiptNo',
                                      );
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                                        content: Text('Failed to print receipt: $e'),
                                        backgroundColor: Colors.redAccent,
                                      ));
                                    }
                                  },
                                  tooltip: 'Print Receipt',
                                ))),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: i * 30)).fadeIn();
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRecordBookPaymentDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _RecordBookPaymentDialog(),
    );
  }
}

class _RecordBookPaymentDialog extends ConsumerStatefulWidget {
  const _RecordBookPaymentDialog();

  @override
  ConsumerState<_RecordBookPaymentDialog> createState() => _RecordBookPaymentDialogState();
}

class _RecordBookPaymentDialogState extends ConsumerState<_RecordBookPaymentDialog> {
  final _amountCtrl = TextEditingController();
  final _studentNameCtrl = TextEditingController();
  final _booksDetailsCtrl = TextEditingController(text: 'Nursery Book Set');
  final _parentNameCtrl = TextEditingController();
  final _transactionIdCtrl = TextEditingController();
  String _selectedClass = 'Nursery';
  String _selectedMode = 'Cash';
  String _distributionStatus = 'Partially Distributed';
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    _studentNameCtrl.dispose();
    _booksDetailsCtrl.dispose();
    _parentNameCtrl.dispose();
    _transactionIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final studentName = _studentNameCtrl.text.trim();
    final amount = double.tryParse(_amountCtrl.text);
    if (studentName.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a student name and a valid amount.')));
      return;
    }

    setState(() => _isSaving = true);
    final receiptNo = 'HD-BK-RC-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';

    try {
      // Save details to the isolated Firestore collection `book_receipts`
      // We do NOT update the student's standard `feesPaid` / `feesTotal` fields,
      // so this payment will not affect academic dashboard statistics.
      await FirebaseFirestore.instance.collection('book_receipts').doc().set({
        'receiptNo': receiptNo,
        'studentId': 'manual_entry',
        'studentName': studentName,
        'className': _selectedClass,
        'amount': amount,
        'paymentMode': _selectedMode,
        'transactionId': _transactionIdCtrl.text.trim(),
        'date': FieldValue.serverTimestamp(),
        'receivedFrom': _parentNameCtrl.text.trim(),
        'booksDetails': _booksDetailsCtrl.text.trim(),
        'distributionStatus': _distributionStatus,
      });

      if (mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Book payment recorded successfully.')));

        // Generate and view PDF
        final pdfBytes = await PdfReceiptGenerator.generateReceipt(
          receiptNo: receiptNo,
          studentName: studentName,
          className: _selectedClass,
          amount: amount,
          balance: 0.0,
          paymentMode: _selectedMode,
          date: DateTime.now(),
          parentName: _parentNameCtrl.text.trim(),
          transactionId: _transactionIdCtrl.text.trim(),
          isBookReceipt: true,
          booksDetails: _booksDetailsCtrl.text.trim(),
          distributionStatus: _distributionStatus,
        );

        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: 'BookReceipt_$receiptNo',
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
    return AlertDialog(
      title: const Text('Record Book Payment & Dist.'),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _studentNameCtrl,
                decoration: const InputDecoration(labelText: 'Student Name', prefixIcon: Icon(Icons.person_rounded)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                decoration: const InputDecoration(labelText: 'Class', prefixIcon: Icon(Icons.class_rounded)),
                items: ['Playgroup', 'Nursery', 'Jr. KG', 'Sr. KG'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedClass = v ?? 'Nursery';
                    _booksDetailsCtrl.text = '$_selectedClass Book Set';
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _parentNameCtrl,
                decoration: const InputDecoration(labelText: 'Received From (Mr./Mrs.)', prefixIcon: Icon(Icons.person_outline_rounded)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _booksDetailsCtrl,
                decoration: const InputDecoration(labelText: 'Book Set Details', prefixIcon: Icon(Icons.menu_book_outlined)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Amount (₹)', prefixIcon: Icon(Icons.currency_rupee_rounded)),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _distributionStatus,
                decoration: const InputDecoration(labelText: 'Distribution Status', prefixIcon: Icon(Icons.local_shipping_rounded)),
                items: ['Partially Distributed', 'Fully Distributed'].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _distributionStatus = v ?? 'Partially Distributed'),
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
