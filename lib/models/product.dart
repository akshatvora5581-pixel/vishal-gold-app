import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final String tagNumber;
  final String category;
  final String subcategory;
  final String? name;
  final String? description;
  final List<String> imageUrls;
  final double grossWeight;
  final double netWeight;
  final int purity; // 84 or 92
  final bool isActive;
  final String status; // 'draft' | 'published'
  final String inventoryStatus; // 'in_stock' | 'sold_out' | 'on_order'
  final int version;
  final DateTime? lastPublishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product({
    required this.id,
    required this.tagNumber,
    required this.category,
    required this.subcategory,
    this.name,
    this.description,
    required this.imageUrls,
    required this.grossWeight,
    required this.netWeight,
    required this.purity,
    this.isActive = true,
    this.status = 'published',
    this.inventoryStatus = 'in_stock',
    this.version = 1,
    this.lastPublishedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return Product(
      id: json['id'] as String? ?? '',
      tagNumber: json['tag_number'] as String? ?? '',
      category: json['category'] as String? ?? '',
      subcategory: json['subcategory'] as String? ?? '',
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>?)?.cast<String>() ?? [],
      grossWeight: (json['gross_weight'] as num?)?.toDouble() ?? 0.0,
      netWeight: (json['net_weight'] as num?)?.toDouble() ?? 0.0,
      purity: json['purity'] as int? ?? 84,
      isActive: json['is_active'] as bool? ?? true,
      status: json['status'] as String? ?? 'published',
      inventoryStatus: json['inventory_status'] as String? ?? 'in_stock',
      version: json['version'] as int? ?? 1,
      lastPublishedAt: json['last_published_at'] != null
          ? parseDate(json['last_published_at'])
          : null,
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tag_number': tagNumber,
      'category': category,
      'subcategory': subcategory,
      'name': name,
      'description': description,
      'image_urls': imageUrls,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'purity': purity,
      'is_active': isActive,
      'status': status,
      'inventory_status': inventoryStatus,
      'version': version,
      'last_published_at': lastPublishedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  String get categoryDisplay {
    switch (category) {
      case '84_melting':
        return '84 Melting';
      case '92_melting':
        return '92 Melting';
      case '92_melting_chains':
        return '92 Melting Chains';
      default:
        return category.replaceAll('_', ' ').toUpperCase();
    }
  }

  String get purityDisplay {
    return '$purity (${purity == 84 ? '20K' : '22K'})';
  }

  String get inventoryStatusDisplay {
    switch (inventoryStatus) {
      case 'sold_out':
        return 'Sold Out';
      case 'on_order':
        return 'On Order';
      default:
        return 'In Stock';
    }
  }

  String get weightDisplay {
    return '${grossWeight.toStringAsFixed(2)}g';
  }

  double calculateEstimatedPrice({
    required double baseRatePerGram,
    required double makingChargePerGram,
    required double makingChargeFlat,
  }) {
    final weightPrice = netWeight * baseRatePerGram;
    final totalMaking = (netWeight * makingChargePerGram) + makingChargeFlat;
    return weightPrice + totalMaking;
  }

  factory Product.empty() {
    return Product(
      id: '',
      tagNumber: '',
      category: '',
      subcategory: '',
      imageUrls: [],
      grossWeight: 0.0,
      netWeight: 0.0,
      purity: 84,
      inventoryStatus: 'in_stock',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
