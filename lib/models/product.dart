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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      tagNumber: json['tag_number'] as String,
      category: json['category'] as String,
      subcategory: json['subcategory'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      imageUrls: (json['image_urls'] as List<dynamic>).cast<String>(),
      grossWeight: (json['gross_weight'] as num).toDouble(),
      netWeight: (json['net_weight'] as num).toDouble(),
      purity: json['purity'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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

  String get weightDisplay {
    return '${grossWeight.toStringAsFixed(2)}g';
  }

  /// Create empty product
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
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
