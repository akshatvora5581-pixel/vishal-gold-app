import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/supabase_service.dart';
import 'package:vishal_gold/services/image_picker_service.dart';

class UploadDesignScreen extends StatefulWidget {
  final List<XFile>? images;

  const UploadDesignScreen({super.key, this.images});

  @override
  State<UploadDesignScreen> createState() => _UploadDesignScreenState();
}

class _UploadDesignScreenState extends State<UploadDesignScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _qtyController = TextEditingController();
  final _sizeController = TextEditingController();
  final _weightPerQtyController = TextEditingController();
  final _totalController = TextEditingController();
  final _imagePickerService = ImagePickerService();

  List<XFile> _selectedImages = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String _uploadStatus = '';

  // Category options
  String? _selectedCategory;
  final List<Map<String, String>> _categories = [
    {'value': '84_ornaments', 'label': '84 Ornaments'},
    {'value': '92_ornaments', 'label': '92 Ornaments'},
    {'value': '92_chain', 'label': '92 Chain'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.images != null) {
      _selectedImages = List.from(widget.images!);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _itemNameController.dispose();
    _qtyController.dispose();
    _sizeController.dispose();
    _weightPerQtyController.dispose();
    _totalController.dispose();
    super.dispose();
  }

  Future<void> _addMoreImages() async {
    final source = await _imagePickerService.showImageSourcePicker(context);
    if (source == null) return;

    if (source == ImageSource.gallery) {
      final images = await _imagePickerService.pickMultipleImages(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages.addAll(images);
        });
      }
    } else {
      final image = await _imagePickerService.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() {
          _selectedImages.add(image);
        });
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _submitDesign() async {
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one image'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadStatus = 'Starting upload...';
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user == null) {
      setState(() => _isUploading = false);
      return;
    }

    final supabaseService = SupabaseService();

    try {
      // Upload images
      List<String> imageUrls = [];
      for (int i = 0; i < _selectedImages.length; i++) {
        setState(() {
          _uploadProgress = (i / _selectedImages.length);
          _uploadStatus =
              'Uploading image ${i + 1} of ${_selectedImages.length}...';
        });

        final bytes = await _selectedImages[i].readAsBytes();
        final url = await supabaseService.uploadImage(
          _selectedImages[i].path,
          bytes,
        );
        imageUrls.add(url);
      }

      setState(() {
        _uploadProgress = 0.9;
        _uploadStatus = 'Saving design...';
      });

      // Create upload entry
      await supabaseService.createWholesalerUpload(
        userId: authProvider.user!.id,
        imageUrls: imageUrls,
        description: _descriptionController.text.trim(),
        category: _selectedCategory,
        itemName: _itemNameController.text.trim(),
        quantity: _qtyController.text.trim(),
        size: _sizeController.text.trim(),
        weightPerQty: _weightPerQtyController.text.trim(),
        total: _totalController.text.trim(),
      );

      setState(() {
        _uploadProgress = 1.0;
        _uploadStatus = 'Complete!';
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Design uploaded successfully!'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = 0.0;
          _uploadStatus = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Upload Design'),
        actions: [
          if (_selectedImages.isNotEmpty && !_isUploading)
            TextButton(
              onPressed: _submitDesign,
              child: const Text(
                'Upload',
                style: TextStyle(
                  color: AppColors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Category Selection Section
              Text(
                'Product Details',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.oliveGreen,
                ),
              ),
              const SizedBox(height: 16),

              // Category Dropdown
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Select Category *',
                  prefixIcon: const Icon(
                    Icons.category,
                    color: AppColors.oliveGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                items: _categories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['value'],
                    child: Text(category['label']!),
                  );
                }).toList(),
                onChanged: _isUploading
                    ? null
                    : (value) {
                        setState(() {
                          _selectedCategory = value;
                        });
                      },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a category';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Item Name
              TextFormField(
                controller: _itemNameController,
                enabled: !_isUploading,
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'Enter item name',
                  prefixIcon: const Icon(
                    Icons.label_outline,
                    color: AppColors.oliveGreen,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter item name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Quantity and Size Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _qtyController,
                      enabled: !_isUploading,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Qty *',
                        hintText: 'e.g. 10',
                        prefixIcon: const Icon(
                          Icons.numbers,
                          color: AppColors.oliveGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _sizeController,
                      enabled: !_isUploading,
                      decoration: InputDecoration(
                        labelText: 'Size *',
                        hintText: 'e.g. 18 inch',
                        prefixIcon: const Icon(
                          Icons.straighten,
                          color: AppColors.oliveGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weight per Qty and Total Row
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _weightPerQtyController,
                      enabled: !_isUploading,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Wt/Qty *',
                        hintText: 'e.g. 5.5g',
                        prefixIcon: const Icon(
                          Icons.scale,
                          color: AppColors.oliveGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalController,
                      enabled: !_isUploading,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Total *',
                        hintText: 'e.g. 55g',
                        prefixIcon: const Icon(
                          Icons.calculate,
                          color: AppColors.oliveGreen,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: AppColors.white,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Divider
              Divider(
                color: AppColors.grey.withValues(alpha: 0.3),
                thickness: 1,
              ),
              const SizedBox(height: 16),

              // Image Selection Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Product Images (${_selectedImages.length})',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!_isUploading)
                    TextButton.icon(
                      onPressed: _addMoreImages,
                      icon: const Icon(Icons.add_photo_alternate),
                      label: const Text('Add More'),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Image Grid
              if (_selectedImages.isEmpty)
                _EmptyImagePlaceholder(onTap: _addMoreImages)
              else
                _ImageGrid(
                  images: _selectedImages,
                  onRemove: _isUploading ? null : _removeImage,
                  onAddMore: _isUploading ? null : _addMoreImages,
                ),
              const SizedBox(height: 24),

              // Description
              TextFormField(
                controller: _descriptionController,
                enabled: !_isUploading,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Add any additional details about your design...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 80),
                    child: Icon(
                      Icons.description_outlined,
                      color: AppColors.oliveGreen,
                    ),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.white,
                ),
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 32),

              // Upload Progress
              if (_isUploading) ...[
                LinearProgressIndicator(
                  value: _uploadProgress,
                  backgroundColor: AppColors.grey.withValues(alpha: 0.2),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.oliveGreen,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _uploadStatus,
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
              ],

              // Submit Button
              ElevatedButton(
                onPressed: _isUploading || _selectedImages.isEmpty
                    ? null
                    : _submitDesign,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.oliveGreen,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: AppColors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Uploading...',
                            style: GoogleFonts.roboto(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Upload Design',
                        style: GoogleFonts.roboto(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),

              const SizedBox(height: 16),

              // Info Text
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.oliveGreen.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.oliveGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Your design will be reviewed by admin before being added to the catalog.',
                        style: GoogleFonts.roboto(
                          fontSize: 12,
                          color: AppColors.oliveGreen,
                        ),
                      ),
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
}

class _EmptyImagePlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const _EmptyImagePlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.grey.withValues(alpha: 0.3),
            width: 2,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 64,
              color: AppColors.grey.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to add images',
              style: GoogleFonts.roboto(fontSize: 16, color: AppColors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'You can select multiple images',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: AppColors.grey.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImageGrid extends StatelessWidget {
  final List<XFile> images;
  final void Function(int)? onRemove;
  final VoidCallback? onAddMore;

  const _ImageGrid({required this.images, this.onRemove, this.onAddMore});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: images.length + (onAddMore != null ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == images.length && onAddMore != null) {
          return _AddMoreButton(onTap: onAddMore!);
        }
        return _ImageTile(
          image: images[index],
          onRemove: onRemove != null ? () => onRemove!(index) : null,
        );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final XFile image;
  final VoidCallback? onRemove;

  const _ImageTile({required this.image, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(image.path),
            width: double.infinity,
            height: double.infinity,
            fit: BoxFit.cover,
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.errorRed,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddMoreButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.grey, size: 32),
            SizedBox(height: 4),
            Text('Add', style: TextStyle(color: AppColors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
