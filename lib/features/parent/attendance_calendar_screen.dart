// lib/features/parent/attendance_calendar_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/attendance_model.dart';
import '../../core/providers/attendance_provider.dart';
import '../../core/providers/student_provider.dart';
import '../../core/utils/app_date_utils.dart';
import '../../shared/widgets/page_header.dart';
import '../../shared/widgets/app_card.dart';

class AttendanceCalendarScreen extends ConsumerStatefulWidget {
  const AttendanceCalendarScreen({super.key});

  @override
  ConsumerState<AttendanceCalendarScreen> createState() =>
      _AttendanceCalendarScreenState();
}

class _AttendanceCalendarScreenState
    extends ConsumerState<AttendanceCalendarScreen> {
  DateTime _displayMonth = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final childAsync = ref.watch(parentChildStudentProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const PageHeader(
              title: 'Attendance Calendar',
              subtitle: 'Monthly attendance overview for your child',
            ),
            const SizedBox(height: 20),
            childAsync.when(
              data: (student) {
                if (student == null) {
                  return const Center(
                    child: Text(
                      'No student linked to your account.',
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                  );
                }
                return _AttendanceCalendarView(
                  studentId: student.id,
                  studentName: student.name,
                  displayMonth: _displayMonth,
                  onMonthChanged: (m) =>
                      setState(() => _displayMonth = m),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error: $err')),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceCalendarView extends ConsumerStatefulWidget {
  final String studentId;
  final String studentName;
  final DateTime displayMonth;
  final ValueChanged<DateTime> onMonthChanged;

  const _AttendanceCalendarView({
    required this.studentId,
    required this.studentName,
    required this.displayMonth,
    required this.onMonthChanged,
  });

  @override
  ConsumerState<_AttendanceCalendarView> createState() =>
      _AttendanceCalendarViewState();
}

class _AttendanceCalendarViewState
    extends ConsumerState<_AttendanceCalendarView> {
  Map<String, AttendanceStatus> _attendanceMap = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadMonth(widget.displayMonth);
  }

  @override
  void didUpdateWidget(_AttendanceCalendarView old) {
    super.didUpdateWidget(old);
    if (old.displayMonth != widget.displayMonth) {
      _loadMonth(widget.displayMonth);
    }
  }

  Future<void> _loadMonth(DateTime month) async {
    setState(() => _isLoading = true);
    try {
      final from = DateTime(month.year, month.month, 1);
      final to = DateTime(month.year, month.month + 1, 0);
      final map = await ref
          .read(attendanceRepositoryProvider)
          .getAttendanceMap(widget.studentId, from, to);
      if (mounted) setState(() => _attendanceMap = map);
    } catch (_) {} finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = AppDateUtils.daysInMonth(
        widget.displayMonth.year, widget.displayMonth.month);
    final firstWeekday = days.first.weekday % 7; // 0 = Sun

    final presentDays =
        _attendanceMap.values.where((s) => s == AttendanceStatus.present).length;
    final absentDays =
        _attendanceMap.values.where((s) => s == AttendanceStatus.absent).length;
    final leaveDays =
        _attendanceMap.values.where((s) => s == AttendanceStatus.leave).length;
    final totalMarked = _attendanceMap.length;
    final pct = totalMarked > 0 ? (presentDays / totalMarked * 100) : 0.0;

    return Expanded(
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Month Navigation
            AppCard(
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => widget.onMonthChanged(DateTime(
                      widget.displayMonth.year,
                      widget.displayMonth.month - 1,
                    )),
                    icon: const Icon(Icons.chevron_left_rounded),
                  ),
                  Expanded(
                    child: Text(
                      AppDateUtils.formatMonthYear(widget.displayMonth),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: widget.displayMonth.month >=
                            DateTime.now().month &&
                            widget.displayMonth.year >= DateTime.now().year
                        ? null
                        : () => widget.onMonthChanged(DateTime(
                              widget.displayMonth.year,
                              widget.displayMonth.month + 1,
                            )),
                    icon: const Icon(Icons.chevron_right_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Summary row
            Row(
              children: [
                _SummaryTile(
                  label: 'Present',
                  count: presentDays,
                  color: AppTheme.accent,
                  emoji: '✅',
                ),
                const SizedBox(width: 12),
                _SummaryTile(
                  label: 'Absent',
                  count: absentDays,
                  color: AppTheme.secondary,
                  emoji: '❌',
                ),
                const SizedBox(width: 12),
                _SummaryTile(
                  label: 'Leave',
                  count: leaveDays,
                  color: AppTheme.warning,
                  emoji: '🏖',
                ),
                const SizedBox(width: 12),
                _SummaryTile(
                  label: 'Attendance',
                  count: null,
                  countText: '${pct.toStringAsFixed(0)}%',
                  color: pct >= 75
                      ? AppTheme.accent
                      : pct >= 50
                          ? AppTheme.warning
                          : AppTheme.secondary,
                  emoji: '📊',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calendar Grid
            AppCard(
              title: 'Attendance Calendar',
              subtitle: widget.studentName,
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : Column(
                      children: [
                        // Day headers
                        Row(
                          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                              .map((d) => Expanded(
                                    child: Center(
                                      child: Text(
                                        d,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 8),
                        // Calendar cells
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 7,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                            childAspectRatio: 1,
                          ),
                          itemCount: firstWeekday + days.length,
                          itemBuilder: (ctx, i) {
                            if (i < firstWeekday) {
                              return const SizedBox.shrink();
                            }
                            final day = days[i - firstWeekday];
                            final key = AppDateUtils.dateKey(day);
                            final status = _attendanceMap[key];
                            final isToday =
                                AppDateUtils.isToday(day);
                            final isFuture =
                                day.isAfter(DateTime.now());
                            final isWeekend =
                                AppDateUtils.isWeekend(day);

                            return _DayCell(
                              day: day,
                              status: status,
                              isToday: isToday,
                              isFuture: isFuture,
                              isWeekend: isWeekend,
                            );
                          },
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 16),

            // Legend
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 20,
                runSpacing: 8,
                children: [
                  _LegendItem(color: AppTheme.accent, label: 'Present'),
                  _LegendItem(color: AppTheme.secondary, label: 'Absent'),
                  _LegendItem(color: AppTheme.warning, label: 'Leave'),
                  _LegendItem(color: Colors.grey.shade200, label: 'Not Marked'),
                  _LegendItem(
                      color: Colors.orange.shade100, label: 'Weekend'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final DateTime day;
  final AttendanceStatus? status;
  final bool isToday;
  final bool isFuture;
  final bool isWeekend;

  const _DayCell({
    required this.day,
    required this.status,
    required this.isToday,
    required this.isFuture,
    required this.isWeekend,
  });

  Color _bgColor() {
    if (isFuture) return Colors.transparent;
    if (isWeekend) return Colors.orange.shade50;
    if (status == null) return Colors.grey.shade100;
    switch (status!) {
      case AttendanceStatus.present:
        return AppTheme.accent.withOpacity(0.15);
      case AttendanceStatus.absent:
        return AppTheme.secondary.withOpacity(0.15);
      case AttendanceStatus.leave:
        return AppTheme.warning.withOpacity(0.15);
    }
  }

  Color _textColor() {
    if (isFuture) return AppTheme.textSecondary.withOpacity(0.4);
    if (isWeekend) return Colors.orange.shade400;
    if (status == null) return AppTheme.textSecondary;
    switch (status!) {
      case AttendanceStatus.present:
        return AppTheme.accent;
      case AttendanceStatus.absent:
        return AppTheme.secondary;
      case AttendanceStatus.leave:
        return AppTheme.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor(),
        borderRadius: BorderRadius.circular(8),
        border: isToday
            ? Border.all(color: AppTheme.primary, width: 2)
            : null,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 12,
            fontWeight:
                isToday ? FontWeight.w800 : FontWeight.w500,
            color: isToday ? AppTheme.primary : _textColor(),
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final int? count;
  final String? countText;
  final Color color;
  final String emoji;

  const _SummaryTile({
    required this.label,
    required this.count,
    required this.color,
    required this.emoji,
    this.countText,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 4),
            Text(
              countText ?? '${count ?? 0}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 10,
                  color: color,
                  fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
              fontSize: 12, color: AppTheme.textSecondary),
        ),
      ],
    );
  }
}
