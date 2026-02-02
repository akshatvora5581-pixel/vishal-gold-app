class Order {
  final String id;
  final String userId;
  final String orderNumber;
  final String status; // pending, processing, shipped, delivered, cancelled
  final int totalItems;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem>? items; // Joined order items

  Order({
    required this.id,
    required this.userId,
    required this.orderNumber,
    required this.status,
    required this.totalItems,
    this.adminNotes,
    required this.createdAt,
    required this.updatedAt,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      orderNumber: json['order_number'] as String,
      status: json['status'] as String,
      totalItems: json['total_items'] as int,
      adminNotes: json['admin_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['order_items'] != null
          ? (json['order_items'] as List)
                .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
                .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'order_number': orderNumber,
      'status': status,
      'total_items': totalItems,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
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
}

class OrderItem {
  final String id;
  final String orderId;
  final String? productId;
  final int quantity;
  final String tagNumber;
  final double grossWeight;
  final double netWeight;
  final DateTime createdAt;

  OrderItem({
    required this.id,
    required this.orderId,
    this.productId,
    required this.quantity,
    required this.tagNumber,
    required this.grossWeight,
    required this.netWeight,
    required this.createdAt,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String?,
      quantity: json['quantity'] as int,
      tagNumber: json['tag_number'] as String,
      grossWeight: (json['gross_weight'] as num).toDouble(),
      netWeight: (json['net_weight'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_id': orderId,
      'product_id': productId,
      'quantity': quantity,
      'tag_number': tagNumber,
      'gross_weight': grossWeight,
      'net_weight': netWeight,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
