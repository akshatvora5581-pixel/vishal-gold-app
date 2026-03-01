import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/category.dart' as app_category;
import 'package:vishal_gold/models/subcategory.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class ProductManagementScreen extends StatefulWidget {
  const ProductManagementScreen({super.key});

  @override
  State<ProductManagementScreen> createState() =>
      _ProductManagementScreenState();
}

class _ProductManagementScreenState extends State<ProductManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  String _searchQuery = '';
  String? _selectedCategory;
  String? _selectedStatus;

  // Multi-selection state
  bool _isSelectionMode = false;
  final Set<String> _selectedProductIds = {};

  int _lastFetchedCount = 0;
  List<Product> _currentVisibleProducts = [];

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
                _selectedProductIds.length == _lastFetchedCount
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
            onChanged: (v) => setState(() => _searchQuery = v),
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
          // Scrollable filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All Status', null, _selectedStatus),
                _buildFilterChip('Published', 'published', _selectedStatus),
                _buildFilterChip('Draft', 'draft', _selectedStatus),
                const SizedBox(width: 12),
                const VerticalDivider(color: AppColors.textSecondary),
                const SizedBox(width: 12),
                _buildFilterChip('All Categories', null, _selectedCategory),
                _buildFilterChip('84 Melting', '84_melting', _selectedCategory),
                _buildFilterChip('92 Melting', '92_melting', _selectedCategory),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _toggleAllSelection() {
    setState(() {
      if (_selectedProductIds.length == _currentVisibleProducts.length) {
        _selectedProductIds.clear();
      } else {
        _selectedProductIds.addAll(_currentVisibleProducts.map((p) => p.id));
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
          SnackBar(content: Text('Successfully updated products')),
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

  Widget _buildFilterChip(String label, String? value, String? groupValue) {
    final isSelected = value == groupValue;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            if (label.contains('Status')) {
              _selectedStatus = value;
            } else {
              _selectedCategory = value;
            }
          });
        },
        backgroundColor: AppColors.background,
        selectedColor: AppColors.gold.withValues(alpha: 0.2),
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
    // Note: Simple filter for now. Real world would use composite queries or client-side filtering.
    // Firestore limited in multiple 'where' inequality/ordering.
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }

        var docs = snapshot.data?.docs ?? [];

        // Client-side filtering
        _currentVisibleProducts = docs
            .map((doc) {
              return Product.fromJson({
                'id': doc.id,
                ...doc.data() as Map<String, dynamic>,
              });
            })
            .where((p) {
              bool statusMatch =
                  _selectedStatus == null || p.status == _selectedStatus;
              bool categoryMatch =
                  _selectedCategory == null || p.category == _selectedCategory;
              bool searchMatch =
                  _searchQuery.isEmpty ||
                  p.tagNumber.toLowerCase().contains(
                    _searchQuery.toLowerCase(),
                  ) ||
                  (p.name?.toLowerCase().contains(_searchQuery.toLowerCase()) ??
                      false);
              return statusMatch && categoryMatch && searchMatch;
            })
            .toList();

        _lastFetchedCount = _currentVisibleProducts.length;

        if (_currentVisibleProducts.isEmpty) {
          return Center(
            child: Text(
              'No products found',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _currentVisibleProducts.length,
          itemBuilder: (context, index) {
            final product = _currentVisibleProducts[index];
            return _buildProductTile(product);
          },
        );
      },
    );
  }

  Widget _buildProductTile(Product product) {
    final isSelected = _selectedProductIds.contains(product.id);

    return Card(
      color: isSelected
          ? AppColors.gold.withValues(alpha: 0.1)
          : AppColors.surface,
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
        borderRadius: BorderRadius.circular(12),
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
                      ? Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: DecorationImage(
                              image: _getImageProvider(product.imageUrls.first),
                              fit: BoxFit.cover,
                            ),
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
                    'GW: ${product.grossWeight}g | Purity: ${product.purity}%',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  Text(
                    'Inventory: ${product.inventoryStatusDisplay}',
                    style: TextStyle(
                      color: product.inventoryStatus == 'in_stock'
                          ? Colors.green
                          : product.inventoryStatus == 'sold_out'
                          ? Colors.red
                          : Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: product.status == 'published'
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
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
                ],
              ),
            ),
            Divider(color: AppColors.white.withValues(alpha: 0.05), height: 1),
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
                  TextButton.icon(
                    onPressed: () => _togglePublishStatus(product),
                    icon: Icon(
                      product.status == 'published'
                          ? Icons.unarchive_outlined
                          : Icons.publish_outlined,
                      size: 18,
                    ),
                    label: Text(
                      product.status == 'published' ? 'Draft' : 'Publish',
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.gold,
                    ),
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
    );
  }

  void _openAddEditProduct(BuildContext context, {Product? product}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: _AddEditProductSheet(product: product),
      ),
    );
  }

  Future<void> _togglePublishStatus(Product product) async {
    try {
      final performerId =
          context.read<AuthProvider>().currentUser?.uid ?? 'unknown';

      // Stage the status change
      await _firebaseService.stageChange(
        adminId: performerId,
        collectionName: 'products',
        docId: product.id,
        data: {
          ...product.toJson(), // Get all current data
          'status': product.status == 'published' ? 'draft' : 'published',
        },
        changeType: 'update',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status change staged for preview!'),
            backgroundColor: AppColors.gold,
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

        await _firebaseService.stageChange(
          adminId: performerId,
          collectionName: 'products',
          docId: product.id,
          data: null, // No data for delete
          changeType: 'delete',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Delete action staged for preview!'),
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

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return NetworkImage(url);
  }
}

class _AddEditProductSheet extends StatefulWidget {
  final Product? product;

  const _AddEditProductSheet({this.product});

  @override
  State<_AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends State<_AddEditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _tagController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _grossWeightController;
  late TextEditingController _netWeightController;

  String? _selectedCategory;
  app_category.Category? _categoryObj;
  String? _selectedSubcategory;
  int _selectedPurity = 84;
  final List<File> _newImageFiles = [];
  List<String> _existingImageUrls = [];
  String _inventoryStatus = 'in_stock';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController(
      text: widget.product?.tagNumber ?? '',
    );
    _nameController = TextEditingController(text: widget.product?.name ?? '');
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _grossWeightController = TextEditingController(
      text: widget.product?.grossWeight.toString() ?? '',
    );
    _netWeightController = TextEditingController(
      text: widget.product?.netWeight.toString() ?? '',
    );
    _selectedCategory = widget.product?.category;
    _selectedSubcategory = widget.product?.subcategory;
    _selectedPurity = widget.product?.purity ?? 84;
    _existingImageUrls = widget.product?.imageUrls != null
        ? List.from(widget.product!.imageUrls)
        : [];
    _inventoryStatus = widget.product?.inventoryStatus ?? 'in_stock';
  }

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _grossWeightController.dispose();
    _netWeightController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _newImageFiles.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null || _selectedSubcategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and subcategory')),
      );
      return;
    }
    if (_newImageFiles.isEmpty && _existingImageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    final performerId =
        context.read<AuthProvider>().currentUser?.uid ?? 'unknown';

    setState(() => _isLoading = true);

    try {
      List<String> uploadedUrls = [];

      // Upload new images
      for (var file in _newImageFiles) {
        String url = await _firebaseService.uploadImage(
          imageFile: file,
          folder: 'products',
        );
        uploadedUrls.add(url);
      }

      final allUrls = [..._existingImageUrls, ...uploadedUrls];

      final productData = {
        'tag_number': _tagController.text,
        'category': _selectedCategory,
        'subcategory': _selectedSubcategory,
        'name': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'image_urls': allUrls,
        'gross_weight': double.parse(_grossWeightController.text),
        'net_weight': double.parse(_netWeightController.text),
        'purity': _selectedPurity,
        'inventory_status': _inventoryStatus,
        'is_active': true,
      };

      await _firebaseService.stageChange(
        adminId: performerId,
        collectionName: 'products',
        docId:
            widget.product?.id ??
            FirebaseFirestore.instance.collection('products').doc().id,
        data: productData,
        changeType: widget.product == null ? 'create' : 'update',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Changes staged for preview!'),
            backgroundColor: AppColors.gold,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.product == null ? 'Add Product' : 'Edit Product',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _buildImagePicker(),
              const SizedBox(height: 24),
              _buildTextField(
                _tagController,
                'Tag Number (Required)',
                Icons.tag,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _nameController,
                'Product Name (Optional)',
                Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 16),
              _buildTextField(
                _descriptionController,
                'Description (Optional)',
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              _buildCategoryDropdowns(),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      _grossWeightController,
                      'Gross Weight',
                      Icons.scale,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(
                      _netWeightController,
                      'Net Weight',
                      Icons.scale_outlined,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildPuritySelector(),
              const SizedBox(height: 16),
              _buildInventoryStatusSelector(),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: AppColors.black)
                      : Text(
                          widget.product == null
                              ? 'Create Product'
                              : 'Save Changes',
                          style: const TextStyle(
                            color: AppColors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        prefixIcon: Icon(icon, color: AppColors.gold),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.white.withValues(alpha: 0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.gold),
        ),
      ),
      validator: (value) {
        if (label.contains('Required') || label.contains('Weight')) {
          if (value == null || value.isEmpty) {
            return 'Required field';
          }
        }
        return null;
      },
    );
  }

  Widget _buildImagePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              GestureDetector(
                onTap: _pickImages,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Icon(
                    Icons.add_photo_alternate_outlined,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ...List.generate(_existingImageUrls.length, (index) {
                return _buildImageThumbnail(
                  _existingImageUrls[index],
                  isExisting: true,
                  onRemove: () =>
                      setState(() => _existingImageUrls.removeAt(index)),
                );
              }),
              ...List.generate(_newImageFiles.length, (index) {
                return _buildImageThumbnail(
                  _newImageFiles[index],
                  isExisting: false,
                  onRemove: () =>
                      setState(() => _newImageFiles.removeAt(index)),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildImageThumbnail(
    dynamic image, {
    required bool isExisting,
    required VoidCallback onRemove,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: Stack(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: DecorationImage(
                image: isExisting
                    ? _getImageProvider(image as String)
                    : FileImage(image as File) as ImageProvider,
                fit: BoxFit.cover,
              ),
            ),
          ),
          Positioned(
            right: -4,
            top: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 14, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInventoryStatusSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Inventory Status',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatusChip('In Stock', 'in_stock', Colors.green),
            const SizedBox(width: 8),
            _buildStatusChip('Sold Out', 'sold_out', Colors.red),
            const SizedBox(width: 8),
            _buildStatusChip('On Order', 'on_order', Colors.orange),
          ],
        ),
      ],
    );
  }

  Widget _buildStatusChip(String label, String value, Color color) {
    final isSelected = _inventoryStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) setState(() => _inventoryStatus = value);
      },
      backgroundColor: AppColors.background,
      selectedColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? color : AppColors.textPrimary,
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildCategoryDropdowns() {
    return Column(
      children: [
        StreamBuilder<QuerySnapshot>(
          stream: _firebaseService.getCategories(),
          builder: (context, snapshot) {
            final categories =
                snapshot.data?.docs
                    .map(
                      (doc) => app_category.Category.fromJson(
                        doc.data() as Map<String, dynamic>,
                        doc.id,
                      ),
                    )
                    .toList() ??
                [];
            return _buildDropdown<String>(
              value: _selectedCategory,
              hint: 'Select Category',
              icon: Icons.category_outlined,
              items: categories
                  .map(
                    (c) => DropdownMenuItem(value: c.id, child: Text(c.name)),
                  )
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedCategory = v;
                  _categoryObj = categories.firstWhere((c) => c.id == v);
                  _selectedSubcategory =
                      null; // Reset subcategory when category changes
                });
              },
            );
          },
        ),
        if (_selectedCategory != null) ...[
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getSubcategories(_selectedCategory!),
            builder: (context, snapshot) {
              final subcategories =
                  snapshot.data?.docs
                      .map(
                        (doc) => Subcategory.fromJson(
                          doc.data() as Map<String, dynamic>,
                          doc.id,
                        ),
                      )
                      .toList() ??
                  [];
              return _buildDropdown<String>(
                value: _selectedSubcategory,
                hint: 'Select Subcategory',
                icon: Icons.account_tree_outlined,
                items: subcategories
                    .map(
                      (s) =>
                          DropdownMenuItem(value: s.name, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedSubcategory = v),
              );
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        hint: Text(
          hint,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        items: items,
        onChanged: onChanged,
        dropdownColor: AppColors.surface,
        icon: const Icon(Icons.arrow_drop_down, color: AppColors.gold),
        decoration: InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(icon, color: AppColors.gold),
        ),
        style: const TextStyle(color: AppColors.textPrimary),
      ),
    );
  }

  Widget _buildPuritySelector() {
    final options = _categoryObj?.purityOptions ?? ['18K', '20K', '22K'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Purity',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          children: options.map((opt) {
            // Try to parse int if possible for model compatibility,
            // but the model expects int currently.
            // If it's "22K", we might need to handle it.
            // For now, let's stick to int values or mapped values.
            int val = int.tryParse(opt.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
            return _buildPurityChip(val, opt);
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPurityChip(int value, String label) {
    bool isSelected = _selectedPurity == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedPurity = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.2)
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : AppColors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.gold : AppColors.textPrimary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return NetworkImage(url);
  }
}
