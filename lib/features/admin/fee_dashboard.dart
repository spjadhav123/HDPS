// lib/features/admin/fee_dashboard.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/student_provider.dart';

class AdminFeeDashboard extends ConsumerWidget {
  const AdminFeeDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Fee Management Dashboard',
              subtitle: 'Monitor fee collections, pendings, and structures.',
            ),
            const SizedBox(height: 24),

            // Quick Actions
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin/fees/structure'),
                  icon: const Icon(Icons.settings_suggest_rounded, size: 18),
                  label: const Text('Fee Structure Setup'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.secondary),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push('/admin/fees/assignment'),
                  icon: const Icon(Icons.people_rounded, size: 18),
                  label: const Text('Student Fee Assignment'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 32),

            studentsAsync.when(
              data: (students) {
                double totalCollected = 0;
                double totalPending = 0;
                double todayCollection = 0; // Mocked for now

                for (var student in students) {
                  totalCollected += student.feesPaid;
                  final pending = student.feesTotal - student.feesPaid;
                  if (pending > 0) totalPending += pending;
                }

                final isMobile = MediaQuery.of(context).size.width < 700;

                return Column(
                  children: [
                    if (isMobile) ...[
                      _buildSummaryCard('Total Collected', '₹${totalCollected.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, AppTheme.accent),
                      const SizedBox(height: 16),
                      _buildSummaryCard('Total Pending', '₹${totalPending.toStringAsFixed(0)}', Icons.warning_rounded, AppTheme.warning),
                      const SizedBox(height: 16),
                      _buildSummaryCard('Today\'s Collection', '₹${todayCollection.toStringAsFixed(0)}', Icons.today_rounded, AppTheme.secondary),
                    ] else ...[
                      Row(
                        children: [
                          Expanded(child: _buildSummaryCard('Total Collected', '₹${totalCollected.toStringAsFixed(0)}', Icons.account_balance_wallet_rounded, AppTheme.accent)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSummaryCard('Total Pending', '₹${totalPending.toStringAsFixed(0)}', Icons.warning_rounded, AppTheme.warning)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildSummaryCard('Today\'s Collection', '₹${todayCollection.toStringAsFixed(0)}', Icons.today_rounded, AppTheme.secondary)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 32),
                    // Class wise summary
                    _buildClassWiseSummary(students, isMobile),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(String title, String amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 16),
          Text(amount, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 13, color: AppTheme.textSecondary, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildClassWiseSummary(List students, bool isMobile) {
    Map<String, Map<String, double>> classSummary = {};
    for (var student in students) {
      if (!classSummary.containsKey(student.className)) {
        classSummary[student.className] = {'collected': 0, 'pending': 0};
      }
      classSummary[student.className]!['collected'] = classSummary[student.className]!['collected']! + student.feesPaid;
      final pending = student.feesTotal - student.feesPaid;
      if (pending > 0) {
        classSummary[student.className]!['pending'] = classSummary[student.className]!['pending']! + pending;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade100)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Class Wise Fee Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...classSummary.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: isMobile 
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Collected: ₹${e.value['collected']!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600)),
                      Text('Pending: ₹${e.value['pending']!.toStringAsFixed(0)}', style: TextStyle(color: e.value['pending']! > 0 ? AppTheme.warning : AppTheme.textSecondary)),
                      const Divider(),
                    ],
                  )
                : Row(
                    children: [
                      Expanded(flex: 2, child: Text(e.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                      Expanded(flex: 3, child: Text('Collected: ₹${e.value['collected']!.toStringAsFixed(0)}', style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.w600))),
                      Expanded(flex: 3, child: Text('Pending: ₹${e.value['pending']!.toStringAsFixed(0)}', style: TextStyle(color: e.value['pending']! > 0 ? AppTheme.warning : AppTheme.textSecondary))),
                    ],
                  ),
            );
          }).toList(),
          if (classSummary.isEmpty) const Text('No data available', style: TextStyle(color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
