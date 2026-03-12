import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/category.dart' as app_category;
import 'package:vishal_gold/models/subcategory.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/providers/auth_provider.dart';

class AddEditProductSheet extends StatefulWidget {
  final Product? product;

  const AddEditProductSheet({super.key, this.product});

  @override
  State<AddEditProductSheet> createState() => _AddEditProductSheetState();
}

class _AddEditProductSheetState extends State<AddEditProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseService = FirebaseService();
  final _picker = ImagePicker();

  // Controllers
  late TextEditingController _tagController;
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _grossWeightController;
  late TextEditingController _netWeightController;

  // State Notifiers (Performance Optimization)
  late ValueNotifier<String?> _selectedCategoryNotifier;
  late ValueNotifier<app_category.Category?> _categoryObjNotifier;
  late ValueNotifier<String?> _selectedSubcategoryNotifier;
  late ValueNotifier<bool> _isLoadingCategoriesNotifier;
  late ValueNotifier<int> _selectedPurityNotifier;
  late ValueNotifier<List<File>> _newImageFilesNotifier;
  late ValueNotifier<List<String>> _existingImageUrlsNotifier;
  late ValueNotifier<String> _inventoryStatusNotifier;
  late ValueNotifier<bool> _isLoadingNotifier;

  late ValueNotifier<List<app_category.Category>> _categoriesListNotifier;
  late ValueNotifier<List<DropdownMenuItem<String>>?>
  _categoryDropdownItemsNotifier;
  late ValueNotifier<String?> _categoriesErrorNotifier;

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

    _selectedCategoryNotifier = ValueNotifier(widget.product?.category);
    _categoryObjNotifier = ValueNotifier(null);
    _selectedSubcategoryNotifier = ValueNotifier(widget.product?.subcategory);
    _isLoadingCategoriesNotifier = ValueNotifier(true);
    _selectedPurityNotifier = ValueNotifier(widget.product?.purity ?? 22);
    _newImageFilesNotifier = ValueNotifier([]);
    _existingImageUrlsNotifier = ValueNotifier(widget.product?.imageUrls ?? []);
    _inventoryStatusNotifier = ValueNotifier(
      widget.product?.inventoryStatus ?? 'in_stock',
    );
    _isLoadingNotifier = ValueNotifier(false);
    _categoriesListNotifier = ValueNotifier([]);
    _categoryDropdownItemsNotifier = ValueNotifier(null);
    _categoriesErrorNotifier = ValueNotifier(null);

    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final snapshot = await _firebaseService.getCategories().first;
      final categories = snapshot.docs.map((doc) {
        return app_category.Category.fromJson(
          doc.data() as Map<String, dynamic>,
          doc.id,
        );
      }).toList();

      if (mounted) {
        _categoriesListNotifier.value = categories;
        _categoryDropdownItemsNotifier.value = categories
            .map((c) => DropdownMenuItem(value: c.id, child: Text(c.name)))
            .toList();
        _isLoadingCategoriesNotifier.value = false;

        if (_selectedCategoryNotifier.value != null) {
          final match = categories.where(
            (c) => c.id == _selectedCategoryNotifier.value,
          );
          if (match.isNotEmpty) {
            _categoryObjNotifier.value = match.first;
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _isLoadingCategoriesNotifier.value = false;
        _categoriesErrorNotifier.value = 'Failed to load categories';
      }
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _grossWeightController.dispose();
    _netWeightController.dispose();
    _selectedCategoryNotifier.dispose();
    _categoryObjNotifier.dispose();
    _selectedSubcategoryNotifier.dispose();
    _isLoadingCategoriesNotifier.dispose();
    _selectedPurityNotifier.dispose();
    _newImageFilesNotifier.dispose();
    _existingImageUrlsNotifier.dispose();
    _inventoryStatusNotifier.dispose();
    _isLoadingNotifier.dispose();
    _categoriesListNotifier.dispose();
    _categoryDropdownItemsNotifier.dispose();
    _categoriesErrorNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage(imageQuality: 30);
    if (images.isNotEmpty) {
      _newImageFilesNotifier.value = [
        ..._newImageFilesNotifier.value,
        ...images.map((x) => File(x.path)),
      ];
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }
    if (_selectedCategoryNotifier.value == null ||
        _selectedSubcategoryNotifier.value == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select category and subcategory')),
      );
      return;
    }
    if (_newImageFilesNotifier.value.isEmpty &&
        _existingImageUrlsNotifier.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one image')),
      );
      return;
    }

    final performerId =
        context.read<AuthProvider>().currentUser?.uid ?? 'unknown';

    _isLoadingNotifier.value = true;

    try {
      List<String> uploadedUrls = [];

      for (var file in _newImageFilesNotifier.value) {
        String url = await _firebaseService.uploadImage(
          imageFile: file,
          folder: 'products',
        );
        uploadedUrls.add(url);
      }

      final allUrls = [..._existingImageUrlsNotifier.value, ...uploadedUrls];

      final productData = {
        'tag_number': _tagController.text.trim(),
        'category': _selectedCategoryNotifier.value?.trim(),
        'subcategory': _selectedSubcategoryNotifier.value?.trim(),
        'name': _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'image_urls': allUrls,
        'gross_weight': double.parse(_grossWeightController.text),
        'net_weight': double.parse(_netWeightController.text),
        'purity': _selectedPurityNotifier.value,
        'inventory_status': _inventoryStatusNotifier.value,
        'is_active': true,
        'status': 'published', // Ensuring it's set to published
        'uploaded_by': performerId,
        'version': widget.product?.version ?? 1,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (widget.product == null) {
        // New Product
        productData['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance
            .collection('products')
            .add(productData);
      } else {
        // Edit Product
        await FirebaseFirestore.instance
            .collection('products')
            .doc(widget.product!.id)
            .update(productData);
      }

      await _firebaseService.logAdminAction(
        adminId: performerId,
        action: widget.product == null ? 'CREATE_PRODUCT' : 'UPDATE_PRODUCT',
        targetId: widget.product?.id ?? 'new',
        targetType: 'product',
        details:
            '${widget.product == null ? 'Created' : 'Updated'} product: ${_tagController.text.trim()}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.product == null
                  ? 'Product uploaded successfully!'
                  : 'Product updated successfully!',
            ),
            backgroundColor: Colors.green,
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
      if (mounted) _isLoadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Container(
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
                  RepaintBoundary(child: _buildImagePicker()),
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
                  RepaintBoundary(child: _buildCategoryDropdowns()),
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
                  ValueListenableBuilder<bool>(
                    valueListenable: _isLoadingNotifier,
                    builder: (context, isLoading, _) {
                      return SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: isLoading
                              ? const CircularProgressIndicator(
                                  color: AppColors.black,
                                )
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
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
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
          borderSide: BorderSide(color: AppColors.white.withOpacity(0.1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.white.withOpacity(0.1)),
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
        ValueListenableBuilder<List<String>>(
          valueListenable: _existingImageUrlsNotifier,
          builder: (context, existingUrls, _) {
            return ValueListenableBuilder<List<File>>(
              valueListenable: _newImageFilesNotifier,
              builder: (context, newFiles, _) {
                return SingleChildScrollView(
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
                              color: AppColors.gold.withOpacity(0.3),
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
                      ...List.generate(existingUrls.length, (index) {
                        return _buildImageThumbnail(
                          existingUrls[index],
                          isExisting: true,
                          onRemove: () {
                            _existingImageUrlsNotifier.value =
                                List<String>.from(existingUrls)
                                  ..removeAt(index);
                          },
                        );
                      }),
                      ...List.generate(newFiles.length, (index) {
                        return _buildImageThumbnail(
                          newFiles[index],
                          isExisting: false,
                          onRemove: () {
                            _newImageFilesNotifier.value = List<File>.from(
                              newFiles,
                            )..removeAt(index);
                          },
                        );
                      }),
                    ],
                  ),
                );
              },
            );
          },
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
                    ? NetworkImage(image as String)
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
        ValueListenableBuilder<String>(
          valueListenable: _inventoryStatusNotifier,
          builder: (context, inventoryStatus, _) {
            return Row(
              children: [
                _buildStatusChip(
                  'In Stock',
                  'in_stock',
                  Colors.green,
                  inventoryStatus,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'Sold Out',
                  'sold_out',
                  Colors.red,
                  inventoryStatus,
                ),
                const SizedBox(width: 8),
                _buildStatusChip(
                  'On Order',
                  'on_order',
                  Colors.orange,
                  inventoryStatus,
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatusChip(
    String label,
    String value,
    Color color,
    String currentStatus,
  ) {
    final isSelected = currentStatus == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _inventoryStatusNotifier.value = value;
      },
      backgroundColor: AppColors.background,
      selectedColor: color.withOpacity(0.2),
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
        ValueListenableBuilder<bool>(
          valueListenable: _isLoadingCategoriesNotifier,
          builder: (context, isLoading, _) {
            return ValueListenableBuilder<String?>(
              valueListenable: _categoriesErrorNotifier,
              builder: (context, categoriesError, _) {
                return ValueListenableBuilder<String?>(
                  valueListenable: _selectedCategoryNotifier,
                  builder: (context, selectedCategory, _) {
                    if (isLoading) {
                      return _buildDisabledDropdownPlaceholder(
                        Icons.category_outlined,
                        'Loading categories...',
                      );
                    }
                    if (categoriesError != null) {
                      return _buildDisabledDropdownPlaceholder(
                        Icons.error_outline,
                        categoriesError,
                      );
                    }
                    return ValueListenableBuilder<
                      List<DropdownMenuItem<String>>?
                    >(
                      valueListenable: _categoryDropdownItemsNotifier,
                      builder: (context, categoryDropdownItems, _) {
                        if (categoryDropdownItems == null ||
                            categoryDropdownItems.isEmpty) {
                          return _buildDisabledDropdownPlaceholder(
                            Icons.category_outlined,
                            'No categories found',
                          );
                        }

                        return ValueListenableBuilder<
                          List<app_category.Category>
                        >(
                          valueListenable: _categoriesListNotifier,
                          builder: (context, categoriesList, _) {
                            return _buildDropdown<String>(
                              value:
                                  categoriesList.any(
                                    (c) => c.id == selectedCategory,
                                  )
                                  ? selectedCategory
                                  : null,
                              hint: 'Select Category',
                              icon: Icons.category_outlined,
                              items: categoryDropdownItems,
                              onTap: () => FocusScope.of(context).unfocus(),
                              onChanged: (v) {
                                if (v == _selectedCategoryNotifier.value) {
                                  return;
                                }
                                _selectedCategoryNotifier.value = v;
                                _categoryObjNotifier.value = categoriesList
                                    .firstWhere((c) => c.id == v);
                                _selectedSubcategoryNotifier.value = null;
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            );
          },
        ),
        ValueListenableBuilder<String?>(
          valueListenable: _selectedCategoryNotifier,
          builder: (context, selectedCategory, _) {
            if (selectedCategory == null) return const SizedBox.shrink();
            return Column(
              children: [
                const SizedBox(height: 16),
                ValueListenableBuilder<String?>(
                  valueListenable: _selectedSubcategoryNotifier,
                  builder: (context, selectedSubcategory, _) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firebaseService.getSubcategories(
                        selectedCategory,
                      ),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return _buildDisabledDropdownPlaceholder(
                            Icons.account_tree_outlined,
                            'Loading sub-categories...',
                          );
                        }
                        if (snapshot.hasError) {
                          return _buildDisabledDropdownPlaceholder(
                            Icons.error_outline,
                            'Error loading sub-categories',
                          );
                        }
                        final subcategories =
                            snapshot.data?.docs.map((doc) {
                              return Subcategory.fromJson(
                                doc.data() as Map<String, dynamic>,
                                doc.id,
                              );
                            }).toList() ??
                            [];

                        if (subcategories.isEmpty) {
                          return _buildDisabledDropdownPlaceholder(
                            Icons.account_tree_outlined,
                            'No sub-categories for this category',
                          );
                        }

                        // Validation
                        final safeSub =
                            (selectedSubcategory != null &&
                                subcategories.any(
                                  (s) => s.id == selectedSubcategory,
                                ))
                            ? selectedSubcategory
                            : null;

                        return _buildDropdown<String>(
                          value: safeSub,
                          hint: 'Select Subcategory',
                          icon: Icons.account_tree_outlined,
                          items: subcategories.map((s) {
                            return DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name),
                            );
                          }).toList(),
                          onTap: () => FocusScope.of(context).unfocus(),
                          onChanged: (v) {
                            if (v == _selectedSubcategoryNotifier.value) return;
                            _selectedSubcategoryNotifier.value = v;
                          },
                        );
                      },
                    );
                  },
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildDisabledDropdownPlaceholder(IconData icon, String message) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 20),
          const SizedBox(width: 12),
          Text(
            message,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String hint,
    required IconData icon,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    VoidCallback? onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.white.withOpacity(0.1)),
      ),
      child: DropdownButtonFormField<T>(
        initialValue: value,
        hint: Text(
          hint,
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        items: items,
        onChanged: onChanged,
        onTap: onTap,
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
    return ValueListenableBuilder<app_category.Category?>(
      valueListenable: _categoryObjNotifier,
      builder: (context, categoryObj, _) {
        final options = categoryObj?.purityOptions ?? ['18K', '20K', '22K'];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Purity',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 8),
            ValueListenableBuilder<int>(
              valueListenable: _selectedPurityNotifier,
              builder: (context, selectedPurity, _) {
                return Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: options.map((opt) {
                    int val =
                        int.tryParse(opt.replaceAll(RegExp(r'[^0-9]'), '')) ??
                        0;
                    return _buildPurityChip(val, opt, selectedPurity);
                  }).toList(),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildPurityChip(int value, String label, int currentValue) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _selectedPurityNotifier.value = value;
      },
      backgroundColor: AppColors.background,
      selectedColor: AppColors.gold.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.gold : AppColors.textPrimary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
