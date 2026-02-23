import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/services/firebase_service.dart';

/// Sort options exposed to the UI.
enum ProductSortOrder { newestFirst, tagAsc, tagDesc, weightAsc, weightDesc }

class ProductProvider with ChangeNotifier {
  final FirebaseService _firebaseService = FirebaseService();

  List<Product> _products = [];
  List<Product> _filteredProducts = [];
  bool _isLoading = false;
  String? _error;
  String _currentCategory = 'all';
  String? _currentSubcategory;
  String _searchQuery = '';
  ProductSortOrder _currentSort = ProductSortOrder.newestFirst;
  bool _viewDrafts = false;

  // Getters
  List<Product> get products =>
      _filteredProducts.isNotEmpty ? _filteredProducts : _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;
  String? get currentSubcategory => _currentSubcategory;
  bool get hasProducts => products.isNotEmpty;
  ProductSortOrder get currentSort => _currentSort;
  bool get viewDrafts => _viewDrafts;

  /// Load all products
  Future<void> loadProducts({List<QueryDocumentSnapshot>? stagedDocs}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final liveProducts = await _firebaseService.getAllProducts(
        status: _viewDrafts ? 'draft' : 'published',
      );

      if (stagedDocs != null && stagedDocs.isNotEmpty) {
        _products = _mergeProducts(liveProducts, stagedDocs);
      } else {
        _products = liveProducts;
      }

      _applyFilters();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<Product> _mergeProducts(
    List<Product> liveItems,
    List<QueryDocumentSnapshot> stagedDocs,
  ) {
    final Map<String, Product> mergedMap = {
      for (var item in liveItems) item.id: item,
    };

    for (var doc in stagedDocs) {
      final change = doc.data() as Map<String, dynamic>;
      final String collectionName = change['collection_name'];
      if (collectionName != 'products') continue;

      final String changeType = change['change_type'];
      final String docId = change['doc_id'];
      final Map<String, dynamic>? data = change['data'];

      if (changeType == 'delete') {
        mergedMap.remove(docId);
      } else if (data != null) {
        // Ensure id is present in data for fromJson
        final Map<String, dynamic> completeData = Map.from(data);
        completeData['id'] = docId;
        mergedMap[docId] = Product.fromJson(completeData);
      }
    }
    return mergedMap.values.toList();
  }

  /// Load products by category
  Future<void> loadProductsByCategory(
    String category, {
    String? subcategory,
    List<QueryDocumentSnapshot>? stagedDocs,
  }) async {
    _currentCategory = category;
    _currentSubcategory = subcategory;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final status = _viewDrafts ? 'draft' : 'published';
      final List<Product> liveProducts;
      if (category == 'all') {
        liveProducts = await _firebaseService.getAllProducts(status: status);
      } else {
        liveProducts = await _firebaseService.getProductsByCategory(
          category,
          status: status,
        );
      }

      if (stagedDocs != null && stagedDocs.isNotEmpty) {
        _products = _mergeProducts(liveProducts, stagedDocs);
      } else {
        _products = liveProducts;
      }

      _applyFilters();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load products by category: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Search products
  void searchProducts(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Apply filters (category + search) then sort
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // Check search query
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            product.tagNumber.toLowerCase().contains(_searchQuery) ||
            (product.name?.toLowerCase().contains(_searchQuery) ?? false) ||
            (product.description?.toLowerCase().contains(_searchQuery) ??
                false);

        if (!matchesSearch) return false;
      }

      // Check subcategory
      if (_currentSubcategory != null && _currentSubcategory!.isNotEmpty) {
        if (product.subcategory.toUpperCase() !=
            _currentSubcategory!.toUpperCase()) {
          return false;
        }
      }

      return true;
    }).toList();

    _applySortToList(_filteredProducts);
  }

  /// Sort a product list in-place according to [_currentSort]
  void _applySortToList(List<Product> list) {
    switch (_currentSort) {
      case ProductSortOrder.newestFirst:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case ProductSortOrder.tagAsc:
        list.sort(
          (a, b) =>
              a.tagNumber.toLowerCase().compareTo(b.tagNumber.toLowerCase()),
        );
        break;
      case ProductSortOrder.tagDesc:
        list.sort(
          (a, b) =>
              b.tagNumber.toLowerCase().compareTo(a.tagNumber.toLowerCase()),
        );
        break;
      case ProductSortOrder.weightAsc:
        list.sort((a, b) => a.grossWeight.compareTo(b.grossWeight));
        break;
      case ProductSortOrder.weightDesc:
        list.sort((a, b) => b.grossWeight.compareTo(a.grossWeight));
        break;
    }
  }

  /// Change sort order and re-sort the current list immediately
  void sortProducts(ProductSortOrder order) {
    if (_currentSort == order) return;
    _currentSort = order;
    _applyFilters();
    notifyListeners();
  }

  /// Toggle Draft View
  void setViewDrafts(bool value) {
    if (_viewDrafts == value) return;
    _viewDrafts = value;
    loadProductsByCategory(_currentCategory, subcategory: _currentSubcategory);
  }

  /// Get single product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      // First check cache
      final cachedProduct = _products.firstWhere(
        (p) => p.id == productId,
        orElse: () => Product(
          id: '',
          tagNumber: '',
          category: '',
          subcategory: '',
          imageUrls: [],
          grossWeight: 0,
          netWeight: 0,
          purity: 84,
          status: 'published',
          version: 1,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      if (cachedProduct.id.isNotEmpty) {
        return cachedProduct;
      }

      // If not in cache, fetch from Firestore
      final product = await _firebaseService.getProduct(productId);
      return product;
    } catch (e) {
      debugPrint('Failed to get product: $e');
      return null;
    }
  }

  /// Upload new product (wholesalers only)
  Future<String?> uploadProduct({
    required String tagNumber,
    required String category,
    required String subcategory,
    required double grossWeight,
    required double netWeight,
    required int purity,
    required List<String> imageUrls,
    required String uploadedBy,
    String? name,
    String? description,
  }) async {
    try {
      final productId = await _firebaseService.uploadProduct(
        tagNumber: tagNumber,
        category: category,
        subcategory: subcategory,
        grossWeight: grossWeight,
        netWeight: netWeight,
        purity: purity,
        imageUrls: imageUrls,
        uploadedBy: uploadedBy,
        name: name,
        description: description,
      );

      // Reload products
      await loadProducts();

      return productId;
    } catch (e) {
      debugPrint('Failed to upload product: $e');
      rethrow;
    }
  }

  /// Delete product (wholesalers only)
  Future<void> deleteProduct(String productId, String performedBy) async {
    try {
      await _firebaseService.deleteProduct(productId, performedBy);

      // Remove from local cache
      _products.removeWhere((p) => p.id == productId);
      _applyFilters();
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to delete product: $e');
      rethrow;
    }
  }

  /// Update product (wholesalers only)
  Future<void> updateProduct({
    required String productId,
    required Map<String, dynamic> updates,
    required String performedBy,
  }) async {
    try {
      await _firebaseService.updateProductWithLog(
        productId: productId,
        updates: updates,
        performedBy: performedBy,
      );

      // Reload products
      await loadProducts();
    } catch (e) {
      debugPrint('Failed to update product: $e');
      rethrow;
    }
  }

  /// Clear filters
  void clearFilters() {
    _searchQuery = '';
    _currentCategory = 'all';
    _applyFilters();
    notifyListeners();
  }

  /// Refresh products
  Future<void> refresh() async {
    await loadProductsByCategory(_currentCategory);
  }
}
