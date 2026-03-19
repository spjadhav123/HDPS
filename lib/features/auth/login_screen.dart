import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../shared/widgets/app_animations.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _aadhaarController = TextEditingController();
  bool _obscurePassword = true;
  String? _selectedDemo;

  @override
  void dispose() {
    _emailController.dispose();
    _aadhaarController.dispose();
    super.dispose();
  }

  Future<void> _fillDemo(String email, String password) async {
    setState(() {
      _selectedDemo = email;
    });
    
    // Auto-login for demo chips to bypass the need for hidden staff fields
    final success = await ref.read(authProvider.notifier).login(email, password);
    
    if (!success && mounted) {
      AppToast.show(
        context,
        message: ref.read(authProvider).error ?? 'Login failed',
        type: ToastType.error,
      );
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    
    final credential = _emailController.text.trim();
    final password = _aadhaarController.text.trim();

    // 1. Check if it's a demo user (staff/admin)
    if (AppConstants.demoUsers.containsKey(credential.toLowerCase())) {
      final success = await ref.read(authProvider.notifier).login(credential, password);
      if (!success && mounted) {
        AppToast.show(
          context,
          message: ref.read(authProvider).error ?? 'Staff login failed',
          type: ToastType.error,
        );
      }
      return;
    }
    
    // 2. Try Parent Login (Username based)
    final success = await ref.read(authProvider.notifier).parentLogin(credential, password);
    
    // 3. Fallback: If parent login failed and it looks like an email, try regular Firebase login
    if (!success && credential.contains('@') && mounted) {
      final fallbackSuccess = await ref.read(authProvider.notifier).login(credential, password);
      if (fallbackSuccess) return;
    }

    if (!success && mounted) {
      AppToast.show(
        context,
        message: ref.read(authProvider).error ?? 'Login failed',
        type: ToastType.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;

    return Scaffold(
      body: Row(
        children: [
          if (isWide)
            Expanded(
              child: _buildBranding()
                  .animate()
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.1),
            ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(40),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: _buildForm(authState, isWide)
                        .animate()
                        .fadeIn(duration: 500.ms, delay: 200.ms)
                        .slideY(begin: 0.05),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranding() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primary, Color(0xFF9C8FFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Transform.scale(
                scale: 2.2,
                alignment: Alignment.center,
                child: Image.asset('assets/images/logo.jpg', fit: BoxFit.contain),
              ),
            ),
          )
              .animate()
              .scale(
                begin: const Offset(0.4, 0.4),
                end: const Offset(1.0, 1.0),
                duration: 600.ms,
                curve: Curves.elasticOut,
              )
              .then(delay: 1000.ms)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(end: 1.04, duration: 1800.ms, curve: Curves.easeInOut),
          const SizedBox(height: 32),
          const Text(
            'HD Preprimary School',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const Text(
            'Pre-Primary School',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w400,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Nurturing Young Minds',
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
          const SizedBox(height: 60),
          _buildFeatureRow(Icons.people_rounded, 'Manage Students & Staff')
              .animate().fadeIn(duration: 350.ms, delay: 500.ms).slideX(begin: 0.1, curve: Curves.easeOut),
          _buildFeatureRow(Icons.receipt_long_rounded, 'Fee Receipts & Payments')
              .animate().fadeIn(duration: 350.ms, delay: 600.ms).slideX(begin: 0.1, curve: Curves.easeOut),
          _buildFeatureRow(Icons.bar_chart_rounded, 'Reports & Analytics')
              .animate().fadeIn(duration: 350.ms, delay: 700.ms).slideX(begin: 0.1, curve: Curves.easeOut),
          _buildFeatureRow(Icons.notifications_rounded, 'Parent Communication')
              .animate().fadeIn(duration: 350.ms, delay: 800.ms).slideX(begin: 0.1, curve: Curves.easeOut),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 48),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(width: 12),
          Text(label,
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildForm(AuthState authState, bool isWide) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isWide) ...[
            Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Transform.scale(
                  scale: 2.2,
                  alignment: Alignment.center,
                  child: Image.asset('assets/images/logo.jpg', height: 80, width: 80, fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Text(
            'Welcome Back 👋',
            style: TextStyle(
              fontSize: isWide ? 28 : 24,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to your account to continue',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 32),

          const SizedBox(height: 32),
          
          const Text(
            'Secure Login',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(height: 16),

          AnimatedFocusField(
            controller: _emailController,
            labelText: 'Student Name (Username)',
            prefixIcon: const Icon(Icons.person_outlined, size: 20),
            hintText: 'Enter the exact student name',
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter the student name';
              return null;
            },
          ).animate().fadeIn(duration: 300.ms, delay: 280.ms).slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 16),

          AnimatedFocusField(
            controller: _aadhaarController,
            obscureText: _obscurePassword,
            labelText: 'Mobile Number (Password)',
            prefixIcon: const Icon(Icons.lock_outline, size: 20),
            hintText: 'Enter registered mobile number',
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined, size: 20),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Enter the password'
                : null,
          ).animate().fadeIn(duration: 300.ms, delay: 360.ms).slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 28),

          SizedBox(
            width: double.infinity,
            height: 50,
            child: AppButton(
              onPressed: _login,
              isLoading: authState.isLoading,
              child: const Text('Sign In', textAlign: TextAlign.center, style: TextStyle(fontSize: 15)),
            ),
          ).animate().fadeIn(duration: 300.ms, delay: 440.ms).slideY(begin: 0.06, curve: Curves.easeOut),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Don't have an account? ",
                style:
                    TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              TextButton(
                onPressed: () => context.go('/signup'),
                child: const Text('Sign Up'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'HD Preprimary School\nManagement System v1.0',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
