import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/models/category.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/screens/admin/subcategory_management_screen.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Manage Categories',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.gold),
            onPressed: () => _openAddEditCategory(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getCategories(onlyActive: false),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No categories found',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _openAddEditCategory(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                    ),
                    child: Text(
                      'Add First Category',
                      style: TextStyle(color: AppColors.black),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final category = Category.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return _buildCategoryTile(context, category);
            },
          );
        },
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, Category category) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: RepaintBoundary(
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              image: DecorationImage(
                image: CachedNetworkImageProvider(category.imageUrl),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: category.isActive
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          category.isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            color: category.isActive ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () =>
                  _openAddEditCategory(context, category: category),
            ),
            IconButton(
              icon: Icon(
                category.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.gold,
              ),
              onPressed: () => _toggleCategoryStatus(category),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _confirmDeleteCategory(context, category),
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SubcategoryManagementScreen(category: category),
            ),
          );
        },
      ),
    );
  }

  void _openAddEditCategory(BuildContext context, {Category? category}) {
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
        child: _AddEditCategorySheet(category: category),
      ),
    );
  }

  Future<void> _toggleCategoryStatus(Category category) async {
    try {
      final performerId =
          context.read<AuthProvider>().currentUser?.uid ?? 'unknown';
      await _firebaseService.updateCategory(
        id: category.id,
        data: {'is_active': !category.isActive},
        performedBy: performerId,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _confirmDeleteCategory(
    BuildContext context,
    Category category,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Category?',
          style: GoogleFonts.playfairDisplay(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${category.name}"?\n\nAll products under it might become inaccessible.',
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteCategory(category);
    }
  }

  Future<void> _deleteCategory(Category category) async {
    try {
      await FirebaseFirestore.instance
          .collection('categories')
          .doc(category.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${category.name}" deleted successfully.'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete failed: ${e.toString()}')),
        );
      }
    }
  }

}

// ---------------------------------------------------------------------------
// Optimized Add/Edit Category Sheet
// Uses ValueNotifier + ValueListenableBuilder for targeted rebuilds.
// Text fields are NEVER rebuilt by image/purity/loading state changes.
// ---------------------------------------------------------------------------

class _AddEditCategorySheet extends StatefulWidget {
  final Category? category;

  const _AddEditCategorySheet({this.category});

  @override
  State<_AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<_AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final _picker = ImagePicker();

  // --- TextEditingControllers (no setState needed, they manage their own state) ---
  late final TextEditingController _nameController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _purityController;
  late final TextEditingController _makingChargeGramController;
  late final TextEditingController _makingChargeFlatController;

  // --- ValueNotifiers (targeted rebuilds, no full-widget setState) ---
  late final ValueNotifier<bool> _loadingNotifier;
  late final ValueNotifier<File?> _imageFileNotifier;
  late final ValueNotifier<List<String>> _puritiesNotifier;

  @override
  void initState() {
    super.initState();

    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _imageUrlController = TextEditingController(
      text: widget.category?.imageUrl ?? '',
    );
    _purityController = TextEditingController();
    _makingChargeGramController = TextEditingController(
      text: widget.category?.makingChargePerGram.toString() ?? '0.0',
    );
    _makingChargeFlatController = TextEditingController(
      text: widget.category?.makingChargeFlat.toString() ?? '0.0',
    );

    _loadingNotifier = ValueNotifier<bool>(false);
    _imageFileNotifier = ValueNotifier<File?>(null);
    _puritiesNotifier = ValueNotifier<List<String>>(
      widget.category?.purityOptions != null
          ? List<String>.from(widget.category!.purityOptions)
          : ['18K', '20K', '22K'],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _purityController.dispose();
    _makingChargeGramController.dispose();
    _makingChargeFlatController.dispose();
    _loadingNotifier.dispose();
    _imageFileNotifier.dispose();
    _puritiesNotifier.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 30,
    );
    if (pickedFile != null) {
      _imageFileNotifier.value = File(pickedFile.path);
      _imageUrlController.clear();
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final performerId =
        context.read<AuthProvider>().currentUser?.uid ?? 'unknown';

    _loadingNotifier.value = true;

    try {
      String imageUrl = _imageUrlController.text.trim();

      if (_imageFileNotifier.value != null) {
        imageUrl = await _firebaseService.uploadImage(
          imageFile: _imageFileNotifier.value!,
          folder: 'categories',
        );
      }

      if (imageUrl.isEmpty) {
        imageUrl = 'assets/logo.png';
      }

      final data = {
        'name': _nameController.text.trim(),
        'image_url': imageUrl,
        'purity_options': _puritiesNotifier.value,
        'making_charge_per_gram':
            double.tryParse(_makingChargeGramController.text) ?? 0.0,
        'making_charge_flat':
            double.tryParse(_makingChargeFlatController.text) ?? 0.0,
        'is_active': widget.category?.isActive ?? true,
      };

      if (widget.category == null) {
        debugPrint('ℹ️ Adding new category: $data (by $performerId)');
        await _firebaseService.addCategory(data, performerId);
        debugPrint('✅ Category added successfully');
      } else {
        await _firebaseService.updateCategory(
          id: widget.category!.id,
          data: data,
          performedBy: performerId,
        );
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) _loadingNotifier.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Title (static, never rebuilds) ---
              Text(
                widget.category == null ? 'Add Category' : 'Edit Category',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 24),

              // --- Category Name (isolated, no rebuild from other state) ---
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Category Name',
                  labelStyle: TextStyle(color: AppColors.gold),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                style: TextStyle(color: AppColors.textPrimary),
                validator: (v) => v!.isEmpty ? 'Enter name' : null,
              ),
              const SizedBox(height: 16),

              // --- Image Section (wrapped in RepaintBoundary + ValueListenableBuilder) ---
              RepaintBoundary(
                child: ValueListenableBuilder<File?>(
                  valueListenable: _imageFileNotifier,
                  builder: (context, imageFile, _) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: _imageUrlController,
                                decoration: InputDecoration(
                                  labelText: 'Image URL',
                                  labelStyle: TextStyle(
                                    color: AppColors.gold,
                                  ),
                                  enabledBorder: UnderlineInputBorder(
                                    borderSide: BorderSide(
                                      color: AppColors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                    ),
                                  ),
                                ),
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                                enabled: imageFile == null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            TextButton.icon(
                              onPressed: _pickImage,
                              icon: Icon(
                                Icons.image,
                                color: AppColors.gold,
                              ),
                              label: Text(
                                'Pick',
                                style: TextStyle(color: AppColors.gold),
                              ),
                            ),
                          ],
                        ),
                        if (imageFile != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  'Image selected: ${imageFile.path.split(Platform.pathSeparator).last}',
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                  size: 16,
                                ),
                                onPressed: () =>
                                    _imageFileNotifier.value = null,
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // --- Purity Options (only this section rebuilds on chip changes) ---
              Text(
                'Purity Options',
                style: GoogleFonts.outfit(
                  color: AppColors.gold,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<List<String>>(
                valueListenable: _puritiesNotifier,
                builder: (context, purities, _) {
                  return Wrap(
                    spacing: 8,
                    children: purities.map((p) {
                      return Chip(
                        label: Text(p, style: TextStyle(fontSize: 12)),
                        backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                        labelStyle: TextStyle(color: AppColors.gold),
                        deleteIcon: const Icon(
                          Icons.close,
                          size: 14,
                          color: Colors.red,
                        ),
                        onDeleted: () {
                          _puritiesNotifier.value = List<String>.from(purities)
                            ..remove(p);
                        },
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _purityController,
                      decoration: InputDecoration(
                        labelText: 'Add Purity (e.g., 22K or 92)',
                        labelStyle: TextStyle(color: AppColors.gold),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.add_circle, color: AppColors.gold),
                    onPressed: () {
                      final val = _purityController.text.trim();
                      if (val.isNotEmpty &&
                          !_puritiesNotifier.value.contains(val)) {
                        _puritiesNotifier.value = [
                          ..._puritiesNotifier.value,
                          val,
                        ];
                        _purityController.clear();
                      }
                    },
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // --- Making Charges (isolated, no rebuild from other state) ---
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _makingChargeGramController,
                      decoration: InputDecoration(
                        labelText: 'Making Charge (/g)',
                        labelStyle: TextStyle(color: AppColors.gold),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _makingChargeFlatController,
                      decoration: InputDecoration(
                        labelText: 'Making Charge (Flat)',
                        labelStyle: TextStyle(color: AppColors.gold),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.white.withValues(alpha: 0.3),
                          ),
                        ),
                      ),
                      style: TextStyle(color: AppColors.textPrimary),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // --- Save Button (only rebuilds on loading state change) ---
              ValueListenableBuilder<bool>(
                valueListenable: _loadingNotifier,
                builder: (context, loading, _) {
                  return ElevatedButton(
                    onPressed: loading ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: loading
                        ? CircularProgressIndicator(
                            color: AppColors.black,
                          )
                        : Text(
                            widget.category == null
                                ? 'Create Category'
                                : 'Save Changes',
                            style: TextStyle(
                              color: AppColors.black,
                              fontWeight: FontWeight.bold,
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
    );
  }
}
