import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/widgets/admin/add_edit_product_sheet.dart';
import 'package:vishal_gold/utils/debouncer.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _searchController = TextEditingController();
  final _searchDebouncer = Debouncer(milliseconds: 500);

  // Use ValueNotifier for basic filters to avoid full rebuilds on every keystroke/tap
  final ValueNotifier<String> _searchQueryNotifier = ValueNotifier('');
  final ValueNotifier<String?> _selectedStatusNotifier = ValueNotifier(null);
  final ValueNotifier<String?> _selectedCategoryNotifier = ValueNotifier(null);

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedProductIds = {};

  // Pagination state
  final List<Product> _products = [];
  DocumentSnapshot? _lastDocument;
  bool _isLoading = false;
  bool _hasMore = true;
  String? _errorMessage;
  final int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchProducts();

    // Listen to filter changes to reset and refetch
    _searchQueryNotifier.addListener(_onFilterChanged);
    _selectedStatusNotifier.addListener(_onFilterChanged);
    _selectedCategoryNotifier.addListener(_onFilterChanged);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        _hasMore) {
      _fetchProducts();
    }
  }

  void _onFilterChanged() {
    _resetPagination();
    _fetchProducts();
  }

  void _resetPagination() {
    setState(() {
      _products.clear();
      _lastDocument = null;
      _hasMore = true;
      _errorMessage = null; // Clear error on reset
      _selectedProductIds.clear();
      _isSelectionMode = false;
    });
  }

  Future<void> _fetchProducts() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _firebaseService.getProductsPaginated(
        category: _selectedCategoryNotifier.value,
        limit: _pageSize,
        startAfter: _lastDocument,
        status: _selectedStatusNotifier.value ?? 'published',
      );

      final List<Product> newProducts =
          (result['products'] as List).cast<Product>();
      _lastDocument = result['lastDocument'];

      if (mounted) {
        setState(() {
          _products.addAll(newProducts);
          _hasMore = newProducts.length == _pageSize;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
        // Also show a snackbar for immediate feedback if background load fails
        if (_products.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    _searchDebouncer.dispose();
    _searchQueryNotifier.dispose();
    _selectedStatusNotifier.dispose();
    _selectedCategoryNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close, color: AppColors.textPrimary),
                onPressed: () => setState(() {
                  _isSelectionMode = false;
                  _selectedProductIds.clear();
                }),
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedProductIds.length} Selected'
              : 'Product Management',
          style: GoogleFonts.outfit(
            color: _isSelectionMode ? AppColors.textPrimary : AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: Icon(
                _selectedProductIds.length == _products.length
                    ? Icons.deselect_outlined
                    : Icons.select_all_outlined,
                color: AppColors.gold,
              ),
              onPressed: _toggleAllSelection,
            )
          else
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
              onPressed: () => _openAddEditProduct(context),
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildFilters(),
              Expanded(child: _buildProductList()),
            ],
          ),
          if (_isSelectionMode) _buildBulkActionBar(),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: AppColors.surface,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (v) {
              _searchDebouncer.run(() {
                _searchQueryNotifier.value = v;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search by Tag # or Name',
              hintStyle: const TextStyle(color: AppColors.textSecondary),
              prefixIcon: const Icon(Icons.search, color: AppColors.gold),
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: _selectedStatusNotifier,
                  builder: (context, status, _) {
                    return Row(
                      children: [
                        _buildFilterChip(
                          'All Status',
                          null,
                          status,
                          (val) => _selectedStatusNotifier.value = val,
                        ),
                        _buildFilterChip(
                          'Published',
                          'published',
                          status,
                          (val) => _selectedStatusNotifier.value = val,
                        ),
                        _buildFilterChip(
                          'Draft',
                          'draft',
                          status,
                          (val) => _selectedStatusNotifier.value = val,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(width: 12),
                Container(
                  height: 24,
                  width: 1,
                  color: AppColors.white.withOpacity(0.1),
                ),
                const SizedBox(width: 12),
                ValueListenableBuilder<String?>(
                  valueListenable: _selectedCategoryNotifier,
                  builder: (context, category, _) {
                    return Row(
                      children: [
                        _buildFilterChip(
                          'All Categories',
                          null,
                          category,
                          (val) => _selectedCategoryNotifier.value = val,
                        ),
                        _buildFilterChip(
                          '84 Melting',
                          '84_melting',
                          category,
                          (val) => _selectedCategoryNotifier.value = val,
                        ),
                        _buildFilterChip(
                          '92 Melting',
                          '92_melting',
                          category,
                          (val) => _selectedCategoryNotifier.value = val,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAllSelection() {
    setState(() {
      if (_selectedProductIds.length == _products.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds.addAll(_products.map((p) => p.id));
      }
    });
  }

  Widget _buildBulkActionBar() {
    final auth = context.read<AuthProvider>();
    final performerId = auth.currentUser?.uid ?? 'unknown';

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        color: AppColors.gold,
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                '${_selectedProductIds.length} items',
                style: const TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => _bulkUpdateStatus('published', performerId),
                icon: const Icon(
                  Icons.publish,
                  color: AppColors.black,
                  size: 20,
                ),
                label: const Text(
                  'Publish',
                  style: TextStyle(color: AppColors.black),
                ),
              ),
              TextButton.icon(
                onPressed: () => _bulkUpdateStatus('draft', performerId),
                icon: const Icon(
                  Icons.archive,
                  color: AppColors.black,
                  size: 20,
                ),
                label: const Text(
                  'Draft',
                  style: TextStyle(color: AppColors.black),
                ),
              ),
              IconButton(
                onPressed: _confirmBulkDelete,
                icon: const Icon(Icons.delete_outline, color: Colors.black87),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _bulkUpdateStatus(String status, String performerId) async {
    try {
      await _firebaseService.bulkUpdateProducts(
        productIds: _selectedProductIds.toList(),
        updates: {'status': status},
        performedBy: performerId,
      );
      setState(() {
        _isSelectionMode = false;
        _selectedProductIds.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully updated products')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _confirmBulkDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Selected',
          style: TextStyle(color: AppColors.gold),
        ),
        content: Text(
          'Are you sure you want to delete ${_selectedProductIds.length} products?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (!mounted) return;
      final performerId =
          context.read<AuthProvider>().currentUser?.uid ?? 'unknown';
      try {
        for (var id in _selectedProductIds) {
          await _firebaseService.deleteProduct(id, performerId);
        }
        setState(() {
          _isSelectionMode = false;
          _selectedProductIds.clear();
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting products: ${e.toString()}')),
          );
        }
      }
    }
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    String? groupValue,
    ValueChanged<String?> onSelected,
  ) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) => onSelected(selected ? value : null),
        backgroundColor: AppColors.background,
        selectedColor: AppColors.gold.withOpacity(0.2),
        labelStyle: TextStyle(
          color: isSelected ? AppColors.gold : AppColors.textPrimary,
          fontSize: 12,
        ),
        checkmarkColor: AppColors.gold,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? AppColors.gold : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    // 1. Initial Loading State
    if (_isLoading && _products.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.gold),
            SizedBox(height: 16),
            Text('Loading products...', style: TextStyle(color: AppColors.gold)),
          ],
        ),
      );
    }

    // 2. Error State (When no products yet)
    if (_errorMessage != null && _products.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _onFilterChanged,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold),
                child: const Text(
                  'RETRY',
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // 3. Empty State
    if (_products.isEmpty) {
      return RefreshIndicator(
        onRefresh: () async => _onFilterChanged(),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
            const Center(
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'No products found matching filters',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            ),
          ],
        ),
      );
    }

    // 4. Content List
    return RefreshIndicator(
      onRefresh: () async => _onFilterChanged(),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _products.length + (_hasMore ? 1 : 0),
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          if (index == _products.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.gold),
              ),
            );
          }
          return _buildProductTile(_products[index]);
        },
      ),
    );
  }

  Widget _buildProductTile(Product product) {
    // Only setState when selection changes
    final isSelected = _selectedProductIds.contains(product.id);

    return Card(
      color: isSelected ? AppColors.gold.withOpacity(0.1) : AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? const BorderSide(color: AppColors.gold, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            setState(() {
              if (isSelected) {
                _selectedProductIds.remove(product.id);
                if (_selectedProductIds.isEmpty) _isSelectionMode = false;
              } else {
                _selectedProductIds.add(product.id);
              }
            });
          } else {
            _openAddEditProduct(context, product: product);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            setState(() {
              _isSelectionMode = true;
              _selectedProductIds.add(product.id);
            });
          }
        },
        child: RepaintBoundary(
          child: Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSelectionMode)
                      Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: AppColors.gold,
                        ),
                      ),
                    product.imageUrls.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: product.imageUrls.first,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                              memCacheHeight:
                                  180, // Optimization: cache smaller version
                              memCacheWidth: 180,
                              placeholder: (context, url) =>
                                  Container(color: AppColors.background),
                              errorWidget: (context, url, error) =>
                                  const Icon(Icons.error),
                            ),
                          )
                        : Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.image_not_supported,
                              color: AppColors.textSecondary,
                            ),
                          ),
                  ],
                ),
                title: Text(
                  product.tagNumber,
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.name != null && product.name!.isNotEmpty)
                      Text(
                        product.name!,
                        style: const TextStyle(color: AppColors.textPrimary),
                      ),
                    Text(
                      '${product.categoryDisplay} > ${product.subcategory}',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      'GW: ${product.grossWeight}g | Purity: ${product.purity}K',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: product.status == 'published'
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    product.status.toUpperCase(),
                    style: TextStyle(
                      color: product.status == 'published'
                          ? Colors.green
                          : Colors.orange,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          _openAddEditProduct(context, product: product),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: Colors.blue),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () => _deleteProduct(product),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openAddEditProduct(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddEditProductSheet(product: product),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    final auth = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Product',
          style: TextStyle(color: AppColors.gold),
        ),
        content: Text('Are you sure you want to delete ${product.tagNumber}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final performerId = auth.currentUser?.uid ?? 'unknown';
        await FirebaseFirestore.instance
            .collection('products')
            .doc(product.id)
            .delete();
        await _firebaseService.logAdminAction(
          adminId: performerId,
          action: 'DELETE_PRODUCT',
          targetId: product.id,
          targetType: 'product',
          details: 'Deleted product: ${product.tagNumber}',
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Product deleted successfully!'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
        }
      }
    }
  }
}
