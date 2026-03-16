// lib/shared/widgets/status_badge.dart
import 'package:flutter/material.dart';

/// A colored pill/badge for displaying status labels.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 11,
  });

  /// Convenience factory for common student/attendance statuses.
  static StatusBadge fromStatus(String status) {
    final Color color;
    switch (status.toLowerCase()) {
      case 'active':
      case 'present':
      case 'cleared':
        color = const Color(0xFF22C55E); // green
        break;
      case 'absent':
      case 'overdue':
        color = const Color(0xFFFF6584); // red/pink
        break;
      case 'leave':
      case 'partial':
        color = const Color(0xFFFFB347); // orange
        break;
      case 'inactive':
        color = const Color(0xFF94A3B8); // gray
        break;
      default:
        color = const Color(0xFF6C63FF); // purple default
    }
    return StatusBadge(label: status, color: color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(77)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
