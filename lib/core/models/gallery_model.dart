// lib/core/models/gallery_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class GalleryPhoto {
  final String id;
  final String url;
  final String description;
  final DateTime createdAt;

  const GalleryPhoto({
    required this.id,
    required this.url,
    required this.description,
    required this.createdAt,
  });

  factory GalleryPhoto.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryPhoto(
      id: doc.id,
      url: data['url'] as String? ?? '',
      description: data['description'] as String? ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'url': url,
        'description': description,
        'createdAt': FieldValue.serverTimestamp(),
      };
}

class GalleryAlbum {
  final String id;
  final String title;
  final String description;
  final String coverUrl;
  final int photoCount;
  final DateTime createdAt;

  const GalleryAlbum({
    required this.id,
    required this.title,
    required this.description,
    required this.coverUrl,
    required this.photoCount,
    required this.createdAt,
  });

  factory GalleryAlbum.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GalleryAlbum(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      coverUrl: data['coverUrl'] as String? ?? '',
      photoCount: data['photoCount'] as int? ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'coverUrl': coverUrl,
        'photoCount': photoCount,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
