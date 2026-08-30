import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/providers/product_provider.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';
import 'package:vishal_jewelers/services/whatsapp_service.dart';
import 'package:vishal_jewelers/models/notification.dart';

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
    if (_selectedImages.length >= 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Maximum 4 images allowed')));
      return;
    }

    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isNotEmpty) {
      setState(() {
        // Take only up to 4 images total
        final int remainingSlot = 4 - _selectedImages.length;
        _selectedImages.addAll(
          images.take(remainingSlot).map((x) => File(x.path)),
        );
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _handleUpload() async {
    // 1. Explicit Validation
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a design image first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return; // Form shows field errors
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Authentication required. Please log in.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final productProvider = Provider.of<ProductProvider>(
      context,
      listen: false,
    );

    // 2. Visual Loading State
    setState(() => _isUploading = true);

    try {
      // 3. Safe Upload Logic (Try-Catch)
      // 1. Upload images to Firebase Storage
      final imageUrls = await _firebaseService.uploadMultipleImages(
        imageFiles: _selectedImages,
        folder: 'products',
      );

      // 2. Save product metadata to Firestore
      final productId = await productProvider.uploadProduct(
        tagNumber: _tagController.text.trim(),
        category: _selectedCategory.trim(),
        subcategory: _selectedSubcategory.trim(),
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
        status: 'order_design', // Use 'order_design' to avoid automatic broadcast to all users
      );

      if (mounted) {
        // 3. Send Explicit Admin Notification
        final String customerName = authProvider.displayName;
        final String customerPhone = authProvider.phoneNumber ?? 'No Phone';

        try {
          await _firebaseService.sendNotificationRequest(
            notificationData: {
              'title': 'New Design Uploaded!',
              'body': 'A new design was uploaded by $customerName for review/order.',
              'target': 'admins',
              'type': 'design_upload',
            },
            performedBy: authProvider.currentUser?.uid ?? 'system',
          );

          await _firebaseService.createDbNotification(
            AppNotification(
              id: '', // Firestore will auto-generate document ID
              userId: 'admin',
              title: 'New Design Uploaded!',
              message: 'A new design was uploaded by $customerName ($customerPhone).',
              type: 'design_upload',
              relatedId: productId ?? '',
              createdAt: DateTime.now(),
            ),
          );
        } catch (e) {
          debugPrint('Failed to send admin push notification: $e');
        }

        if (!mounted) return;

        // Success Handling
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Design uploaded successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // 4. Send WhatsApp Notification
        if (!mounted) return;
        await WhatsAppService.notifyAdmin(
          context: context,
          customerName: customerName,
          customerPhone: customerPhone,
          category: _selectedCategory,
          itemName: _nameController.text.trim().isEmpty
              ? _selectedSubcategory
              : _nameController.text.trim(),
          qty: '1',
          size: 'N/A',
          weight: _grossWeightController.text,
          totalWeight: _grossWeightController.text,
          rodium: false,
          huid: false,
          remarks: _descriptionController.text.trim().isEmpty
              ? 'N/A'
              : _descriptionController.text.trim(),
          imageUrls: imageUrls,
        );

        if (mounted) {
          // Clear and pop
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
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
      body: SingleChildScrollView(
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
                                child: Icon(
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
                    RadioGroup<int>(
                      groupValue: _selectedPurity,
                      onChanged: (v) => setState(() => _selectedPurity = v!),
                      child: Row(
                        children: [
                          Radio<int>(value: 84),
                          const Text('84 (20K)'),
                          const SizedBox(width: 20),
                          Radio<int>(value: 92),
                          const Text('92 (22K)'),
                        ],
                      ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _isUploading ? null : _handleUpload,
                        child: _isUploading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Text(
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
