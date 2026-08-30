import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/models/category.dart';
import 'package:vishal_jewelers/models/subcategory.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';

class SubcategoryManagementScreen extends StatefulWidget {
  final Category? category;

  const SubcategoryManagementScreen({super.key, this.category});

  @override
  State<SubcategoryManagementScreen> createState() =>
      _SubcategoryManagementScreenState();
}

class _SubcategoryManagementScreenState
    extends State<SubcategoryManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          widget.category != null
              ? '${widget.category!.name} > Subcategories'
              : 'All Subcategories',
          style: GoogleFonts.outfit(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: AppColors.gold),
            onPressed: () => _openAddEditSubcategory(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firebaseService.getSubcategories(
          widget.category?.id,
          onlyActive: false,
        ),
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
                    widget.category != null
                        ? 'No subcategories found in ${widget.category!.name}'
                        : 'No subcategories found',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _openAddEditSubcategory(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                    ),
                    child: Text(
                      'Add First Subcategory',
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
              final subcategory = Subcategory.fromJson(
                doc.data() as Map<String, dynamic>,
                doc.id,
              );

              return _buildSubcategoryTile(context, subcategory);
            },
          );
        },
      ),
    );
  }

  Widget _buildSubcategoryTile(BuildContext context, Subcategory subcategory) {
    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 50,
            height: 50,
            child:
                subcategory.imageUrl.isNotEmpty &&
                    !subcategory.imageUrl.startsWith('assets/')
                ? CachedNetworkImage(
                    imageUrl: subcategory.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (_, _ ) => Container(
                      color: AppColors.background,
                      child: Center(
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.gold,
                          ),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.background,
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                        size: 24,
                      ),
                    ),
                  )
                : Container(
                    color: AppColors.background,
                    child: Icon(
                      Icons.category_outlined,
                      color: AppColors.textSecondary,
                      size: 24,
                    ),
                  ),
          ),
        ),
        title: Text(
          subcategory.name,
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.bold,
            color: subcategory.isActive
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        ),
        subtitle: Text(
          subcategory.isActive ? 'Active' : 'Inactive',
          style: TextStyle(
            color: subcategory.isActive ? Colors.green : Colors.red,
            fontSize: 12,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.blue),
              onPressed: () =>
                  _openAddEditSubcategory(context, subcategory: subcategory),
            ),
            IconButton(
              icon: Icon(
                subcategory.isActive
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.gold,
              ),
              onPressed: () => _toggleSubcategoryStatus(subcategory),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever, color: Colors.red),
              onPressed: () => _confirmDeleteSubcategory(context, subcategory),
            ),
          ],
        ),
      ),
    );
  }

  void _openAddEditSubcategory(
    BuildContext context, {
    Subcategory? subcategory,
  }) {
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
        child: _AddEditSubcategorySheet(
          categoryId: widget.category?.id ?? '',
          subcategory: subcategory,
        ),
      ),
    );
  }

  Future<void> _toggleSubcategoryStatus(Subcategory subcategory) async {
    try {
      final performerId =
          context.read<AuthProvider>().currentUser?.uid ?? 'unknown';
      await _firebaseService.updateSubcategory(
        id: subcategory.id,
        data: {'is_active': !subcategory.isActive},
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

  Future<void> _confirmDeleteSubcategory(
    BuildContext context,
    Subcategory subcategory,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Delete Subcategory?',
          style: GoogleFonts.playfairDisplay(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Are you sure you want to delete "${subcategory.name}"?\n\nAll products under it might become inaccessible.',
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
      await _deleteSubcategory(subcategory);
    }
  }

  Future<void> _deleteSubcategory(Subcategory subcategory) async {
    try {
      await FirebaseFirestore.instance
          .collection('subcategories')
          .doc(subcategory.id)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"${subcategory.name}" deleted successfully.'),
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

class _AddEditSubcategorySheet extends StatefulWidget {
  final String categoryId;
  final Subcategory? subcategory;

  const _AddEditSubcategorySheet({required this.categoryId, this.subcategory});

  @override
  State<_AddEditSubcategorySheet> createState() =>
      _AddEditSubcategorySheetState();
}

class _AddEditSubcategorySheetState extends State<_AddEditSubcategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;
  File? _imageFile;
  final _picker = ImagePicker();
  String? _selectedCategoryId;
  List<Category> _categories = [];
  bool _fetchingCategories = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.subcategory?.name ?? '',
    );
    _imageUrlController = TextEditingController(
      text: widget.subcategory?.imageUrl ?? '',
    );
    _selectedCategoryId = widget.categoryId.isNotEmpty
        ? widget.categoryId
        : widget.subcategory?.categoryId;
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    setState(() => _fetchingCategories = true);
    try {
      final snapshot = await _firebaseService
          .getCategories(onlyActive: false)
          .first;
      setState(() {
        _categories = snapshot.docs.map((doc) {
          return Category.fromJson(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();

        // If categoryId was passed but not in list (edge case), or if editing
        if (_selectedCategoryId != null &&
            !_categories.any((c) => c.id == _selectedCategoryId)) {
          // Keep it or set to null? Better keep it if it's there.
        }
      });
    } catch (e) {
      debugPrint('Error fetching categories: $e');
    } finally {
      if (mounted) setState(() => _fetchingCategories = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100, // Full quality — no compression
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        _imageUrlController.clear();
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final performerId =
        context.read<AuthProvider>().currentUser?.uid ?? 'unknown';

    setState(() => _loading = true);

    try {
      String imageUrl = _imageUrlController.text.trim();

      if (_imageFile != null) {
        imageUrl = await _firebaseService.uploadImage(
          imageFile: _imageFile!,
          folder: 'subcategories',
        );
      }

      if (imageUrl.isEmpty) {
        imageUrl = 'assets/images/earrings.png'; // Default placeholder
      }

      if (_selectedCategoryId == null || _selectedCategoryId!.isEmpty) {
        throw 'Please select a parent category';
      }

      final data = {
        'category_id': _selectedCategoryId,
        'name': _nameController.text.trim(),
        'image_url': imageUrl,
        'is_active': widget.subcategory?.isActive ?? true,
      };

      if (widget.subcategory == null) {
        debugPrint('ℹ️ Adding new subcategory: $data (by $performerId)');
        await _firebaseService.addSubcategory(data, performerId);
        debugPrint('✅ Subcategory added successfully');
      } else {
        await _firebaseService.updateSubcategory(
          id: widget.subcategory!.id,
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
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.subcategory == null
                  ? 'Add Subcategory'
                  : 'Edit Subcategory',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            if (_fetchingCategories)
              LinearProgressIndicator(color: AppColors.gold)
            else
              DropdownButtonFormField<String>(
                initialValue: (_categories.any((c) => c.id == _selectedCategoryId))
                    ? _selectedCategoryId
                    : null,
                dropdownColor: AppColors.surface,
                style: TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  labelStyle: TextStyle(color: AppColors.gold),
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: AppColors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
                items: _categories.map((c) {
                  return DropdownMenuItem(
                    value: c.id,
                    child: Text(
                      c.name,
                      style: TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() => _selectedCategoryId = val);
                },
                validator: (v) => v == null ? 'Select a category' : null,
              ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Subcategory Name',
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
            // ── Banner Image Section ──
            Text(
              'Subcategory Banner Image',
              style: TextStyle(color: AppColors.gold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // 16:9 Banner Preview
            AspectRatio(
              aspectRatio: 16 / 9,
              child: GestureDetector(
                onTap: _pickImage,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: _imageFile != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(_imageFile!, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: () => setState(() => _imageFile = null),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : _imageUrlController.text.trim().isNotEmpty &&
                            !_imageUrlController.text.trim().startsWith(
                              'assets/',
                            )
                      ? Image.network(
                          _imageUrlController.text.trim(),
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppColors.background,
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.gold,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: AppColors.background,
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.broken_image,
                                    color: AppColors.textSecondary,
                                    size: 40,
                                  ),
                                  SizedBox(height: 8),
                                  Text(
                                    'Failed to load image',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: AppColors.background,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  color: AppColors.gold,
                                  size: 40,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Tap to select banner image',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Manual URL input (fallback)
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Or paste Image URL',
                      labelStyle: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                    ),
                    enabled: _imageFile == null,
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? CircularProgressIndicator(color: AppColors.black)
                  : Text(
                      widget.subcategory == null
                          ? 'Create Subcategory'
                          : 'Save Changes',
                      style: TextStyle(
                        color: AppColors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
