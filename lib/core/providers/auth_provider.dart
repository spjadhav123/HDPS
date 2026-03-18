// lib/core/providers/auth_provider.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class AuthUser {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? username;
  final bool? mustChangePassword;
  final String? studentId;

  const AuthUser({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.username,
    this.mustChangePassword,
    this.studentId,
  });
}

class AuthState {
  final AuthUser? user;
  final bool isLoading;
  final String? error;

  const AuthState({this.user, this.isLoading = false, this.error});

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    AuthUser? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  AuthNotifier() : super(const AuthState()) {
    _init();
  }

  void _init() {
    _auth.authStateChanges().listen((user) {
      if (user == null) {
        // If Firebase has no user but we already have a local demo user
        // in state, keep that session instead of clearing it. This lets
        // the app work even when Firebase isn't fully configured.
        if (state.user != null) {
          return;
        }
        state = state.copyWith(clearUser: true);
      } else if (user.isAnonymous) {
        // If anonymous, we trust the state set during the login() bypass.
        // If state is empty (e.g. on app restart with existing anon session),
        // we default to Parent or just keep it empty/loading.
        if (state.user == null) {
          state = state.copyWith(
            user: const AuthUser(
              uid: 'anonymous',
              email: 'guest@demo.com',
              name: 'Guest User',
              role: 'parent',
            ),
          );
        }
      } else {
        // If state already has a user (e.g. from parentLogin or demo sign-in),
        // don't overwrite it with a half-baked session from authStateChanges.
        if (state.user != null) {
           return;
        }

        // For non-anonymous users, prefer keeping any existing role/name
        // already stored in state for this email (e.g. from signup),
        // otherwise fall back to demo users mapping or default parent.
        if (state.user != null &&
            state.user!.email.toLowerCase() ==
                (user.email ?? '').toLowerCase()) {
          state = state.copyWith(
            user: AuthUser(
              uid: user.uid,
              email: user.email ?? state.user!.email,
              name: state.user!.name,
              role: state.user!.role,
              username: state.user!.username,
              studentId: state.user!.studentId,
              mustChangePassword: state.user!.mustChangePassword,
            ),
          );
        } else {
          // Find role from email (for regular users)
          final userMap = AppConstants.demoUsers.entries
              .firstWhere(
                (e) =>
                    e.key.toLowerCase() == user.email?.toLowerCase(),
                orElse: () =>
                    const MapEntry('', {'role': 'parent', 'name': 'Parent'}),
              )
              .value;

          state = state.copyWith(
            user: AuthUser(
              uid: user.uid,
              email: user.email ?? 'anonymous',
              name: userMap['name']!,
              role: userMap['role']!,
            ),
          );
        }
      }
    });
  }

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.toLowerCase().trim();
    print('DEBUG: Attempting login for $normalizedEmail');

    try {
      // 1. Check if it's a demo user
      final demoUser = AppConstants.demoUsers[normalizedEmail];
      final bool isDemo = demoUser != null;

      if (isDemo) {
        print('DEBUG: Demo user detected! Logging in without requiring Firebase.');

        // Try to sign in anonymously if Firebase is available, but don't
        // fail the login if this throws (e.g. Firebase not configured).
        String uid = 'demo-$normalizedEmail';
        try {
          final cred = await _auth.signInAnonymously();
          if (cred.user != null) {
            uid = cred.user!.uid;
          }
          print('DEBUG: Anonymous sign-in (optional) success: ${cred.user?.uid}');
        } catch (e) {
          print('DEBUG: Optional anonymous sign-in failed, continuing with local demo session: $e');
        }

        // Manually update state – this is now the source of truth for demo users.
        state = state.copyWith(
          isLoading: false,
          user: AuthUser(
            uid: uid,
            email: normalizedEmail,
            name: demoUser['name']!,
            role: demoUser['role']!,
          ),
        );
        return true;
      }

      print('DEBUG: Not a demo user. Attempting real login...');
      // 2. Regular login attempts
      final cred = await _auth.signInWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );
      
