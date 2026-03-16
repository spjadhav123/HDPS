// lib/core/utils/validators.dart

class Validators {
  static String? required(String? value, [String fieldName = 'Field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? aadhaar(String? value) {
    if (value == null || value.trim().isEmpty) return 'Aadhaar number is required';
    final cleaned = value.replaceAll(RegExp(r'\s'), '');
    if (cleaned.length != 12) return 'Aadhaar must be 12 digits';
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) return 'Aadhaar must contain only digits';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final cleaned = value.replaceAll(RegExp(r'[\s\-\+]'), '');
    if (cleaned.length < 10) return 'Enter a valid phone number';
    return null;
  }

  static String? minLength(String? value, int min, [String fieldName = 'Field']) {
    final err = required(value, fieldName);
    if (err != null) return err;
    if (value!.length < min) return '$fieldName must be at least $min characters';
    return null;
  }

  static String? amount(String? value) {
    if (value == null || value.trim().isEmpty) return 'Amount is required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null) return 'Enter a valid amount';
    if (parsed <= 0) return 'Amount must be greater than 0';
    return null;
  }
}
