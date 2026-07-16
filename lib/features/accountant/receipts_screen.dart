// lib/features/accountant/receipts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/providers/receipt_provider.dart';
import '../../core/models/receipt_model.dart';
import '../../core/utils/pdf_receipt_generator.dart';

class ReceiptsScreen extends ConsumerWidget {
  final bool showHeader;
  const ReceiptsScreen({super.key, this.showHeader = true});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptsAsync = ref.watch(allReceiptsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: showHeader ? const EdgeInsets.all(24) : EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showHeader) ...[
              const PageHeader(title: 'Fee Receipts', subtitle: 'Download and manage payment receipts'),
              const SizedBox(height: 24),
            ] else ...[
              const Text('Receipts History', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 16),
            ],
            Expanded(
              child: Container(
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
                          Expanded(flex: 2, child: Text('Amount', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 2, child: Text('Date', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 2, child: Text('Mode', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary))),
                          Expanded(flex: 1, child: Text('PDF', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: AppTheme.textSecondary), textAlign: TextAlign.center)),
                        ],
                      ),
                    ),
                    Expanded(
                      child: receiptsAsync.when(
                        data: (receipts) {
                          if (receipts.isEmpty) {
                            return const Center(child: Text('No receipts found.'));
                          }
                          return ListView.separated(
                            itemCount: receipts.length,
                            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                            itemBuilder: (ctx, i) {
                              final r = receipts[i];
                              final modeColor = r.paymentMethod == 'Online' || r.paymentMethod == 'UPI'
                                  ? AppTheme.primary
                                  : r.paymentMethod == 'Cheque' || r.paymentMethod == 'D.D.'
                                      ? AppTheme.accent
                                      : AppTheme.warning;

                              final formattedDate = DateFormat('dd MMM yyyy').format(r.date);

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  children: [
                                    Expanded(flex: 2, child: Text(r.receiptNo, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.primary))),
                                    Expanded(flex: 3, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(r.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                                      Text(r.className, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                    ])),
                                    Expanded(flex: 2, child: Text('₹${NumberFormat('#,##0').format(r.amount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                                    Expanded(flex: 2, child: Text(formattedDate, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                                    Expanded(flex: 2, child: Align(
                                      alignment: Alignment.centerLeft,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: modeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                        child: Text(r.paymentMethod, style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w600)),
                                      ),
                                    )),
                                    Expanded(flex: 1, child: Center(child: IconButton(
                                      icon: const Icon(Icons.download_rounded, color: AppTheme.primary, size: 20),
                                      onPressed: () async {
                                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                          content: Text('Generating ${r.receiptNo}.pdf...'),
                                          backgroundColor: AppTheme.primary,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        ));

                                        try {
                                          final pdfBytes = await PdfReceiptGenerator.generateReceipt(
                                            receiptNo: r.receiptNo,
                                            studentName: r.studentName,
                                            className: r.className,
                                            amount: r.amount,
                                            balance: 0.0, // Historic reprints default balance display
                                            paymentMode: r.paymentMethod,
                                            date: r.date,
                                            parentName: r.receivedFrom.isNotEmpty ? r.receivedFrom : null,
                                            transactionId: r.transactionId.isNotEmpty ? r.transactionId : null,
                                            installment: r.installment.isNotEmpty ? r.installment : null,
                                          );

                                          await Printing.layoutPdf(
                                            onLayout: (PdfPageFormat format) async => pdfBytes,
                                            name: 'Receipt_${r.receiptNo}',
                                          );
                                        } catch (e) {
                                          ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                            content: Text('Failed to print receipt: $e'),
                                            backgroundColor: Colors.redAccent,
                                          ));
                                        }
                                      },
                                      tooltip: 'Download PDF',
                                    ))),
                                  ],
                                ),
                              ).animate(delay: Duration(milliseconds: i * 50)).fadeIn();
                            },
                          );
                        },
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('Error loading receipts: $e')),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
