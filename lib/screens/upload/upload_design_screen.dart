import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/providers/product_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class UploadDesignScreen extends StatefulWidget {
  const UploadDesignScreen({super.key});

  @override
  State<UploadDesignScreen> createState() => _UploadDesignScreenState();
}

class _UploadDesignScreenState extends State<UploadDesignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tagController = TextEditingController();
  final _grossWeightController = TextEditingController();
  final _netWeightController = TextEditingController();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedCategory = '84_ornaments';
  String _selectedSubcategory = 'Ring';
  int _selectedPurity = 84;
  final List<File> _selectedImages = [];
  bool _isUploading = false;

  final ImagePicker _picker = ImagePicker();
  final FirebaseService _firebaseService = FirebaseService();

  final List<String> _categories = [
    '84_ornaments',
    '92_ornaments',
    '92_chains',
  ];

  final Map<String, List<String>> _subcategories = {
    '84_ornaments': ['Ring', 'Earring', 'Pendant', 'Bangle', 'Bracelet', 'Set'],
    '92_ornaments': ['Ring', 'Earring', 'Pendant', 'Bangle', 'Bracelet', 'Set'],
    '92_chains': ['Mens Chain', 'Ladies Chain', 'Thin Chain', 'Heavy Chain'],
  };

  Future<void> _pickImages() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((x) => File(x.path)));
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleUpload() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one image')),
      );
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    if (authProvider.currentUser == null) return;

    setState(() => _isUploading = true);

    try {
      // 1. Upload images to Firebase Storage
      final imageUrls = await _firebaseService.uploadMultipleImages(
        imageFiles: _selectedImages,
        folder: 'products',
      );

      // 2. Save product metadata to Firestore
      await productProvider.uploadProduct(
        tagNumber: _tagController.text.trim(),
        category: _selectedCategory,
        subcategory: _selectedSubcategory,
        grossWeight: double.parse(_grossWeightController.text),
        netWeight: double.parse(_netWeightController.text),
        purity: _selectedPurity,
        imageUrls: imageUrls,
        uploadedBy: authProvider.currentUser!.uid,
        name: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Product uploaded successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  void dispose() {
    _tagController.dispose();
    _grossWeightController.dispose();
    _netWeightController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Upload Design')),
      body: _isUploading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: AppColors.gold),
                  const SizedBox(height: 16),
                  Text(
                    'Uploading design...',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Picker Section
                    const Text(
                      'Product Images',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 120,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _selectedImages.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _selectedImages.length) {
                            return InkWell(
                              onTap: _pickImages,
                              child: Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.gold,
                                    style: BorderStyle.solid,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(
                                  Icons.add_a_photo,
                                  color: AppColors.gold,
                                ),
                              ),
                            );
                          }
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 8),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: FileImage(_selectedImages[index]),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 8,
                                child: InkWell(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(2),
                                    decoration: const BoxDecoration(
                                      color: Colors.black54,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Primary Form Fields
                    TextFormField(
                      controller: _tagController,
                      decoration: const InputDecoration(
                        labelText: 'Tag Number *',
                        hintText: 'e.g. RING001',
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _grossWeightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Gross Weight (g) *',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            controller: _netWeightController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Net Weight (g) *',
                            ),
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Dropdowns for Category/Subcategory
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.replaceAll('_', ' ').toUpperCase()),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          _selectedCategory = v!;
                          _selectedSubcategory =
                              _subcategories[_selectedCategory]![0];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedSubcategory,
                      decoration: const InputDecoration(
                        labelText: 'Subcategory',
                      ),
                      items: _subcategories[_selectedCategory]!
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedSubcategory = v!),
                    ),
                    const SizedBox(height: 16),

                    // Purity Selection
                    const Text(
                      'Purity',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Radio<int>(
                          value: 84,
                          groupValue: _selectedPurity,
                          onChanged: (v) =>
                              setState(() => _selectedPurity = v!),
                        ),
                        const Text('84 (20K)'),
                        const SizedBox(width: 20),
                        Radio<int>(
                          value: 92,
                          groupValue: _selectedPurity,
                          onChanged: (v) =>
                              setState(() => _selectedPurity = v!),
                        ),
                        const Text('92 (22K)'),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Optional Fields
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Product Name (Optional)',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description (Optional)',
                      ),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.gold,
                        ),
                        onPressed: _handleUpload,
                        child: const Text(
                          'UPLOAD DESIGN',
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}
