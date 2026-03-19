// lib/core/providers/student_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/student_model.dart';
import '../providers/auth_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

final firestoreProvider = Provider((ref) => FirebaseFirestore.instance);

final studentsStreamProvider = StreamProvider<List<Student>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('students')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList());
});

final studentRepositoryProvider = Provider((ref) => StudentRepository(ref));

/// Holds the generated credentials of the most recently created student.
/// Reset to null when cleared.
class ParentCredentials {
  final String username;
  final String password;
  final String studentName;

  const ParentCredentials({
    required this.username,
    required this.password,
    required this.studentName,
  });
}

class StudentRepository {
  final Ref _ref;
  StudentRepository(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  Future<List<Student>> getAllStudentsFuture() async {
    final snapshot = await _firestore.collection('students').get();
    return snapshot.docs.map((doc) => Student.fromFirestore(doc)).toList();
  }

  // ---------------------------------------------------------------------------
  // Username Generation
  // ---------------------------------------------------------------------------

  /// Generates a unique parent username from the student's first name.
  /// Format: {firstname_lowercase}
  /// If duplicate exists, appends last 3 digits of parent phone.
  /// Example: "aarav", "aarav210"
  Future<String> generateParentUsername(String studentName, String phone) async {
    final firstName = studentName.trim().split(RegExp(r'\s+')).first.toLowerCase();
    // Remove non-alphanumeric chars
    final base = firstName.replaceAll(RegExp(r'[^a-z0-9]'), '');
    if (base.isEmpty) return 'parent${DateTime.now().millisecondsSinceEpoch}';

    final phoneClean = phone.replaceAll(RegExp(r'[^0-9]'), '');

    // 1. Check if base username is available in 'users' collection
    final doc = await _firestore.collection('users').doc(base).get();
    if (!doc.exists) return base;

    // 2. If exists, append last 3 digits of phone
    final suffix = phoneClean.length >= 3 
        ? phoneClean.substring(phoneClean.length - 3) 
        : phoneClean.padLeft(3, '0');
    
    final candidate = '$base$suffix';
    return candidate;
  }

  // ---------------------------------------------------------------------------
  // Add Student (Single)
  // ---------------------------------------------------------------------------

  /// Adds a student and auto-generates parent credentials.
  /// Returns the generated [ParentCredentials] for display in admin UI.
  Future<ParentCredentials> addStudent(Student student) async {
    // 1. Username is exactly the Student Name
    final username = student.name.trim();

    // 2. Password = parent mobile number (normalized to digits only)
    final password = student.phone.replaceAll(RegExp(r'[^0-9]'), '');

    // 3. Save student record (with parentUsername)
    final studentWithUsername = student.copyWith(parentUsername: username);
    final docRef = await _firestore
        .collection('students')
        .add(studentWithUsername.toFirestore());

    // 4. Store credentials in parent_credentials collection (hashed)
    await _saveParentCredentials(
      username: username,
      password: password,
      parentName: student.parent,
      parentEmail: student.parentEmail,
      parentMobile: student.phone,
      studentId: docRef.id,
      studentName: student.name,
    );

    return ParentCredentials(
      username: username,
      password: password, // This is now the digits-only version
      studentName: student.name,
    );
  }

  // ---------------------------------------------------------------------------
  // Bulk Add Students
  // ---------------------------------------------------------------------------

  /// Bulk adds students and returns a list of generated [ParentCredentials].
  Future<List<ParentCredentials>> bulkAddStudents(
      List<Student> students) async {
    final List<ParentCredentials> allCredentials = [];

    for (final student in students) {
      try {
        final creds = await addStudent(student);
        allCredentials.add(creds);
      } catch (e) {
        print('DEBUG: Error adding student ${student.name}: $e');
        // Continue with next student; partial failure is acceptable for bulk ops
      }
    }

    return allCredentials;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Persists parent credentials to Firestore `parent_credentials` collection.
  /// The password is stored as-is here (plain text for demo – in production
  /// you should hash it with bcrypt/argon2 via a Cloud Function).
  /// Also stores a `mustChangePassword` flag for first-login enforcement.
  Future<void> _saveParentCredentials({
    required String username,
    required String password,
    required String parentName,
    required String parentEmail,
    required String parentMobile,
    required String studentId,
    required String studentName,
  }) async {
    // Attempt real Firebase Auth user creation so firestore.rules validates them later
    String uid = username;
    final safeEmailPrefix = username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final emailForAuth = '${safeEmailPrefix}_${password}@hdpayment.preschool';
    
    try {
      final tempApp = await Firebase.initializeApp(
        name: 'tempAuthApp_${DateTime.now().millisecondsSinceEpoch}',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);
      
      try {
        final cred = await tempAuth.createUserWithEmailAndPassword(
          email: emailForAuth, 
          password: password,
        );
        if (cred.user != null) {
          uid = cred.user!.uid;
        }
      } catch (e) {
        // If a parent with this email already exists, retrieve the UID by logging in
        if (e.toString().contains('email-already-in-use')) {
           final cred = await tempAuth.signInWithEmailAndPassword(
             email: emailForAuth,
             password: password,
           );
           if (cred.user != null) {
             uid = cred.user!.uid;
           }
        } else {
          print('DEBUG: Secondary Auth User creation error: $e');
        }
      }
      await tempApp.delete();
    } catch (e) {
      print('DEBUG: Fatal Secondary Auth error: $e');
    }

    final passwordBytes = utf8.encode(password);
    final hashedPassword = sha256.convert(passwordBytes).toString();

    // Use the actual Firebase Auth UID as the document ID!
    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'username': username.toLowerCase(),
      'password': hashedPassword,
      'parentName': parentName,
      'parentEmail': parentEmail,
      'parentMobile': parentMobile,
      'studentId': studentId,
      'studentName': studentName,
      'role': 'parent',
      'status': 'active',
      'mustChangePassword': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }


  // ---------------------------------------------------------------------------
  // Student Code Generation
  // ---------------------------------------------------------------------------

  /// Generate a human-friendly student code that includes class, student name, and Aadhaar.
  /// Format: {CLASS}-{NAME_INITIALS}-{AADHAAR_LAST_4}
  /// Example: "NUR-RAJ-1234", "LKG-PRI-5678".
  Future<String> generateStudentCode(
      String className, String studentName, String aadhaarNumber) async {
    final classPrefix = _buildClassPrefix(className);
    final nameInitials = _buildNameInitials(studentName);
    final aadhaarLast4 = _getAadhaarLast4(aadhaarNumber);
    return '$classPrefix-$nameInitials-$aadhaarLast4';
  }

  String _buildClassPrefix(String className) {
    final parts = className.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'CLS';
    final first = parts[0].toUpperCase();
    final firstPart = first.length <= 3 ? first : first.substring(0, 3);
    if (parts.length == 1) return firstPart;
    final second = parts[1].toUpperCase();
    final secondPart = second.isNotEmpty ? second[0] : '';
    return '$firstPart-$secondPart';
  }

  String _buildNameInitials(String studentName) {
    final trimmed = studentName.trim();
    if (trimmed.isEmpty) return 'XXX';
    final firstWord = trimmed.split(RegExp(r'\s+')).first.toUpperCase();
    if (firstWord.length >= 3) return firstWord.substring(0, 3);
    return firstWord.padRight(3, 'X');
  }

  String _getAadhaarLast4(String aadhaarNumber) {
    final cleaned = aadhaarNumber.replaceAll(RegExp(r'[\s-]'), '');
    if (cleaned.length < 4) return cleaned.padLeft(4, '0');
    return cleaned.substring(cleaned.length - 4);
  }

  // ---------------------------------------------------------------------------
  // CRUD
  // ---------------------------------------------------------------------------

  Future<void> updateStudent(Student oldStudent, Student updatedStudent) async {
    String newUsername = updatedStudent.parentUsername ?? '';
    bool credentialsChanged = false;

    // 1. If name or phone changed, update username and rewrite credentials
    if (oldStudent.name != updatedStudent.name || oldStudent.phone != updatedStudent.phone) {
      newUsername = updatedStudent.name.trim();
      credentialsChanged = true;
    }

    final finalStudent = updatedStudent.copyWith(parentUsername: newUsername);
    
    // 2. Update student record
    await _firestore
        .collection('students')
        .doc(oldStudent.id)
        .update(finalStudent.toFirestore());

    // 3. Handle credentials migration if username changed or info updated
    if (newUsername.isNotEmpty) {
      final credRef = _firestore.collection('users').doc(newUsername);
      
      if (oldStudent.parentUsername != newUsername) {
        // Delete old credentials if username changed
        await _firestore.collection('users').doc(oldStudent.parentUsername).delete();
        
        // Create new ones with phone as default password
        final pass = updatedStudent.phone.replaceAll(RegExp(r'[^0-9]'), '');
        await _saveParentCredentials(
          username: newUsername,
          password: pass,
          parentName: updatedStudent.parent,
          parentEmail: updatedStudent.parentEmail,
          parentMobile: updatedStudent.phone.trim(),
          studentId: oldStudent.id,
          studentName: updatedStudent.name,
        );
      } else {
        // Just update existing credentials doc
        final credDoc = await credRef.get();
        if (credDoc.exists) {
           Map<String, dynamic> updates = {
             'parentName': updatedStudent.parent,
             'parentEmail': updatedStudent.parentEmail,
             'parentMobile': updatedStudent.phone.trim(),
             'studentName': updatedStudent.name,
             'role': 'parent',
             'status': 'active',
           };
           // If phone changed, reset password to new phone (applying the logic)
           if (oldStudent.phone != updatedStudent.phone) {
              final pass = updatedStudent.phone.replaceAll(RegExp(r'[^0-9]'), '');
              final passwordBytes = utf8.encode(pass);
              updates['password'] = sha256.convert(passwordBytes).toString();
              updates['mustChangePassword'] = false;
           }
           await credRef.update(updates);
        } else {
           // Recreate if missing
           final pass = updatedStudent.phone.replaceAll(RegExp(r'[^0-9]'), '');
           await _saveParentCredentials(
             username: newUsername,
             password: pass,
             parentName: updatedStudent.parent,
             parentEmail: updatedStudent.parentEmail,
             parentMobile: updatedStudent.phone.trim(),
             studentId: oldStudent.id,
             studentName: updatedStudent.name,
           );
        }
      }
    }
  }

  Future<Student?> getStudentById(String id) async {
    if (id.isEmpty) return null;
    final doc = await _firestore.collection('students').doc(id).get();
    if (!doc.exists) return null;
    return Student.fromFirestore(doc);
  }

  Future<void> deleteStudent(String id) async {
    await _firestore.collection('students').doc(id).delete();
  }
}

// ---------------------------------------------------------------------------
// Parent child lookup via parentEmail (fallback still works after migration)
// ---------------------------------------------------------------------------

/// Stream for the logged-in parent's child.
/// Priority: 1. studentId from AuthUser, 2. Email fallback, 3. Username fallback
final parentChildStudentProvider = StreamProvider<Student?>((ref) {
  final authState = ref.watch(authProvider);
  final user = authState.user;
  
  if (user == null) return const Stream<Student?>.empty();

  final firestore = ref.watch(firestoreProvider);

  // 1. Try by studentId if available
  if (user.studentId != null && user.studentId!.isNotEmpty) {
    return firestore
        .collection('students')
        .doc(user.studentId)
        .snapshots()
        .map((doc) => doc.exists ? Student.fromFirestore(doc) : null);
  }

  // 2. Fallback to Email
  if (user.email.isNotEmpty && !user.email.contains('demo')) {
    return firestore
        .collection('students')
        .where('parentEmail', isEqualTo: user.email)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? Student.fromFirestore(snapshot.docs.first) : null);
  }

  // 3. Fallback to Username
  if (user.username != null && user.username!.isNotEmpty) {
    return firestore
        .collection('students')
        .where('parentUsername', isEqualTo: user.username)
        .limit(1)
        .snapshots()
        .map((snapshot) => snapshot.docs.isNotEmpty ? Student.fromFirestore(snapshot.docs.first) : null);
  }

  return Stream.value(null);
});

