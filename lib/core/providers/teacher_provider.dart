// lib/core/providers/teacher_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../models/teacher_model.dart';
import 'student_provider.dart'; // Reusing firestoreProvider

final teachersStreamProvider = StreamProvider<List<Teacher>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('teachers')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) =>
          snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList());
});

final teacherRepositoryProvider = Provider((ref) => TeacherRepository(ref));

class TeacherRepository {
  final Ref _ref;
  TeacherRepository(this._ref);

  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  Future<void> addTeacher(Teacher teacher) async {
    await _firestore.collection('teachers').add(teacher.toFirestore());
    
    // Save generated credentials
    final username = teacher.name.trim();
    final digits = teacher.phone.replaceAll(RegExp(r'[^0-9]'), '');
    final password = digits.length > 10 ? digits.substring(digits.length - 10) : digits;

    await _saveTeacherCredentials(
      username: username,
      password: password,
      teacherName: teacher.name,
      teacherEmail: teacher.email,
      teacherMobile: teacher.phone,
      role: 'teacher',
    );
  }

  Future<void> updateTeacher(Teacher teacher) async {
    await _firestore.collection('teachers').doc(teacher.id).update(teacher.toFirestore());
  }

  Future<void> deleteTeacher(String id) async {
    await _firestore.collection('teachers').doc(id).delete();
  }

  Future<void> _saveTeacherCredentials({
    required String username,
    required String password,
    required String teacherName,
    required String teacherEmail,
    required String teacherMobile,
    required String role,
  }) async {
    String uid = username;
    final safeEmailPrefix = username.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
    final emailForAuth = '${safeEmailPrefix}_$password@hdpayment.preschool';
    
    try {
      FirebaseApp adminApp;
      try {
        adminApp = Firebase.app('adminApp');
      } catch (e) {
        adminApp = await Firebase.initializeApp(
          name: 'adminApp',
          options: Firebase.app().options,
        );
      }
      final tempAuth = FirebaseAuth.instanceFor(app: adminApp);
      
      try {
        final cred = await tempAuth.createUserWithEmailAndPassword(
          email: emailForAuth, 
          password: password,
        );
        if (cred.user != null) {
          uid = cred.user!.uid;
        }
      } catch (e) {
        if (e.toString().contains('email-already-in-use')) {
           final cred = await tempAuth.signInWithEmailAndPassword(
             email: emailForAuth,
             password: password,
           );
           if (cred.user != null) {
             uid = cred.user!.uid;
           }
        }
      }
    } catch (e) {
      print('DEBUG: Fatal Secondary Auth error: $e');
    }

    final passwordBytes = utf8.encode(password);
    final hashedPassword = sha256.convert(passwordBytes).toString();

    await _firestore.collection('users').doc(uid).set({
      'uid': uid,
      'username': username.toLowerCase(),
      'password': hashedPassword,
      'teacherName': teacherName,
      'teacherEmail': teacherEmail,
      'teacherMobile': teacherMobile,
      'role': role,
      'status': 'active',
      'mustChangePassword': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> repairAllTeacherCredentials() async {
    final snapshot = await _firestore.collection('teachers').get();
    final teachers = snapshot.docs.map((d) => Teacher.fromFirestore(d)).toList();

    for (final teacher in teachers) {
      if (teacher.name.isEmpty || teacher.phone.isEmpty) continue;
      
      final username = teacher.name.trim();
      final digits = teacher.phone.replaceAll(RegExp(r'[^0-9]'), '');
      final pass = digits.length > 10 ? digits.substring(digits.length - 10) : digits;
      
      try {
        await _saveTeacherCredentials(
          username: username,
          password: pass,
          teacherName: teacher.name,
          teacherEmail: teacher.email,
          teacherMobile: teacher.phone.trim(),
          role: 'teacher',
        );
      } catch (e) {
        print('DEBUG: Repair error for ${teacher.name}: $e');
      }
    }
  }

  Future<List<Teacher>> getAllTeachersFuture() async {
    final snapshot = await _firestore.collection('teachers').orderBy('createdAt', descending: true).get();
    return snapshot.docs.map((doc) => Teacher.fromFirestore(doc)).toList();
  }
}