      // After successful login, return true
      state = state.copyWith(
        isLoading: false,
        user: AuthUser(
          uid: cred.user!.uid,
          email: normalizedEmail,
          name: cred.user!.displayName ?? 'Staff',
          role: 'admin', // Default to admin for regular login, or handle properly
        ),
      );
      return true;
    } catch (e) {
      print('DEBUG: Login error: $e');
      String errorMessage = 'Login failed';
      
      // Provide user-friendly error messages
      if (e.toString().contains('user-not-found')) {
        errorMessage = 'No account found with this email. Please contact the admin.';
      } else if (e.toString().contains('wrong-password')) {
        errorMessage = 'Incorrect password. Please use the Aadhaar number provided by the admin.';
      } else if (e.toString().contains('invalid-email')) {
        errorMessage = 'Invalid email address.';
      } else if (e.toString().contains('too-many-requests')) {
        errorMessage = 'Too many login attempts. Please try again later.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error. Please check your connection.';
      } else {
        errorMessage = 'Login failed: ${e.toString()}';
      }
      
      state = state.copyWith(
        isLoading: false,
        error: errorMessage,
      );
      return false;
    }
  }

  Future<bool> parentLogin(String username, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedUsername = username.trim().toLowerCase();
    
    // Normalize password to digits only to match stored format
    final normalizedPassword = password.replaceAll(RegExp(r'[^0-9]'), '');
    
    print('DEBUG: [ParentLogin] Username: $normalizedUsername');

    try {
      // Direct Firebase Authentication using the background-mapped email
      final emailForAuth = '$normalizedUsername@hdpayment.preschool';
      
      final cred = await _auth.signInWithEmailAndPassword(
        email: emailForAuth,
        password: normalizedPassword,
      );

      final uid = cred.user!.uid;

      // Now that the user is authentically signed in natively, they bypass 
      // the lock in firestore.rules and can read their own data to verify role/status.
      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
         state = state.copyWith(isLoading: false, error: 'Database record missing.');
         await _auth.signOut();
         return false;
      }

      final userData = userDoc.data()!;
      final role = userData['role'] as String? ?? '';
      if (role.toLowerCase() != 'parent') {
        state = state.copyWith(isLoading: false, error: 'Unauthorized access.');
        await _auth.signOut();
        return false;
      }

      final status = userData['status'] as String? ?? '';
      if (status.toLowerCase() != 'active') {
        state = state.copyWith(isLoading: false, error: 'Parent account not active. Please contact administrator.');
        await _auth.signOut();
        return false;
      }

      final parentEmail = userData['parentEmail'] as String? ?? '';
      final parentName = userData['parentName'] as String? ?? 'Parent';
      final studentId = userData['studentId'] as String? ?? '';
      final mustChangePassword = userData['mustChangePassword'] as bool? ?? false;

      // Create local session
      state = state.copyWith(
        isLoading: false,
        user: AuthUser(
          uid: uid,
          email: parentEmail,
          name: parentName,
          role: 'parent',
          username: normalizedUsername,
          mustChangePassword: mustChangePassword,
          studentId: studentId,
        ),
      );
      
      return true;
    } on FirebaseAuthException catch (e) {
      print('DEBUG: [ParentLogin] FirebaseAuthException: ${e.code}');
      String errMsg = 'Login failed.';
      if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
         errMsg = 'Invalid Username or Password.';
      } else if (e.code == 'wrong-password') {
         errMsg = 'Incorrect Password.';
      }
      state = state.copyWith(isLoading: false, error: errMsg);
      return false;
    } catch (e) {
      print('DEBUG: [ParentLogin] General Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Login Error. Verify credentials.',
      );
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    if (state.user == null || state.user!.username == null) return false;
    
    state = state.copyWith(isLoading: true, clearError: true);
    final username = state.user!.username!;

    try {
      final passwordBytes = utf8.encode(newPassword.trim());
      final hashedPassword = sha256.convert(passwordBytes).toString();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(username)
          .update({
        'password': hashedPassword,
        'mustChangePassword': false,
      });

      // Update local state
      state = state.copyWith(
        isLoading: false,
        user: AuthUser(
          uid: state.user!.uid,
          email: state.user!.email,
          name: state.user!.name,
          role: state.user!.role,
          username: state.user!.username,
          mustChangePassword: false,
        ),
      );
      return true;
    } catch (e) {
      print('DEBUG: Change Password error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update password: ${e.toString()}',
      );
      return false;
    }
  }

  Future<void> logout() async {
    // Clear local auth state first so the app immediately treats the
    // user as logged out, regardless of Firebase behavior.
    state = state.copyWith(clearUser: true, isLoading: false);
    await _auth.signOut();
  }

  /// Register a new user with email/password and a chosen role.
  /// On success, [state.user] is updated and the router redirect
  /// will send the user to the appropriate dashboard.
  Future<bool> register(
    String email,
    String password,
    String name,
    String role,
  ) async {
    state = state.copyWith(isLoading: true, clearError: true);
    final normalizedEmail = email.toLowerCase().trim();
    print('DEBUG: Attempting registration for $normalizedEmail as $role');

    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password,
      );

      final user = cred.user;
      if (user == null) {
        throw Exception('User creation failed');
      }

      // Store the role/name directly in state. The auth state listener
      // is written to preserve this information for this email.
      state = state.copyWith(
        isLoading: false,
        user: AuthUser(
          uid: user.uid,
          email: normalizedEmail,
          name: name,
          role: role,
        ),
      );

      return true;
    } catch (e) {
      print('DEBUG: Registration error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(),
);
