// lib/core/constants/app_constants.dart
class AppConstants {
  static const String appName = 'HD Preprimary School';
  static const String appTagline = 'Nurturing Young Minds';

  // Mock roles
  static const String roleAdmin = 'admin';
  static const String roleTeacher = 'teacher';
  static const String roleAccountant = 'accountant';
  static const String roleParent = 'parent';

  // Demo credentials
  static const Map<String, Map<String, String>> demoUsers = {
    'admin': {
      'password': 'sneha@123',
      'role': roleAdmin,
      'name': 'Admin Principal',
    },
    'teacher@humptydumpty.edu': {
      'password': 'teacher123',
      'role': roleTeacher,
      'name': 'Mrs. Sarah Johnson',
    },
    'accountant@humptydumpty.edu': {
      'password': 'account123',
      'role': roleAccountant,
      'name': 'Mr. Raj Kumar',
    },
    'parent@humptydumpty.edu': {
      'password': 'parent123',
      'role': roleParent,
      'name': 'Mrs. Priya Sharma',
    },
  };
}
