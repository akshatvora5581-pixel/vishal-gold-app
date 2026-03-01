import 'package:cloud_firestore/cloud_firestore.dart';

class Order {
  final String id;
  final String userId;
  final String? orderNumber;
  final String status; // pending, processing, shipped, delivered, cancelled
  final int totalItems;
  final double totalGrossWeight;
  final double totalNetWeight;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem>? items;

  Order({
    required this.id,
    required this.userId,
    this.orderNumber,
    required this.status,
    required this.totalItems,
    required this.totalGrossWeight,
    required this.totalNetWeight,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return Order(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      orderNumber: json['orderNumber'] as String?,
      status: json['status'] as String? ?? 'pending',
      totalItems: json['totalItems'] as int? ?? 0,
      totalGrossWeight: (json['totalGrossWeight'] as num? ?? 0.0).toDouble(),
      totalNetWeight: (json['totalNetWeight'] as num? ?? 0.0).toDouble(),
      adminNotes: json['adminNotes'] as String?,
      createdAt: parseDate(json['createdAt']),
      updatedAt: parseDate(json['updatedAt']),
      items: json['items'] != null
          ? (json['items'] as List)
                .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'orderNumber': orderNumber,
      'status': status,
      'totalItems': totalItems,
      'totalGrossWeight': totalGrossWeight,
      'totalNetWeight': totalNetWeight,
      'adminNotes': adminNotes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'processing':
        return 'Processing';
      case 'shipped':
        return 'Shipped';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String get statusEmoji {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'processing':
        return '⚙️';
      case 'shipped':
        return '🚚';
      case 'delivered':
        return '✓';
      case 'cancelled':
        return '❌';
      default:
        return '';
    }
  }

  /// Create empty order
  factory Order.empty() {
    return Order(
      id: '',
      userId: '',
      status: '',
      totalItems: 0,
      totalGrossWeight: 0.0,
      totalNetWeight: 0.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}

class OrderItem {
  final String? productId;
  final int quantity;
  final String tagNumber;
  final double grossWeight;
  final double netWeight;
  final String category;
  final List<String> imageUrls;

  OrderItem({
    this.productId,
    required this.quantity,
    required this.tagNumber,
    required this.grossWeight,
    required this.netWeight,
    required this.category,
    required this.imageUrls,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      tagNumber: json['tagNumber'] as String? ?? 'N/A',
      grossWeight: (json['grossWeight'] as num? ?? 0.0).toDouble(),
      netWeight: (json['netWeight'] as num? ?? 0.0).toDouble(),
      category: json['category'] as String? ?? '',
      imageUrls: json['imageUrls'] != null
          ? List<String>.from(json['imageUrls'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
      'tagNumber': tagNumber,
      'grossWeight': grossWeight,
      'netWeight': netWeight,
      'category': category,
      'imageUrls': imageUrls,
    };
  }
}
