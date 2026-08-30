import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_jewelers/models/product.dart';

class WishlistItem {
  final String id;
  final String userId;
  final String productId;
  final DateTime addedAt;
  final Product? product; // Joined product data

  WishlistItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.addedAt,
    this.product,
  });

  factory WishlistItem.fromJson(Map<String, dynamic> json) {
    DateTime parseDate(dynamic date) {
      if (date == null) return DateTime.now();
      if (date is Timestamp) return date.toDate();
      if (date is String) return DateTime.tryParse(date) ?? DateTime.now();
      return DateTime.now();
    }

    return WishlistItem(
      id: json['id'] as String? ?? json['productId'] as String? ?? '',
      userId: json['user_id'] as String? ?? json['userId'] as String? ?? '',
      productId:
          json['product_id'] as String? ?? json['productId'] as String? ?? '',
      addedAt: parseDate(json['added_at'] ?? json['addedAt']),
      product: json['product'] != null
          ? Product.fromJson(json['product'] as Map<String, dynamic>)
          : (json['products'] != null
                ? Product.fromJson(json['products'] as Map<String, dynamic>)
                : null),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'userId': userId,
      'product_id': productId,
      'productId': productId,
      'added_at': addedAt.toIso8601String(),
      'addedAt': addedAt.toIso8601String(),
      if (product != null) 'product': product!.toJson(),
    };
  }

  WishlistItem copyWith({
    String? id,
    String? userId,
    String? productId,
    DateTime? addedAt,
    Product? product,
  }) {
    return WishlistItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      addedAt: addedAt ?? this.addedAt,
      product: product ?? this.product,
    );
  }
}
