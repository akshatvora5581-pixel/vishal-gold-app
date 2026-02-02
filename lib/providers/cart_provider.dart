import 'package:flutter/material.dart';
import 'package:vishal_gold/models/cart_item.dart';
import 'package:vishal_gold/models/order.dart';
import 'package:vishal_gold/services/supabase_service.dart';

class CartProvider with ChangeNotifier {
  final SupabaseService _supabaseService = SupabaseService();

  List<CartItem> _cartItems = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<CartItem> get cartItems => _cartItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _cartItems.length;
  int get totalQuantity =>
      _cartItems.fold(0, (sum, item) => sum + item.quantity);

  Future<void> loadCart(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _cartItems = await _supabaseService.getCartItems(userId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Failed to load cart';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(String userId, String productId) async {
    try {
      await _supabaseService.addToCart(userId, productId);
      await loadCart(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to add item to cart';
      notifyListeners();
      return false;
    }
  }

  Future<bool> removeFromCart(String userId, String cartItemId) async {
    try {
      await _supabaseService.removeFromCart(cartItemId);
      await loadCart(userId);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to remove item';
      notifyListeners();
      return false;
    }
  }

  Future<Order?> placeOrder(String userId) async {
    if (_cartItems.isEmpty) {
      _errorMessage = 'Cart is empty';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final order = await _supabaseService.placeOrder(userId, _cartItems);
      _cartItems = [];
      _errorMessage = null;
      return order;
    } catch (e) {
      _errorMessage = 'Failed to place order';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearCart() {
    _cartItems = [];
    notifyListeners();
  }
}
