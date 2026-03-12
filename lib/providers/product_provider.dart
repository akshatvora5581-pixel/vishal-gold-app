import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/services/firebase_service.dart';

/// Sort options exposed to the UI.
enum ProductSortOrder { newestFirst, tagAsc, tagDesc, weightAsc, weightDesc }

/// Inventory status filter options.
enum InventoryStatusFilter { all, inStock, soldOut, onOrder }

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

  // Pagination states
  DocumentSnapshot? _lastVisibleDocument;
  bool _hasMoreData = true;
  bool _isFetchingMore = false;
  final int _pageSize = 20;

  // ── Advanced Filters ───────────────────────────────────────────────────────
  double? _minWeight;
  double? _maxWeight;
  InventoryStatusFilter _inventoryStatusFilter = InventoryStatusFilter.all;

  // Getters
  List<Product> get products => _filteredProducts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get currentCategory => _currentCategory;
  String? get currentSubcategory => _currentSubcategory;
  bool get hasProducts => products.isNotEmpty;
  ProductSortOrder get currentSort => _currentSort;
  bool get viewDrafts => _viewDrafts;
  double? get minWeightFilter => _minWeight;
  double? get maxWeightFilter => _maxWeight;
  InventoryStatusFilter get inventoryStatusFilter => _inventoryStatusFilter;

  // Pagination getters
  bool get hasMoreData => _hasMoreData;
  bool get isFetchingMore => _isFetchingMore;

  /// Returns true if any non-default filter is active.
  bool get hasActiveFilters =>
      _currentSort != ProductSortOrder.newestFirst ||
      _minWeight != null ||
      _maxWeight != null ||
      _inventoryStatusFilter != InventoryStatusFilter.all;

  /// Generate the order by field based on current sorting
  String? _getOrderByField() {
    switch (_currentSort) {
      case ProductSortOrder.newestFirst:
        return 'createdAt';
      case ProductSortOrder.tagAsc:
        return 'tag_number';
      case ProductSortOrder.tagDesc:
        return 'tag_number';
      case ProductSortOrder.weightAsc:
        return 'gross_weight';
      case ProductSortOrder.weightDesc:
        return 'gross_weight';
    }
  }

  bool _getSortDescending() {
    switch (_currentSort) {
      case ProductSortOrder.newestFirst:
        return true;
      case ProductSortOrder.tagAsc:
        return false;
      case ProductSortOrder.tagDesc:
        return true;
      case ProductSortOrder.weightAsc:
        return false;
      case ProductSortOrder.weightDesc:
        return true;
    }
  }

  /// Load all products
  Future<void> loadProducts({List<QueryDocumentSnapshot>? stagedDocs}) async {
    _currentCategory = 'all';
    _currentSubcategory = null;
    await fetchInitialProducts();
  }

  /// Load products by category
  Future<void> loadProductsByCategory(
    String category, {
    String? subcategory,
    List<QueryDocumentSnapshot>? stagedDocs,
  }) async {
    _currentCategory = category;
    _currentSubcategory = subcategory;
    await fetchInitialProducts();
  }

  /// Fetch initial set of paginated products
  Future<void> fetchInitialProducts() async {
    _isLoading = true;
    _error = null;
    _lastVisibleDocument = null;
    _hasMoreData = true;
    _products = [];
    _filteredProducts = [];
    notifyListeners();

    try {
      final status = _viewDrafts ? 'draft' : 'published';
      final result = await _firebaseService.getProductsPaginated(
        category: _currentCategory,
        subcategory: _currentSubcategory,
        limit: _pageSize,
        startAfter: null,
        status: status,
        orderByField: _getOrderByField(),
        descending: _getSortDescending(),
      );

      _products = result['products'] as List<Product>;
      _lastVisibleDocument = result['lastDocument'] as DocumentSnapshot?;
      _hasMoreData = _products.length >= _pageSize;

      _applyFilters();
    } catch (e) {
      _error = e.toString();
      debugPrint('Failed to load initial products: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Fetch next page of products
  Future<void> fetchMoreProducts() async {
    if (_isFetchingMore || !_hasMoreData || _isLoading) return;

    _isFetchingMore = true;
    notifyListeners();

    try {
      final status = _viewDrafts ? 'draft' : 'published';
      final result = await _firebaseService.getProductsPaginated(
        category: _currentCategory,
        subcategory: _currentSubcategory,
        limit: _pageSize,
        startAfter: _lastVisibleDocument,
        status: status,
        orderByField: _getOrderByField(),
        descending: _getSortDescending(),
      );

      final newProducts = result['products'] as List<Product>;
      if (newProducts.isEmpty) {
        _hasMoreData = false;
      } else {
        _products.addAll(newProducts);
        _lastVisibleDocument = result['lastDocument'] as DocumentSnapshot?;
        _hasMoreData = newProducts.length >= _pageSize;
      }

      _applyFilters();
    } catch (e) {
      debugPrint('Failed to fetch more products: $e');
    } finally {
      _isFetchingMore = false;
      notifyListeners();
    }
  }

  /// Search products
  void searchProducts(String query) {
    _searchQuery = query.trim().toLowerCase();
    _applyFilters();
    notifyListeners();
  }

  /// Apply filters (category + search + weight + inventory) then sort
  void _applyFilters() {
    _filteredProducts = _products.where((product) {
      // — Search query —
      if (_searchQuery.isNotEmpty) {
        final matchesSearch =
            product.tagNumber.toLowerCase().contains(_searchQuery) ||
            (product.name?.toLowerCase().contains(_searchQuery) ?? false) ||
            (product.description?.toLowerCase().contains(_searchQuery) ??
                false);
        if (!matchesSearch) return false;
      }

      // — Subcategory —
      if (_currentSubcategory != null && _currentSubcategory!.isNotEmpty) {
        if (product.subcategory.toUpperCase() !=
            _currentSubcategory!.toUpperCase()) {
          return false;
        }
      }

      // — Weight range —
      if (_minWeight != null && product.grossWeight < _minWeight!) {
        return false;
      }
      if (_maxWeight != null && product.grossWeight > _maxWeight!) {
        return false;
      }

      // — Inventory status —
      if (_inventoryStatusFilter != InventoryStatusFilter.all) {
        final statusString =
            _inventoryStatusFilter == InventoryStatusFilter.inStock
            ? 'in_stock'
            : _inventoryStatusFilter == InventoryStatusFilter.soldOut
            ? 'sold_out'
            : 'on_order';
        if (product.inventoryStatus != statusString) return false;
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
    fetchInitialProducts();
  }

  /// Toggle Draft View
  void setViewDrafts(bool value) {
    if (_viewDrafts == value) return;
    _viewDrafts = value;
    fetchInitialProducts();
  }

  /// User Requested: Apply sort by string criteria
  void applySort(String criteria) {
    ProductSortOrder order;
    switch (criteria) {
      case 'TagNo (A - Z)':
        order = ProductSortOrder.tagAsc;
        break;
      case 'TagNo (Z - A)':
        order = ProductSortOrder.tagDesc;
        break;
      case 'Weight (Low - High)':
        order = ProductSortOrder.weightAsc;
        break;
      case 'Weight (High - Low)':
        order = ProductSortOrder.weightDesc;
        break;
      case 'Newest First':
      default:
        order = ProductSortOrder.newestFirst;
        break;
    }
    sortProducts(order);
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
    String status = 'published',
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
        status: status,
      );

      // Reload products
      await fetchInitialProducts();

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
      await fetchInitialProducts();
    } catch (e) {
      debugPrint('Failed to update product: $e');
      rethrow;
    }
  }

  /// Set weight range filter (pass null to remove a bound).
  void setWeightRange(double? min, double? max) {
    _minWeight = min;
    _maxWeight = max;
    _applyFilters();
    notifyListeners();
  }

  /// Set inventory status filter.
  void setInventoryStatusFilter(InventoryStatusFilter status) {
    _inventoryStatusFilter = status;
    _applyFilters();
    notifyListeners();
  }

  /// Clear all advanced filters AND reset sort to newest-first.
  void clearAllFilters() {
    _searchQuery = '';
    _minWeight = null;
    _maxWeight = null;
    _inventoryStatusFilter = InventoryStatusFilter.all;
    _currentSort = ProductSortOrder.newestFirst;
    fetchInitialProducts();
  }

  /// Clear filters (legacy – keeps category context)
  void clearFilters() {
    _searchQuery = '';
    _currentCategory = 'all';
    fetchInitialProducts();
  }

  /// Refresh products
  Future<void> refresh() async {
    await loadProductsByCategory(_currentCategory);
  }
}
