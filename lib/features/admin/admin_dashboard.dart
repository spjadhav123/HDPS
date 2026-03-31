// lib/features/admin/admin_dashboard.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/student_provider.dart';
// import '../../core/providers/attendance_provider.dart';
import '../../core/providers/event_provider.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/stat_card.dart';
import '../../shared/widgets/app_card.dart';
import '../../shared/widgets/app_animations.dart';
import '../../core/utils/app_date_utils.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../shared/widgets/responsive_layout.dart';

class AdminDashboard extends ConsumerWidget {
  const AdminDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final studentsAsync = ref.watch(studentsStreamProvider);
    final eventsAsync = ref.watch(upcomingEventsProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(ResponsiveLayout.isMobile(context) ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Admin Dashboard',
              subtitle: 'Welcome back! Here\'s what\'s happening today.',
            ),
            const SizedBox(height: 24),
            
            studentsAsync.when(
              data: (students) {
                final total = students.length;
                final byClass = {
                  'Playgroup': students.where((s) => s.className == 'Playgroup').length,
                  'Nursery': students.where((s) => s.className == 'Nursery').length,
                  'Jr. KG': students.where((s) => s.className == 'Jr. KG').length,
                  'Sr. KG': students.where((s) => s.className == 'Sr. KG').length,
                };

                double totalDue = 0;
                double totalPaid = 0;
                int pendingPayments = 0;
                for (var s in students) {
                  totalDue += s.feesTotal;
                  totalPaid += s.feesPaid;
                  if (s.feesTotal > s.feesPaid) pendingPayments++;
                }
                final pendingAmount = totalDue - totalPaid;
                final pendingStr = pendingAmount >= 1000 ? '₹${(pendingAmount/1000).toStringAsFixed(1)}k' : '₹${pendingAmount.toStringAsFixed(0)}';

                final isMobile = ResponsiveLayout.isMobile(context);
                final isTablet = ResponsiveLayout.isTablet(context);

                return Column(
                  children: [
                    GridView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 320,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.6,
                      ),
                      children: [
                        StatCard(
                          title: 'Total Students',
                          value: '$total',
                          icon: Icons.people_rounded,
                          color: AppTheme.primary,
                          trend: '+4% from last month',
                          animDelay: 0,
                        ),
                        const StatCard(
                          title: 'Daily Attendance',
                          value: '92%',
                          icon: Icons.how_to_reg_rounded,
                          color: AppTheme.accent,
                          trend: 'Normal',
                          animDelay: 80,
                        ),
                        StatCard(
                          title: 'Pending Fees',
                          value: pendingStr,
                          icon: Icons.payments_rounded,
                          color: AppTheme.secondary,
                          trend: '$pendingPayments payments due',
                          animDelay: 160,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    if (isMobile || isTablet) ...[
                      AppCard(
                        title: 'Enrollment by Class',
                        child: SizedBox(
                          height: 220,
                          child: BarChart(
                            BarChartData(
                              gridData: const FlGridData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (val, meta) {
                                      final keys = byClass.keys.toList();
                                      if (val.toInt() >= keys.length) return const SizedBox();
                                      return Text(keys[val.toInt()], style: const TextStyle(fontSize: 10));
                                    },
                                  ),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              barGroups: byClass.entries.toList().asMap().entries.map((e) {
                                return BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.value.toDouble(),
                                      color: AppTheme.primary.withAlpha(204),
                                      width: 25,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      AppCard(
                        title: 'Upcoming Events',
                        child: eventsAsync.when(
                          data: (events) {
                            if (events.isEmpty) {
                              return const Center(child: Text('No upcoming events', style: TextStyle(fontSize: 12, color: Colors.grey)));
                            }
                            return Column(
                              children: events.take(3).map((e) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                title: Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                subtitle: Text(AppDateUtils.formatDisplay(e.date), style: const TextStyle(fontSize: 11)),
                                leading: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(color: AppTheme.accent.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                                  child: const Icon(Icons.event, color: AppTheme.accent, size: 18),
                                ),
                              )).toList(),
                            );
                          },
                          loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: SpinningLoader(size: 32))),
                          error: (_, __) => const Text('Error loading events'),
                        ),
                      ),
                    ] else ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: AppCard(
                              title: 'Enrollment by Class',
                              child: SizedBox(
                                height: 220,
                                child: BarChart(
                                  BarChartData(
                                    gridData: const FlGridData(show: false),
                                    titlesData: FlTitlesData(
                                      leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                      bottomTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          getTitlesWidget: (val, meta) {
                                            final keys = byClass.keys.toList();
                                            if (val.toInt() >= keys.length) return const SizedBox();
                                            return Text(keys[val.toInt()], style: const TextStyle(fontSize: 10));
                                          },
                                        ),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    barGroups: byClass.entries.toList().asMap().entries.map((e) {
                                      return BarChartGroupData(
                                        x: e.key,
                                        barRods: [
                                          BarChartRodData(
                                            toY: e.value.value.toDouble(),
                                            color: AppTheme.primary.withAlpha(204),
                                            width: 25,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: AppCard(
                              title: 'Upcoming Events',
                              child: eventsAsync.when(
                                data: (events) {
                                  if (events.isEmpty) {
                                    return const Center(child: Text('No upcoming events', style: TextStyle(fontSize: 12, color: Colors.grey)));
                                  }
                                  return Column(
                                    children: events.take(3).map((e) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      title: Text(e.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                                      subtitle: Text(AppDateUtils.formatDisplay(e.date), style: const TextStyle(fontSize: 11)),
                                      leading: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(color: AppTheme.accent.withAlpha(25), borderRadius: BorderRadius.circular(8)),
                                        child: const Icon(Icons.event, color: AppTheme.accent, size: 18),
                                      ),
                                    )).toList(),
                                  );
                                },
                                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: SpinningLoader(size: 32))),
                                error: (_, __) => const Text('Error loading events'),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                );
              },
              loading: () => const Padding(padding: EdgeInsets.only(top: 100), child: FullPageLoader(message: 'Loading Dashboard...')),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
            
            const SizedBox(height: 24),
            const Text('Quick Actions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))
                .animate()
                .fadeIn(duration: 350.ms, delay: 200.ms)
                .slideX(begin: -0.05, curve: Curves.easeOut),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _QuickAction(icon: Icons.person_add_rounded, label: 'Add Student', color: Colors.blue, animDelay: 220, onTap: () => context.push('/admin/students')),
                _QuickAction(icon: Icons.campaign_rounded, label: 'Send Notice', color: Colors.orange, animDelay: 290, onTap: () => context.push('/notifications')),
                _QuickAction(icon: Icons.receipt_long_rounded, label: 'Fee Receipt', color: Colors.green, animDelay: 360, onTap: () => context.push('/admin/fees')),
                _QuickAction(icon: Icons.calendar_month_rounded, label: 'Academic Calendar', color: Colors.purple, animDelay: 430, onTap: () => context.push('/events')),
                _QuickAction(icon: Icons.verified_user_rounded, label: 'Bonafide', color: Colors.teal, animDelay: 500, onTap: () => context.push('/admin/bonafide')),
                _QuickAction(icon: Icons.workspace_premium_rounded, label: 'Experience', color: Colors.blueGrey, animDelay: 540, onTap: () => context.push('/admin/experience-letter')),
                _QuickAction(icon: Icons.output_rounded, label: 'Leaving Cert', color: Colors.indigo, animDelay: 570, onTap: () => context.push('/admin/leaving-certificate')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatefulWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int animDelay;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.animDelay = 0,
  });

  @override
  State<_QuickAction> createState() => _QuickActionState();
}

class _QuickActionState extends State<_QuickAction> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedScale(
        duration: const Duration(milliseconds: 180),
        scale: _hovered ? 1.05 : 1.0,
        curve: Curves.easeOut,
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: _hovered ? 6 : 1,
          shadowColor: widget.color.withAlpha(64),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            hoverColor: widget.color.withAlpha(15),
            splashColor: widget.color.withAlpha(30),
            child: SizedBox(
              width: 140,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: widget.color.withAlpha(25),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(widget.icon, color: widget.color, size: 24),
                    ),
                    const SizedBox(height: 10),
                    Text(widget.label,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: widget.animDelay))
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOut);
  }
}
