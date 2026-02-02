import 'package:vishal_gold/models/product.dart';

class CartItem {
  final String id;
  final String userId;
  final String productId;
  final int quantity;
  final DateTime addedAt;
  final Product? product; // Joined product data

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.quantity,
    required this.addedAt,
    this.product,
  });

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      productId: json['product_id'] as String,
      quantity: json['quantity'] as int,
      addedAt: DateTime.parse(json['added_at'] as String),
      product: json['products'] != null
          ? Product.fromJson(json['products'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'product_id': productId,
      'quantity': quantity,
      'added_at': addedAt.toIso8601String(),
    };
  }

  CartItem copyWith({
    String? id,
    String? userId,
    String? productId,
    int? quantity,
    DateTime? addedAt,
    Product? product,
  }) {
    return CartItem(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      productId: productId ?? this.productId,
      quantity: quantity ?? this.quantity,
      addedAt: addedAt ?? this.addedAt,
      product: product ?? this.product,
    );
  }
}
