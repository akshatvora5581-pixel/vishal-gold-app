import 'package:cloud_firestore/cloud_firestore.dart';

class Category {
  final String id;
  final String name;
  final String imageUrl;
  final List<String> purityOptions;
  final double makingChargePerGram;
  final double makingChargeFlat;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.imageUrl,
    this.purityOptions = const ['18K', '20K', '22K'],
    this.makingChargePerGram = 0.0,
    this.makingChargeFlat = 0.0,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Category.fromJson(Map<String, dynamic> json, String id) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return Category(
      id: id,
      name: json['name'] as String? ?? 'Unnamed Category',
      imageUrl: json['image_url'] as String? ?? '',
      purityOptions:
          (json['purity_options'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const ['18K', '20K', '22K'],
      makingChargePerGram: (json['makingChargePerGram'] ?? json['making_charge_per_gram'] ?? 0.0).toDouble(),
      makingChargeFlat: (json['makingChargeFlat'] ?? json['making_charge_flat'] ?? 0.0).toDouble(),
      isActive: json['isActive'] as bool? ?? json['is_active'] as bool? ?? true,
      createdAt: parseDate(json['createdAt'] ?? json['created_at']),
      updatedAt: parseDate(json['updatedAt'] ?? json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'imageUrl': imageUrl,
      'purityOptions': purityOptions,
      'makingChargePerGram': makingChargePerGram,
      'makingChargeFlat': makingChargeFlat,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  Category copyWith({
    String? name,
    String? imageUrl,
    List<String>? purityOptions,
    double? makingChargePerGram,
    double? makingChargeFlat,
    bool? isActive,
  }) {
    return Category(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      purityOptions: purityOptions ?? this.purityOptions,
      makingChargePerGram: makingChargePerGram ?? this.makingChargePerGram,
      makingChargeFlat: makingChargeFlat ?? this.makingChargeFlat,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
