import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_animations.dart';
import '../../core/providers/student_provider.dart';
import '../../core/providers/receipt_provider.dart';
import '../../core/models/receipt_model.dart';

class AccountantDashboard extends ConsumerWidget {
  const AccountantDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final receiptsAsync = ref.watch(allReceiptsStreamProvider);
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Accounts Dashboard',
              subtitle: 'Financial overview for Academic Year 2025-26',
            ),
            const SizedBox(height: 24),
            studentsAsync.when(
              data: (students) {
                double totalDue = 0;
                double totalPaid = 0;
                int pendingCount = 0;
                for (var s in students) {
                  totalDue += s.feesTotal;
                  totalPaid += s.feesPaid;
                  if (s.feesTotal > s.feesPaid && s.feesTotal > 0) pendingCount++;
                }
                
                final totalStr = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 1).format(totalDue);
                final paidStr = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 1).format(totalPaid);
                final pendingStr = NumberFormat.compactCurrency(symbol: '₹', decimalDigits: 1).format(totalDue - totalPaid);
                final percent = totalDue > 0 ? (totalPaid / totalDue * 100).toStringAsFixed(1) : '0';

                return LayoutBuilder(builder: (ctx, c) {
                  return GridView.count(
                    crossAxisCount: c.maxWidth > 800 ? 4 : c.maxWidth > 500 ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.8,
                    children: [
                      StatCard(title: 'Total Fees Due', value: totalStr, icon: Icons.receipt_long_rounded, color: AppTheme.primary, animDelay: 0),
                      StatCard(title: 'Collected', value: paidStr, icon: Icons.payments_rounded, color: const Color(0xFF22C55E), trend: '$percent%', animDelay: 100),
                      StatCard(title: 'Pending', value: pendingStr, icon: Icons.pending_actions_rounded, color: AppTheme.warning, trend: '$pendingCount students', animDelay: 200),
                      const StatCard(title: 'Verify Status', value: 'Active', icon: Icons.verified_user_rounded, color: AppTheme.secondary, trend: 'Gateway Connected', animDelay: 300),
                    ],
                  );
                });
              },
              loading: () => const ShimmerListView(itemCount: 1, itemHeight: 90),
              error: (err, _) => Text('Error loading stats: $err'),
            ),
            const SizedBox(height: 24),
            receiptsAsync.when(
              data: (receipts) => _buildRecentPayments(receipts),
              loading: () => const ShimmerListView(itemCount: 4, itemHeight: 60),
              error: (err, _) => Text('Error loading receipts: $err'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPayments(List<Receipt> receipts) {
    if (receipts.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: const Text('No recent payments found.', style: TextStyle(color: AppTheme.textSecondary)),
      );
    }
    
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
          const Text('Recent Payments', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppTheme.textPrimary)),
          const SizedBox(height: 16),
          ...receipts.take(10).toList().asMap().entries.map((e) {
            final p = e.value;
            final dateStr = DateFormat('dd MMM, yyyy').format(p.date as DateTime);
            return AnimatedListItem(
              index: e.key,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.accent.withAlpha(38),
                      child: Text(p.studentName.isNotEmpty ? p.studentName[0] : 'U', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(p.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Text('${p.receiptNo} • Class: ${p.className} • $dateStr', style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                      ]),
                    ),
                    Text('₹${p.amount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withAlpha(25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Paid', style: TextStyle(fontSize: 11, color: AppTheme.accent, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    ).animate().fadeIn(duration: AppDurations.slow);
  }
}
