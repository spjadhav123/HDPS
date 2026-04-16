// lib/core/providers/gallery_provider.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/gallery_model.dart';
import 'student_provider.dart';

final storageProvider = Provider((ref) => FirebaseStorage.instance);

/// Stream all gallery albums.
final galleryAlbumsProvider = StreamProvider<List<GalleryAlbum>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('gallery')
      // .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        try {
          return GalleryAlbum.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing album ${doc.id}: $e');
          return null;
        }
      }).whereType<GalleryAlbum>().toList());
});

/// Stream photos for a specific album.
final albumPhotosProvider = StreamProvider.family<List<GalleryPhoto>, String>((ref, albumId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('gallery')
      .doc(albumId)
      .collection('photos')
      // .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((doc) {
        try {
          return GalleryPhoto.fromFirestore(doc);
        } catch (e) {
          debugPrint('Error parsing photo ${doc.id}: $e');
          return null;
        }
      }).whereType<GalleryPhoto>().toList());
});

final galleryRepositoryProvider = Provider((ref) => GalleryRepository(ref));

class GalleryRepository {
  final Ref _ref;
  GalleryRepository(this._ref);

  FirebaseFirestore get _db => _ref.read(firestoreProvider);
  FirebaseStorage get _storage => _ref.read(storageProvider);

  Future<String> uploadPhoto(dynamic file, String albumId) async {
    try {
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('gallery/$albumId/$fileName');
      
      UploadTask uploadTask;
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      if (kIsWeb) {
        uploadTask = ref.putData(file as Uint8List, metadata);
      } else {
        uploadTask = ref.putFile(file as File, metadata);
      }
      
      // Attempt to upload but timeout after 5 seconds to prevent hanging on permission/CORS errors
      final snapshot = await uploadTask.timeout(const Duration(seconds: 5));
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      debugPrint('Firebase Storage upload failed or timed out ($e). Falling back to Base64 encoding.');
      // If the upload failed/timed out (e.g. from missing auth/CORS on Firebase), we fallback to base64 embedded URI.
      if (kIsWeb) {
        final b64 = base64Encode(file as Uint8List);
        return 'data:image/jpeg;base64,$b64';
      } else {
        final bytes = await (file as File).readAsBytes();
        final b64 = base64Encode(bytes);
        return 'data:image/jpeg;base64,$b64';
      }
    }
  }

  Future<String> createAlbum(GalleryAlbum album) async {
    final ref = await _db.collection('gallery').add(album.toFirestore());
    return ref.id;
  }

  Future<void> addPhotoToAlbum(String albumId, GalleryPhoto photo) async {
    final batch = _db.batch();
    
    // Add photo
    final photoRef = _db.collection('gallery').doc(albumId).collection('photos').doc();
    batch.set(photoRef, photo.toFirestore());
    
    // Increment photo count in album
    final albumRef = _db.collection('gallery').doc(albumId);
    batch.update(albumRef, {
      'photoCount': FieldValue.increment(1),
      'coverUrl': photo.url, // Update cover to latest photo
    });
    
    await batch.commit();
  }

  Future<void> deleteAlbum(String albumId) async {
    // Delete photos subcollection first (optional but cleaner)
    final photos = await _db.collection('gallery').doc(albumId).collection('photos').get();
    final batch = _db.batch();
    for (var doc in photos.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(_db.collection('gallery').doc(albumId));
    await batch.commit();
  }

  Future<void> deletePhoto(String albumId, String photoId) async {
    final batch = _db.batch();
    
    // Delete photo doc
    final photoRef = _db.collection('gallery').doc(albumId).collection('photos').doc(photoId);
    batch.delete(photoRef);
    
    // Decrement photo count in album
    final albumRef = _db.collection('gallery').doc(albumId);
    batch.update(albumRef, {
      'photoCount': FieldValue.increment(-1),
    });
    
    await batch.commit();
  }
}
