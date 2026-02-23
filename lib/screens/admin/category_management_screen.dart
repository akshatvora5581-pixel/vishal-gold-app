import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/category.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/screens/admin/subcategory_management_screen.dart';
import 'package:vishal_gold/services/firebase_service.dart';

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
            icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
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
                    'No categories found',
                    style: GoogleFonts.outfit(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () => _openAddEditCategory(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                    ),
                    child: const Text(
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
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            image: DecorationImage(
              image: _getImageProvider(category.imageUrl),
              fit: BoxFit.cover,
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
    // TODO: Implement Add/Edit Category Modal or Screen
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

  ImageProvider _getImageProvider(String url) {
    if (url.startsWith('assets/')) {
      return AssetImage(url);
    }
    return NetworkImage(url);
  }
}

class _AddEditCategorySheet extends StatefulWidget {
  final Category? category;

  const _AddEditCategorySheet({this.category});

  @override
  State<_AddEditCategorySheet> createState() => _AddEditCategorySheetState();
}

class _AddEditCategorySheetState extends State<_AddEditCategorySheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _imageUrlController;
  final FirebaseService _firebaseService = FirebaseService();
  bool _loading = false;
  File? _imageFile;
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
        // Clear controller if file is picked
        _imageUrlController.clear();
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.category?.name ?? '');
    _imageUrlController = TextEditingController(
      text: widget.category?.imageUrl ?? '',
    );
    _purities = widget.category?.purityOptions != null
        ? List.from(widget.category!.purityOptions)
        : ['18K', '20K', '22K'];
    _purityController = TextEditingController();
    _makingChargeGramController = TextEditingController(
      text: widget.category?.makingChargePerGram.toString() ?? '0.0',
    );
    _makingChargeFlatController = TextEditingController(
      text: widget.category?.makingChargeFlat.toString() ?? '0.0',
    );
  }

  List<String> _purities = [];
  late TextEditingController _purityController;
  late TextEditingController _makingChargeGramController;
  late TextEditingController _makingChargeFlatController;

  @override
  void dispose() {
    _nameController.dispose();
    _imageUrlController.dispose();
    _purityController.dispose();
    _makingChargeGramController.dispose();
    _makingChargeFlatController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final performerId =
        context.read<AuthProvider>().currentUser?.uid ?? 'unknown';

    setState(() => _loading = true);

    try {
      String imageUrl = _imageUrlController.text.trim();

      // Upload image if file picked
      if (_imageFile != null) {
        imageUrl = await _firebaseService.uploadImage(
          imageFile: _imageFile!,
          folder: 'categories',
        );
      }

      if (imageUrl.isEmpty) {
        imageUrl = 'assets/logo.png';
      }

      final data = {
        'name': _nameController.text.trim(),
        'image_url': imageUrl,
        'purity_options': _purities,
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
              widget.category == null ? 'Add Category' : 'Edit Category',
              style: GoogleFonts.playfairDisplay(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.gold,
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Category Name',
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
            const SizedBox(height: 24),
            Text(
              'Purity Options',
              style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: _purities.map((p) {
                return Chip(
                  label: Text(p, style: const TextStyle(fontSize: 12)),
                  backgroundColor: AppColors.gold.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: AppColors.gold),
                  deleteIcon: const Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.red,
                  ),
                  onDeleted: () => setState(() => _purities.remove(p)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purityController,
                    decoration: InputDecoration(
                      labelText: 'Add Purity (e.g., 22K or 92)',
                      labelStyle: const TextStyle(color: AppColors.gold),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.gold),
                  onPressed: () {
                    final val = _purityController.text.trim();
                    if (val.isNotEmpty && !_purities.contains(val)) {
                      setState(() {
                        _purities.add(val);
                        _purityController.clear();
                      });
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _makingChargeGramController,
                    decoration: InputDecoration(
                      labelText: 'Making Charge (/g)',
                      labelStyle: const TextStyle(color: AppColors.gold),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _makingChargeFlatController,
                    decoration: InputDecoration(
                      labelText: 'Making Charge (Flat)',
                      labelStyle: const TextStyle(color: AppColors.gold),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: AppColors.white.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    style: const TextStyle(color: AppColors.textPrimary),
                    keyboardType: TextInputType.number,
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
                  ? const CircularProgressIndicator(color: AppColors.black)
                  : Text(
                      widget.category == null
                          ? 'Create Category'
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
