import 'package:flutter/foundation.dart';
import 'package:vishal_gold/models/order.dart';
import 'package:vishal_gold/models/cart_item.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class OrderProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Order> _orders = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Order> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasOrders => _orders.isNotEmpty;

  /// Load orders for a user
  Future<void> loadOrders(String? userId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      if (userId != null) {
        // Load user-specific orders (wholesalers)
        _orders = await _firebaseService.getOrders(userId);
      } else {
        // For retailers without auth, orders won't be tracked
        // Or you could implement anonymous order tracking
        _orders = [];
      }
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load orders: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Create order from cart
  Future<String?> createOrder({
    String? userId,
    required List<CartItem> cartItems,
    Map<String, dynamic>? additionalData,
  }) async {
    if (cartItems.isEmpty) {
      _error = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Convert cart items to order items
      final orderItems = cartItems.map((cartItem) {
        final product = cartItem.product;
        if (product == null) {
          throw 'Product details missing for cart item: ${cartItem.productId}';
        }

        return {
          'productId': cartItem.productId,
          'tagNumber': product.tagNumber,
          'grossWeight': product.grossWeight,
          'netWeight': product.netWeight,
          'purity': product.purity,
          'category': product.category,
          'quantity': cartItem.quantity,
          'imageUrls': product.imageUrls,
        };
      }).toList();

      // Create order data
      final orderData = {
        'userId': userId,
        'items': orderItems,
        'totalItems': cartItems.fold(0, (sum, item) => sum + item.quantity),
        'totalGrossWeight': cartItems.fold(
          0.0,
          (sum, item) =>
              sum + ((item.product?.grossWeight ?? 0.0) * item.quantity),
        ),
        'totalNetWeight': cartItems.fold(
          0.0,
          (sum, item) =>
              sum + ((item.product?.netWeight ?? 0.0) * item.quantity),
        ),
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
        ...?additionalData,
      };

      // Create order in Firestore
      final orderId = await _firebaseService.createOrder(orderData);

      // Reload orders
      if (userId != null) {
        await loadOrders(userId);
      }

      return orderId;
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to create order: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Get single order by ID
  Future<Order?> getOrderById(String orderId) async {
    try {
      // First check cache
      final cachedOrder = _orders.firstWhere(
        (o) => o.id == orderId,
        orElse: () => Order.empty(),
      );

      if (cachedOrder.id.isNotEmpty) {
        return cachedOrder;
      }

      // If not in cache, fetch from Firestore
      final orderData = await _firebaseService.getOrderById(orderId);
      if (orderData != null) {
        return Order.fromJson(orderData);
      }
      return null;
    } catch (e) {
      debugPrint('Failed to get order: $e');
      return null;
    }
  }

  /// Cancel order
  Future<void> cancelOrder(String orderId) async {
    try {
      await _firebaseService.updateOrderStatus(orderId, 'cancelled');

      // Update local cache
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index >= 0) {
        _orders[index] = Order.fromJson({
          ..._orders[index].toJson(),
          'status': 'cancelled',
          'updatedAt': DateTime.now().toIso8601String(),
        });
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to cancel order: $e');
      rethrow;
    }
  }

  /// Refresh orders
  Future<void> refresh(String? userId) async {
    await loadOrders(userId);
  }

  /// Get orders by status
  List<Order> getOrdersByStatus(String status) {
    return _orders.where((order) => order.status == status).toList();
  }

  /// Get recent orders
  List<Order> getRecentOrders({int limit = 10}) {
    final sorted = List<Order>.from(_orders)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted.take(limit).toList();
  }
}
