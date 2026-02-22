import 'package:cloud_firestore/cloud_firestore.dart';

class Subcategory {
  final String id;
  final String categoryId;
  final String name;
  final String imageUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Subcategory({
    required this.id,
    required this.categoryId,
    required this.name,
    required this.imageUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Subcategory.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return Subcategory(
      id: id,
      categoryId: json['category_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Unnamed Subcategory',
      imageUrl: json['image_url'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'name': name,
      'image_url': imageUrl,
      'is_active': isActive,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  Subcategory copyWith({
    String? categoryId,
    String? name,
    String? imageUrl,
    bool? isActive,
  }) {
    return Subcategory(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
