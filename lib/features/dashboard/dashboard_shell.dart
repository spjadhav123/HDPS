// lib/features/dashboard/dashboard_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/providers/notification_provider.dart';

class NavItem {
  final String label;
  final String path;
  final IconData icon;
  const NavItem(this.label, this.path, this.icon);
}

class DashboardShell extends ConsumerStatefulWidget {
  final Widget child;
  const DashboardShell({super.key, required this.child});

  @override
  ConsumerState<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends ConsumerState<DashboardShell>
    with SingleTickerProviderStateMixin {
  bool _sidebarExpanded = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Color _getRoleColor(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return AppTheme.primary;
      case AppConstants.roleTeacher:
        return AppTheme.secondary;
      case AppConstants.roleAccountant:
        return AppTheme.warning;
      case AppConstants.roleParent:
        return AppTheme.accent;
      default:
        return AppTheme.primary;
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return Icons.admin_panel_settings_rounded;
      case AppConstants.roleTeacher:
        return Icons.school_rounded;
      case AppConstants.roleAccountant:
        return Icons.account_balance_rounded;
      case AppConstants.roleParent:
        return Icons.family_restroom_rounded;
      default:
        return Icons.person_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    if (authState.user == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final user = authState.user!;
    final roleColor = _getRoleColor(user.role);
    final navItems = _getNavItems(user.role);
    final currentPath = GoRouterState.of(context).matchedLocation;


    return Scaffold(
      key: _scaffoldKey,
      drawer: MediaQuery.of(context).size.width < 1100
          ? Drawer(child: _buildSidebar(user, roleColor, navItems, currentPath, unreadCount))
          : null,
      body: Row(
        children: [
          if (MediaQuery.of(context).size.width >= 1100)
            _buildSidebar(user, roleColor, navItems, currentPath, unreadCount)
                .animate()
                .fadeIn(duration: 350.ms),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(user, unreadCount)
                    .animate()
                    .fadeIn(duration: 400.ms, delay: 100.ms)
                    .slideY(begin: -0.04, curve: Curves.easeOut),
                Expanded(
                  child: widget.child
                      .animate()
                      .fadeIn(duration: 350.ms, delay: 200.ms),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar(AuthUser user, int unreadCount) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          if (MediaQuery.of(context).size.width < 1100)
            IconButton(
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              icon: const Icon(Icons.menu_rounded),
            ),
          const Spacer(),
          Stack(
            children: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AppTheme.textSecondary),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: 1.0 + _pulseController.value * 0.2,
                        child: child,
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                          color: Colors.red, shape: BoxShape.circle),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ).animate().scale(
                        begin: const Offset(0, 0),
                        duration: 300.ms,
                        curve: Curves.elasticOut,
                      ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primary.withOpacity(0.1),
            child: Text(user.name[0],
                style: const TextStyle(
                    color: AppTheme.primary, fontWeight: FontWeight.bold)),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .shimmer(duration: 2000.ms, delay: 3000.ms, color: AppTheme.primary.withOpacity(0.3)),
        ],
      ),
    );
  }

  Widget _buildSidebar(AuthUser user, Color roleColor, List<NavItem> items,
      String currentPath, int unreadCount) {
    return SizedBox(
      width: _sidebarExpanded ? 260 : 80,
      child: ColoredBox(
        color: AppTheme.background,
        child: Column(
          children: [
            _buildSidebarHeader(),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 20),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  return _buildSidebarItem(items[index], currentPath);
                },
              ),
            ),
            _buildSidebarFooter(user, roleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return GestureDetector(
      onTap: () => setState(() => _sidebarExpanded = !_sidebarExpanded),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12)),
              width: 44,
              height: 44,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Transform.scale(
                  scale: 1.8,
                  alignment: Alignment.center,
                  child: Image.asset('assets/images/logo.jpg',
                      fit: BoxFit.contain),
                ),
              ),
            ),
            if (_sidebarExpanded) ...[
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Humpty Dumpty',
                        style: TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16)),
                    Text('Pre-School',
                        style: TextStyle(
                            color: AppTheme.textSecondary, fontSize: 11)),
                  ],
                ),
              ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.05),
              const Icon(Icons.chevron_left_rounded,
                      color: AppTheme.textSecondary, size: 18)
                  .animate()
                  .fadeIn(duration: 200.ms),
            ] else ...[
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded,
                      color: AppTheme.textSecondary, size: 18)
                  .animate()
                  .fadeIn(duration: 200.ms),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarItem(NavItem item, String currentPath) {
    final isSelected = currentPath == item.path ||
        (item.path != '/admin' && currentPath.startsWith(item.path));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: _HoverNavItem(
        isSelected: isSelected,
        onTap: () => context.go(item.path),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primary.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  item.icon,
                  key: ValueKey('$isSelected${item.icon}'),
                  size: 20,
                  color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
              if (_sidebarExpanded) ...[
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: TextStyle(
                    color:
                        isSelected ? AppTheme.primary : AppTheme.textSecondary,
                    fontWeight:
                        isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (isSelected) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(end: 1.4, duration: 700.ms)
                      .then()
                      .scaleXY(end: 1.0, duration: 700.ms),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSidebarFooter(AuthUser user, Color roleColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Column(
        children: [
          if (_sidebarExpanded)
            AnimatedOpacity(
              opacity: _sidebarExpanded ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: roleColor.withOpacity(0.1),
                      child: Icon(_getRoleIcon(user.role),
                          size: 16, color: roleColor),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 13),
                              overflow: TextOverflow.ellipsis),
                          Text(user.role.toUpperCase(),
                              style: TextStyle(
                                  color: roleColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 200.ms).slideY(begin: 0.05),
          const SizedBox(height: 8),
          _HoverNavItem(
            isSelected: false,
            onTap: () => ref.read(authProvider.notifier).logout(),
            isDestructive: true,
            child: ListTile(
              dense: true,
              leading: const Icon(Icons.logout_rounded,
                  color: Colors.redAccent, size: 20),
              title: _sidebarExpanded
                  ? const Text('Logout',
                      style: TextStyle(
                          color: Colors.redAccent, fontWeight: FontWeight.w600))
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  List<NavItem> _getNavItems(String role) {
    switch (role) {
      case AppConstants.roleAdmin:
        return [
          const NavItem('Dashboard', '/admin', Icons.dashboard_customize_rounded),
          const NavItem('Students', '/admin/students', Icons.group_rounded),
          const NavItem('Teachers', '/admin/teachers', Icons.badge_rounded),
          const NavItem('Fees', '/admin/fees', Icons.payments_rounded),
          const NavItem('Gallery', '/gallery', Icons.photo_library_rounded),
          const NavItem('Events', '/events', Icons.event_rounded),
        ];
      case AppConstants.roleTeacher:
        return [
          const NavItem('Dashboard', '/teacher', Icons.dashboard_rounded),
          const NavItem('Attendance', '/teacher/attendance', Icons.how_to_reg_rounded),
          const NavItem('Activities', '/teacher/activities', Icons.upload_file_rounded),
          const NavItem('Gradebook', '/teacher/gradebook', Icons.grade_rounded),
          const NavItem('Homework', '/teacher/homework', Icons.assignment_rounded),
          const NavItem('Gallery', '/gallery', Icons.photo_library_rounded),
        ];
      case AppConstants.roleParent:
        return [
          const NavItem('Dashboard', '/parent', Icons.home_rounded),
          const NavItem('My Child', '/parent/child', Icons.child_care_rounded),
          const NavItem('Attendance', '/parent/attendance', Icons.calendar_month_rounded),
          const NavItem('Report Cards', '/parent/reports', Icons.assignment_rounded),
          const NavItem('Fees', '/parent/fees', Icons.payments_rounded),
          const NavItem('Homework', '/parent/homework', Icons.book_rounded),
          const NavItem('Gallery', '/gallery', Icons.photo_library_rounded),
        ];
      case AppConstants.roleAccountant:
        return [
          const NavItem('Dashboard', '/accountant', Icons.dashboard_rounded),
          const NavItem('Fees', '/accountant/fees', Icons.payments_rounded),
          const NavItem('Receipts', '/accountant/receipts', Icons.receipt_long_rounded),
        ];
      default:
        return [];
    }
  }


  void _showForceChangePasswordDialog(BuildContext context) {
    // Check if it's already showing
    if (ModalRoute.of(context)?.isCurrent == false) return;
    
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'For security reasons, you must change your password on your first login.',
                style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: Icon(Icons.lock_reset),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                final pwd = passwordController.text.trim();
                final conf = confirmController.text.trim();
                
                if (pwd.length < 6) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Password must be at least 6 characters'))
                   );
                   return;
                }
                
                if (pwd != conf) {
                   ScaffoldMessenger.of(context).showSnackBar(
                     const SnackBar(content: Text('Passwords do not match'))
                   );
                   return;
                }
                
                setDialogState(() => isSaving = true);
                final success = await ref.read(authProvider.notifier).changePassword(pwd);
                if (success) {
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green)
                    );
                  }
                } else {
                  setDialogState(() => isSaving = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to change password. Try again.'))
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, foregroundColor: Colors.white),
              child: isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Update Password'),
            ),
          ],
        ),
      ),
    );
  }
}

/// A hover-aware nav item wrapper that lifts/highlights on hover.
class _HoverNavItem extends StatefulWidget {
  final Widget child;
  final bool isSelected;
  final bool isDestructive;
  final VoidCallback onTap;

  const _HoverNavItem({
    required this.child,
    required this.isSelected,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  State<_HoverNavItem> createState() => _HoverNavItemState();
}

class _HoverNavItemState extends State<_HoverNavItem> {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        hoverColor: widget.isDestructive
            ? Colors.red.withOpacity(0.07)
            : AppTheme.primary.withOpacity(0.06),
        splashColor: widget.isDestructive
            ? Colors.red.withOpacity(0.12)
            : AppTheme.primary.withOpacity(0.1),
        highlightColor: Colors.transparent,
        child: widget.child,
      ),
    );
  }
}
