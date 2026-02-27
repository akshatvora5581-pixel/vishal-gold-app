import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/category.dart';
import 'package:vishal_gold/models/subcategory.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';

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
            icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
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
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
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
                    child: const Text(
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
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: _getImageProvider(subcategory.imageUrl),
              fit: BoxFit.cover,
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

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return NetworkImage(url);
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
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
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
              const LinearProgressIndicator(color: AppColors.gold)
            else
              DropdownButtonFormField<String>(
                initialValue: (_categories.any((c) => c.id == _selectedCategoryId))
                    ? _selectedCategoryId
                    : null,
                dropdownColor: AppColors.surface,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Select Category',
                  labelStyle: const TextStyle(color: AppColors.gold),
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
                      style: const TextStyle(color: AppColors.textPrimary),
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
                labelStyle: const TextStyle(color: AppColors.gold),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: AppColors.white.withValues(alpha: 0.3),
                  ),
                ),
              ),
              style: const TextStyle(color: AppColors.textPrimary),
              validator: (v) => v!.isEmpty ? 'Enter name' : null,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _imageUrlController,
                    decoration: InputDecoration(
                      labelText: 'Image URL',
                      labelStyle: const TextStyle(color: AppColors.gold),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    enabled: _imageFile == null,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image, color: AppColors.gold),
                  label: const Text(
                    'Pick',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              ],
            ),
            if (_imageFile != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Image selected: ${_imageFile!.path.split('/').last}',
                    style: const TextStyle(color: Colors.green, fontSize: 12),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.red, size: 16),
                    onPressed: () => setState(() => _imageFile = null),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _loading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _loading
                  ? const CircularProgressIndicator(color: AppColors.black)
                  : Text(
                      widget.subcategory == null
                          ? 'Create Subcategory'
                          : 'Save Changes',
                      style: const TextStyle(
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
