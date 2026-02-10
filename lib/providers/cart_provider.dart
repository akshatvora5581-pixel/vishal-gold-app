import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/cart_item.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/services/local_storage_service.dart';

class CartProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _userId;
  bool _isWholesaler = false;

  // Getters
  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);
  bool get isEmpty => _items.isEmpty;

  /// Initialize cart
  Future<void> initialize(String? userId, bool isWholesaler) async {
    _userId = userId;
    _isWholesaler = isWholesaler;
    await loadCart();
  }

  /// Load cart from appropriate storage
  Future<void> loadCart() async {
    _isLoading = true;
    Future.microtask(() => notifyListeners());

    try {
      if (_isWholesaler && _userId != null) {
        // Load from Firestore for wholesalers
        await _loadFromFirestore();
      } else {
        // Load from local storage for retailers
        await _loadFromLocalStorage();
      }
    } catch (e) {
      debugPrint('Failed to load cart: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load cart from Firestore (wholesalers)
  Future<void> _loadFromFirestore() async {
    if (_userId == null) return;

    try {
      final cartData = await _firebaseService.getCartItems(_userId!);
      _items = cartData.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Failed to load cart from Firestore: $e');
      _items = [];
    }
  }

  /// Load cart from local storage (retailers)
  Future<void> _loadFromLocalStorage() async {
    try {
      final cartJson = await LocalStorageService.getCart();
      if (cartJson != null && cartJson.isNotEmpty) {
        final List<dynamic> cartList = jsonDecode(cartJson);
        _items = cartList.map((item) => CartItem.fromJson(item)).toList();
      } else {
        _items = [];
      }
    } catch (e) {
      debugPrint('Failed to load cart from local storage: $e');
      _items = [];
    }
  }

  /// Save cart to appropriate storage
  Future<void> _saveCart() async {
    try {
      if (_isWholesaler && _userId != null) {
        // Save to Firestore for wholesalers
        await _saveToFirestore();
      } else {
        // Save to local storage for retailers
        await _saveToLocalStorage();
      }
    } catch (e) {
      debugPrint('Failed to save cart: $e');
    }
  }

  /// Save cart to Firestore (wholesalers)
  Future<void> _saveToFirestore() async {
    if (_userId == null) return;

    try {
      final cartData = _items.map((item) => item.toJson()).toList();
      await _firebaseService.updateCart(_userId!, cartData);
    } catch (e) {
      debugPrint('Failed to save cart to Firestore: $e');
    }
  }

  /// Save cart to local storage (retailers)
  Future<void> _saveToLocalStorage() async {
    try {
      final cartJson = jsonEncode(_items.map((item) => item.toJson()).toList());
      await LocalStorageService.saveCart(cartJson);
    } catch (e) {
      debugPrint('Failed to save cart to local storage: $e');
    }
  }

  /// Add product to cart
  Future<void> addToCart(Product product) async {
    // Check if product already exists
    final existingIndex = _items.indexWhere(
      (item) => item.productId == product.id,
    );

    if (existingIndex >= 0) {
      // Increase quantity
      _items[existingIndex] = _items[existingIndex].copyWith(
        quantity: _items[existingIndex].quantity + 1,
      );
    } else {
      // Add new item
      _items.add(
        CartItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _userId ?? 'guest',
          productId: product.id,
          product: product,
          quantity: 1,
          addedAt: DateTime.now(),
        ),
      );
    }

    notifyListeners();
    await _saveCart();
  }

  /// Remove product from cart
  Future<void> removeFromCart(String productId) async {
    _items.removeWhere((item) => item.productId == productId);
    notifyListeners();
    await _saveCart();
  }

  /// Update quantity
  Future<void> updateQuantity(String productId, int quantity) async {
    if (quantity <= 0) {
      await removeFromCart(productId);
      return;
    }

    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(quantity: quantity);
      notifyListeners();
      await _saveCart();
    }
  }

  /// Clear cart
  Future<void> clearCart() async {
    _items = [];
    notifyListeners();
    await _saveCart();
  }

  /// Get total items weight
  double getTotalGrossWeight() {
    return _items.fold(0.0, (sum, item) {
      if (item.product == null) return sum;
      return sum + (item.product!.grossWeight * item.quantity);
    });
  }

  double getTotalNetWeight() {
    return _items.fold(0.0, (sum, item) {
      if (item.product == null) return sum;
      return sum + (item.product!.netWeight * item.quantity);
    });
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Get cart item quantity
  int getQuantity(String productId) {
    try {
      final item = _items.firstWhere((item) => item.productId == productId);
      return item.quantity;
    } catch (_) {
      return 0;
    }
  }
}
