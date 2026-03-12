import 'package:cloud_firestore/cloud_firestore.dart';

class AppBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String actionType; // 'category', 'subcategory', 'product', 'external'
  final String? actionValue; // ID or URL
  final String templateType; // 'theme1', 'theme2', 'full_image', 'blank'
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
    this.templateType = 'theme1',
    this.isActive = true,
    this.order = 0,
    required this.createdAt,
  });

  factory AppBanner.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return AppBanner(
      id: id,
      imageUrl: (json['imageUrl'] ?? json['image_url']) as String? ?? '',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      actionType: (json['actionType'] ?? json['action_type']) as String? ?? 'category',
      actionValue: (json['actionValue'] ?? json['action_value']) as String?,
      templateType: (json['templateType'] ?? json['template_type']) as String? ?? 'theme1',
      isActive: (json['isActive'] ?? json['is_active']) as bool? ?? true,
      order: (json['order'] ?? 0) as int,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'imageUrl': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'actionType': actionType,
      'actionValue': actionValue,
      'templateType': templateType,
      'isActive': isActive,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  AppBanner copyWith({
    String? imageUrl,
    String? title,
    String? subtitle,
    String? actionType,
    String? actionValue,
    String? templateType,
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
      templateType: templateType ?? this.templateType,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
