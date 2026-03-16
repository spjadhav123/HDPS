// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    throw UnsupportedError(
      'DefaultFirebaseOptions are not supported for this platform.',
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyCTiLYkm12pE_DEJAvgE991EbvpX3yh8yo",
    authDomain: "humdumppreschool.firebaseapp.com",
    projectId: "humdumppreschool",
    storageBucket: "humdumppreschool.firebasestorage.app",
    messagingSenderId: "677149786605",
    appId: "1:677149786605:web:75bdf325f9d380a8ac67e4",
    measurementId: "G-15592HVFVL",
  );
}
