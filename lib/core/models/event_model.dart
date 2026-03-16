// lib/core/models/event_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum EventCategory { academic, cultural, sports, holiday, other }

/// Extension so categoryLabel is callable directly on EventCategory enum values.
extension EventCategoryX on EventCategory {
  String get categoryLabel {
    switch (this) {
      case EventCategory.academic:
        return 'Academic';
      case EventCategory.cultural:
        return 'Cultural';
      case EventCategory.sports:
        return 'Sports';
      case EventCategory.holiday:
        return 'Holiday';
      case EventCategory.other:
        return 'Other';
    }
  }
}

class SchoolEvent {
  final String id;
  final String title;
  final String description;
  final DateTime date;
  final EventCategory category;
  final String? imageUrl;
  final String createdBy;
  final DateTime createdAt;

  const SchoolEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.category,
    this.imageUrl,
    required this.createdBy,
    required this.createdAt,
  });

  factory SchoolEvent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SchoolEvent(
      id: doc.id,
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: _parseCategory(data['category'] as String? ?? 'other'),
      imageUrl: data['imageUrl'] as String?,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt:
          (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'category': category.name,
        'imageUrl': imageUrl,
        'createdBy': createdBy,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static EventCategory _parseCategory(String s) {
    return EventCategory.values.firstWhere(
      (e) => e.name == s,
      orElse: () => EventCategory.other,
    );
  }

  /// Delegates to the extension for convenience on SchoolEvent instances.
  String get categoryLabel => category.categoryLabel;
}
