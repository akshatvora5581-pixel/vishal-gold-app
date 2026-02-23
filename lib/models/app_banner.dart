import 'package:cloud_firestore/cloud_firestore.dart';

class AppBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String actionType; // 'category', 'subcategory', 'product', 'external'
  final String? actionValue; // ID or URL
  final bool isActive;
  final int order;
  final DateTime createdAt;

  AppBanner({
    required this.id,
    required this.imageUrl,
    this.title,
    this.subtitle,
    required this.actionType,
    this.actionValue,
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json, String id) {
    return AppBanner(
      id: id,
      imageUrl: json['image_url'] as String? ?? '',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      actionType: json['action_type'] as String? ?? 'category',
      actionValue: json['action_value'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      order: (json['order'] ?? 0) as int,
      createdAt: (json['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'action_type': actionType,
      'action_value': actionValue,
      'is_active': isActive,
      'order': order,
      'created_at': Timestamp.fromDate(createdAt),
    };
  }

  AppBanner copyWith({
    String? imageUrl,
    String? title,
    String? subtitle,
    String? actionType,
    String? actionValue,
    bool? isActive,
    int? order,
  }) {
    return AppBanner(
      id: id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      actionType: actionType ?? this.actionType,
      actionValue: actionValue ?? this.actionValue,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
