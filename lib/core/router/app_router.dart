// lib/core/router/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/signup_screen.dart';
import '../../features/dashboard/dashboard_shell.dart';
import '../../features/admin/admin_dashboard.dart';
import '../../features/admin/students_screen.dart';
import '../../features/admin/teachers_screen.dart';
import '../../features/admin/bulk_add_students_screen.dart';
import '../../features/admin/fee_dashboard.dart';
import '../../features/admin/fee_structure_setup_screen.dart';
import '../../features/admin/student_fee_assignment_screen.dart';
import '../../features/teacher/teacher_dashboard.dart';
import '../../features/teacher/attendance_screen.dart';
import '../../features/teacher/gradebook_screen.dart';
import '../../features/teacher/homework_screen.dart';
import '../../features/teacher/activity_upload_screen.dart';
import '../../features/accountant/accountant_dashboard.dart';
import '../../features/accountant/fees_screen.dart';
import '../../features/accountant/receipts_screen.dart';
import '../../features/parent/parent_dashboard.dart';
import '../../features/parent/my_child_screen.dart';
import '../../features/parent/fee_payment_screen.dart';
import '../../features/parent/attendance_calendar_screen.dart';
import '../../features/reports/report_card_screen.dart';
import '../../features/notifications/notification_center.dart';
import '../../features/events/events_screen.dart';
import '../../features/chat/chat_screen.dart';
import '../../features/gallery/gallery_screen.dart';
import '../../features/activities/anti_gravity_game.dart';

// ─────────────────────────────────────────────────────────────
// Page transition builder — smooth fade+slide up
// ─────────────────────────────────────────────────────────────
CustomTransitionPage<void> _buildPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      // Fade + slight slide-up transition
      final fadeAnim = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      final slideAnim = Tween<Offset>(
        begin: const Offset(0, 0.04),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      return FadeTransition(
        opacity: fadeAnim,
        child: SlideTransition(position: slideAnim, child: child),
      );
    },
  );
}

// ─────────────────────────────────────────────────────────────
// Page transition builder for sub-pages — slide from right
// ─────────────────────────────────────────────────────────────
CustomTransitionPage<void> _buildSubPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 300),
    reverseTransitionDuration: const Duration(milliseconds: 250),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final inAnim = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      final outAnim = Tween<Offset>(
        begin: Offset.zero,
        end: const Offset(-0.04, 0),
      ).animate(CurvedAnimation(parent: secondaryAnimation, curve: Curves.easeIn));

      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return SlideTransition(
        position: outAnim,
        child: SlideTransition(
          position: inAnim,
          child: FadeTransition(opacity: fade, child: child),
        ),
      );
    },
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final isLoggedIn = authState.user != null;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) {
        final role = authState.user?.role;
        if (role == 'admin') return '/admin';
        if (role == 'teacher') return '/teacher';
        if (role == 'accountant') return '/accountant';
        if (role == 'parent') return '/parent';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _buildPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _buildSubPage(context, state, const SignUpScreen()),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return DashboardShell(child: child);
        },
        routes: [
          // ── Admin ──────────────────────────────────────────
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _buildPage(context, state, const AdminDashboard()),
          ),
          GoRoute(
            path: '/admin/students',
            pageBuilder: (context, state) => _buildSubPage(context, state, const StudentsScreen()),
          ),
          GoRoute(
            path: '/admin/students/bulk',
            pageBuilder: (context, state) => _buildSubPage(context, state, const BulkAddStudentsScreen()),
          ),
          GoRoute(
            path: '/admin/teachers',
            pageBuilder: (context, state) => _buildSubPage(context, state, const TeachersScreen()),
          ),
          GoRoute(
            path: '/admin/fees',
            pageBuilder: (context, state) => _buildSubPage(context, state, const AdminFeeDashboard()),
          ),
          GoRoute(
            path: '/admin/fees/structure',
            pageBuilder: (context, state) => _buildSubPage(context, state, const FeeStructureSetupScreen()),
          ),
          GoRoute(
            path: '/admin/fees/assignment',
            pageBuilder: (context, state) => _buildSubPage(context, state, const StudentFeeAssignmentScreen()),
          ),

          // ── Teacher ────────────────────────────────────────
          GoRoute(
            path: '/teacher',
            pageBuilder: (context, state) => _buildPage(context, state, const TeacherDashboard()),
          ),
          GoRoute(
            path: '/teacher/attendance',
            pageBuilder: (context, state) => _buildSubPage(context, state, const AttendanceScreen()),
          ),
          GoRoute(
            path: '/teacher/gradebook',
            pageBuilder: (context, state) => _buildSubPage(context, state, const GradebookScreen()),
          ),
          GoRoute(
            path: '/teacher/homework',
            pageBuilder: (context, state) => _buildSubPage(context, state, const HomeworkScreen()),
          ),
          GoRoute(
            path: '/teacher/activities',
            pageBuilder: (context, state) => _buildSubPage(context, state, const ActivityUploadScreen()),
          ),

          // ── Accountant ─────────────────────────────────────
          GoRoute(
            path: '/accountant',
            pageBuilder: (context, state) => _buildPage(context, state, const AccountantDashboard()),
          ),
          GoRoute(
            path: '/accountant/fees',
            pageBuilder: (context, state) => _buildSubPage(context, state, const FeesScreen()),
          ),
          GoRoute(
            path: '/accountant/receipts',
            pageBuilder: (context, state) => _buildSubPage(context, state, const ReceiptsScreen()),
          ),

          // ── Parent ─────────────────────────────────────────
          GoRoute(
            path: '/parent',
            pageBuilder: (context, state) => _buildPage(context, state, const ParentDashboard()),
          ),
          GoRoute(
            path: '/parent/child',
            pageBuilder: (context, state) => _buildSubPage(context, state, const MyChildScreen()),
          ),
          GoRoute(
            path: '/parent/fees',
            pageBuilder: (context, state) => _buildSubPage(context, state, const FeePaymentScreen()),
          ),
          GoRoute(
            path: '/parent/attendance',
            pageBuilder: (context, state) => _buildSubPage(context, state, const AttendanceCalendarScreen()),
          ),
          GoRoute(
            path: '/parent/reports',
            pageBuilder: (context, state) => _buildSubPage(context, state, const ReportCardScreen()),
          ),
          GoRoute(
            path: '/parent/homework',
            pageBuilder: (context, state) => _buildSubPage(context, state, const _ParentHomeworkView()),
          ),

          // ── Shared (cross-role) ────────────────────────────
          GoRoute(
            path: '/notifications',
            pageBuilder: (context, state) => _buildSubPage(context, state, const NotificationCenter()),
          ),
          GoRoute(
            path: '/events',
            pageBuilder: (context, state) => _buildSubPage(context, state, const EventsScreen()),
          ),
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => _buildSubPage(context, state, const ChatScreen()),
          ),
          GoRoute(
            path: '/gallery',
            pageBuilder: (context, state) => _buildSubPage(context, state, const GalleryScreen()),
          ),
          GoRoute(
            path: '/anti-gravity',
            pageBuilder: (context, state) => _buildSubPage(context, state, const AntiGravityGame()),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(state.error?.toString() ?? 'Unknown error'),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/login'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});

// Placeholder for ParentHomeworkView
class _ParentHomeworkView extends StatelessWidget {
  const _ParentHomeworkView();
  @override
  Widget build(BuildContext context) => const Center(child: Text('Parent Homework View'));
}
