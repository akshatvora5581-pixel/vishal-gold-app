import 'package:cloud_firestore/cloud_firestore.dart';

class AppBanner {
  final String id;
  final String imageUrl;
  final String? title;
  final String? subtitle;
  final String actionType; // 'category', 'subcategory', 'product', 'external'
  final String? actionValue; // ID or URL
  final String templateType; // 'theme1', 'theme2', 'full_image', 'blank'
  final String termsAndConditions;
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
    this.termsAndConditions = '*T&C Applied',
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
      imageUrl: (json['image_url'] ?? json['imageUrl']) as String? ?? '',
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      actionType: (json['action_type'] ?? json['actionType']) as String? ?? 'category',
      actionValue: (json['action_value'] ?? json['actionValue']) as String?,
      templateType: (json['template_type'] ?? json['templateType']) as String? ?? 'theme1',
      termsAndConditions: (json['terms_and_conditions'] ?? json['termsAndConditions'] ?? '*T&C Applied') as String,
      isActive: (json['is_active'] ?? json['isActive'] ?? true) as bool,
      order: (json['order'] ?? 0) as int,
      createdAt: parseDate(json['created_at'] ?? json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'title': title,
      'subtitle': subtitle,
      'action_type': actionType,
      'action_value': actionValue,
      'template_type': templateType,
      'terms_and_conditions': termsAndConditions,
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
    String? templateType,
    String? termsAndConditions,
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
      termsAndConditions: termsAndConditions ?? this.termsAndConditions,
      isActive: isActive ?? this.isActive,
      order: order ?? this.order,
      createdAt: createdAt,
    );
  }
}
