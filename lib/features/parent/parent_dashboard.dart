// lib/features/parent/parent_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/page_header.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/student_provider.dart';
import 'package:go_router/go_router.dart';

class ParentDashboard extends ConsumerWidget {
  const ParentDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final childAsync = ref.watch(parentChildStudentProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeader(
              title: 'Parent Portal',
              subtitle:
                  'Welcome, ${authState.user?.name ?? 'Parent'} 👋',
            ),
            const SizedBox(height: 24),
            childAsync.when(
              data: (student) => _buildChildCard(context, student),
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, _) => Center(
                child: Text('Error loading child: $err'),
              ),
            ),
            const SizedBox(height: 20),
            _buildQuickActions(context),
            const SizedBox(height: 20),
            _buildAnnouncements(),
          ],
        ),
      ),
    );
  }

  Widget _buildChildCard(BuildContext context, student) {
    if (student == null) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: const Text(
          'No student record is linked to your account yet.\n'
          'Please contact the school admin to register your child '
          'using your email address.',
          style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFF9C8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(51),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.child_care_rounded, color: Colors.white, size: 36),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(student.name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                Text(
                  'Class: ${student.className} | ID: ${student.studentCode}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const _StatBadge(label: 'Attendance', value: '88%'),
                    const SizedBox(width: 12),
                    const _StatBadge(label: 'Grade', value: 'A'),
                    const SizedBox(width: 12),
                    _StatBadge(label: 'Fee Due', value: '₹${(student.feesTotal - student.feesPaid).toStringAsFixed(0)}'),
                    if (student.feesTotal > student.feesPaid) ...[
                      const SizedBox(width: 16),
                      TextButton(
                        onPressed: () => context.go('/parent/fees'),
                        style: TextButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        child: const Text('Pay Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.05);
  }

  Widget _buildQuickActions(BuildContext context) {
    final actions = [
      ('View Progress', Icons.bar_chart_rounded, AppTheme.accent, '/parent/child'),
      ('Pay Fees', Icons.payment_rounded, AppTheme.primary, '/parent/fees'),
      ('Download Receipt', Icons.receipt_rounded, AppTheme.warning, ''),
      ('Message Teacher', Icons.message_rounded, AppTheme.secondary, ''),
    ];

    return LayoutBuilder(builder: (ctx, c) {
      final cols = c.maxWidth > 600 ? 4 : 2;
      return GridView.count(
        crossAxisCount: cols,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.4,
        children: actions.asMap().entries.map((e) {
          final a = e.value;
          return InkWell(
            onTap: () {
              if (a.$4.isNotEmpty) {
                 context.go(a.$4);
              } else {
                ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(
                  content: Text('${a.$1} coming soon'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(color: a.$3.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                    child: Icon(a.$2, color: a.$3, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(a.$1, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textPrimary), textAlign: TextAlign.center),
                ],
              ),
            ),
          ).animate(delay: Duration(milliseconds: e.key * 80)).fadeIn().scale(begin: const Offset(0.95, 0.95));
        }).toList(),
      );
    });
  }

  Widget _buildAnnouncements() {
    final notices = [
      ('Annual Day Celebration', 'Annual day will be held on 15 March 2026. All parents are invited.', Icons.celebration_rounded, AppTheme.primary),
      ('Fee Due Reminder', 'Term 2 fee is due by 31 March 2026. Please pay on time.', Icons.warning_amber_rounded, AppTheme.warning),
      ('Parent-Teacher Meeting', 'PTM scheduled for 20 March. Please confirm attendance.', Icons.people_rounded, AppTheme.accent),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Notices & Announcements', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
        const SizedBox(height: 12),
        ...notices.asMap().entries.map((e) {
          final n = e.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: n.$4.withOpacity(0.06), blurRadius: 8)],
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: n.$4.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Icon(n.$3, color: n.$4, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(n.$1, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(n.$2, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ]),
                ),
              ],
            ),
          ).animate(delay: Duration(milliseconds: e.key * 100)).fadeIn();
        }),
      ],
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  const _StatBadge({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(51),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 9)),
        ],
      ),
    );
  }
}
