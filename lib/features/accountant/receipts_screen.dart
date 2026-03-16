// lib/features/accountant/receipts_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';

class _Receipt {
  final String receiptNo;
  final String studentName;
  final String className;
  final double amount;
  final String date;
  final String paymentMode;
  _Receipt(this.receiptNo, this.studentName, this.className, this.amount, this.date, this.paymentMode);
}

final _receipts = [
  _Receipt('HD-RC-001', 'Aryan Patel', 'Nursery A', 12000, '15 Jan 2026', 'Online'),
  _Receipt('HD-RC-002', 'Rohan Kumar', 'UKG A', 24000, '05 Jan 2026', 'Cheque'),
  _Receipt('HD-RC-003', 'Dev Mehta', 'LKG A', 12000, '12 Jan 2026', 'Cash'),
  _Receipt('HD-RC-004', 'Arjun Verma', 'Nursery B', 24000, '10 Jan 2026', 'Online'),
  _Receipt('HD-RC-005', 'Priya Singh', 'LKG B', 6000, '20 Feb 2026', 'UPI'),
  _Receipt('HD-RC-006', 'Aryan Patel', 'Nursery A', 12000, '15 Feb 2026', 'Online'),
  _Receipt('HD-RC-007', 'Ananya Sharma', 'Nursery A', 12000, '01 Feb 2026', 'Cash'),
  _Receipt('HD-RC-008', 'Ishaan Gupta', 'LKG A', 8000, '25 Feb 2026', 'UPI'),
];

class ReceiptsScreen extends StatelessWidget {
  const ReceiptsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(title: 'Fee Receipts', subtitle: 'Download and manage payment receipts'),
            const SizedBox(height: 24),
            Expanded(
              child: Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(color: AppTheme.background, borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
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
                      child: ListView.separated(
                        itemCount: _receipts.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (ctx, i) {
                          final r = _receipts[i];
                          final modeColor = r.paymentMode == 'Online' || r.paymentMode == 'UPI'
                              ? AppTheme.primary
                              : r.paymentMode == 'Cheque'
                                  ? AppTheme.accent
                                  : AppTheme.warning;
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
                                Expanded(flex: 2, child: Text(r.date, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                                Expanded(flex: 2, child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(color: modeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                                  child: Text(r.paymentMode, style: TextStyle(fontSize: 11, color: modeColor, fontWeight: FontWeight.w600)),
                                )),
                                Expanded(flex: 1, child: Center(child: IconButton(
                                  icon: const Icon(Icons.download_rounded, color: AppTheme.primary, size: 20),
                                  onPressed: () {
                                    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                                      content: Text('Downloading ${r.receiptNo}.pdf...'),
                                      backgroundColor: AppTheme.primary,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ));
                                  },
                                  tooltip: 'Download PDF',
                                ))),
                              ],
                            ),
                          ).animate(delay: Duration(milliseconds: i * 50)).fadeIn();
                        },
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
