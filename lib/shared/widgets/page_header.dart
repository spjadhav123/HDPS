// lib/shared/widgets/page_header.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_theme.dart';

class PageHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? action;

  const PageHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 700;

    if (isMobile && action != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary))
              .animate()
              .fadeIn(duration: 350.ms)
              .slideX(begin: -0.06, curve: Curves.easeOut),
          const SizedBox(height: 4),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppTheme.textSecondary))
              .animate()
              .fadeIn(duration: 350.ms, delay: 60.ms)
              .slideX(begin: -0.06, curve: Curves.easeOut),
          const SizedBox(height: 12),
          action!
              .animate()
              .fadeIn(duration: 350.ms, delay: 120.ms)
              .slideY(begin: 0.08, curve: Curves.easeOut),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary))
                  .animate()
                  .fadeIn(duration: 350.ms)
                  .slideX(begin: -0.06, curve: Curves.easeOut),
              const SizedBox(height: 4),
              Text(subtitle,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.textSecondary))
                  .animate()
                  .fadeIn(duration: 350.ms, delay: 60.ms)
                  .slideX(begin: -0.06, curve: Curves.easeOut),
            ],
          ),
        ),
        if (action != null)
          action!
              .animate()
              .fadeIn(duration: 350.ms, delay: 100.ms)
              .slideX(begin: 0.06, curve: Curves.easeOut),
      ],
    );
  }
}
