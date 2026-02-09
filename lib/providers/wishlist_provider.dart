import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/wishlist_item.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/services/local_storage_service.dart';

class WishlistProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<WishlistItem> _items = [];
  bool _isLoading = false;
  String? _userId;
  bool _isWholesaler = false;

  // Getters
  List<WishlistItem> get items => _items;
  bool get isLoading => _isLoading;
  int get itemCount => _items.length;
  bool get isEmpty => _items.isEmpty;

  /// Initialize wishlist
  Future<void> initialize(String? userId, bool isWholesaler) async {
    _userId = userId;
    _isWholesaler = isWholesaler;
    await loadWishlist();
  }

  /// Load wishlist from appropriate storage
  Future<void> loadWishlist() async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_isWholesaler && _userId != null) {
        // Load from Firestore for wholesalers
        await _loadFromFirestore();
      } else {
        // Load from local storage for retailers
        await _loadFromLocalStorage();
      }
    } catch (e) {
      debugPrint('Failed to load wishlist: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Load from Firestore
  Future<void> _loadFromFirestore() async {
    if (_userId == null) return;
    try {
      final data = await _firebaseService.getWishlistItems(_userId!);
      _items = data.map((item) => WishlistItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('Firestore wishlist load error: $e');
      _items = [];
    }
  }

  /// Load from local storage
  Future<void> _loadFromLocalStorage() async {
    try {
      final json = await LocalStorageService.getWishlist();
      if (json != null && json.isNotEmpty) {
        final List<dynamic> list = jsonDecode(json);
        _items = list.map((item) => WishlistItem.fromJson(item)).toList();
      } else {
        _items = [];
      }
    } catch (e) {
      debugPrint('Local wishlist load error: $e');
      _items = [];
    }
  }

  /// Save wishlist
  Future<void> _saveWishlist() async {
    try {
      if (_isWholesaler && _userId != null) {
        final data = _items.map((item) => item.toJson()).toList();
        await _firebaseService.updateWishlist(_userId!, data);
      } else {
        final json = jsonEncode(_items.map((item) => item.toJson()).toList());
        await LocalStorageService.saveWishlist(json);
      }
    } catch (e) {
      debugPrint('Failed to save wishlist: $e');
    }
  }

  /// Toggle wishlist status
  Future<void> toggleWishlist(Product product) async {
    final index = _items.indexWhere((item) => item.productId == product.id);

    if (index >= 0) {
      _items.removeAt(index);
    } else {
      _items.add(
        WishlistItem(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: _userId ?? 'guest',
          productId: product.id,
          product: product,
          addedAt: DateTime.now(),
        ),
      );
    }

    notifyListeners();
    await _saveWishlist();
  }

  /// Check if product is in wishlist
  bool isInWishlist(String productId) {
    return _items.any((item) => item.productId == productId);
  }

  /// Clear wishlist
  Future<void> clearWishlist() async {
    _items = [];
    notifyListeners();
    await _saveWishlist();
  }
}
