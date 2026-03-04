import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:vishal_gold/models/app_banner.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/services/firebase_service.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: Text(
          'Banner Management',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: AppColors.gold),
            onPressed: () => _openAddEditBanner(context),
          ),
        ],
      ),
      body: StreamBuilder<List<AppBanner>>(
        stream: _firebaseService.getAllBanners(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          final banners = snapshot.data ?? [];
          if (banners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.image_outlined,
                    size: 64,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No banners found',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerCard(banner);
            },
          );
        },
      ),
    );
  }

  Widget _buildBannerCard(AppBanner banner) {
    final auth = context.read<AuthProvider>();
    final performerId = auth.currentUser?.uid ?? 'unknown';

    return Card(
      color: AppColors.surface,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                banner.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: AppColors.background,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          ListTile(
            title: Text(
              banner.title ?? 'No Title',
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'Action: ${banner.actionType} (${banner.actionValue ?? 'No Value'})',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            trailing: Switch(
              value: banner.isActive,
              activeThumbColor: AppColors.gold,
              onChanged: (val) {
                _firebaseService.updateBanner(
                  banner.copyWith(isActive: val),
                  performerId,
                );
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                onPressed: () => _openAddEditBanner(context, banner: banner),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(banner),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(AppBanner banner) {
    final auth = context.read<AuthProvider>();
    final performerId = auth.currentUser?.uid ?? 'unknown';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Banner',
          style: TextStyle(color: AppColors.gold),
        ),
        content: const Text(
          'Are you sure you want to delete this banner?',
          style: TextStyle(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () {
              _firebaseService.deleteBanner(banner.id, performerId);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openAddEditBanner(BuildContext context, {AppBanner? banner}) {
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
        child: _AddEditBannerSheet(banner: banner),
      ),
    );
  }
}

class _AddEditBannerSheet extends StatefulWidget {
  final AppBanner? banner;
  const _AddEditBannerSheet({this.banner});

  @override
  State<_AddEditBannerSheet> createState() => _AddEditBannerSheetState();
}

class _AddEditBannerSheetState extends State<_AddEditBannerSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _actionValueController;
  late String _actionType;
  late String _templateType;
  late bool _isActive;
  late int _order;
  bool _loading = false;
  String _searchTerm = '';
  final FirebaseService _firebaseService = FirebaseService();

  // Image Upload State
  File? _imageFile;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.banner?.imageUrl;
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleController = TextEditingController(
      text: widget.banner?.subtitle ?? '',
    );
    _actionValueController = TextEditingController(
      text: widget.banner?.actionValue ?? '',
    );
    _actionType = widget.banner?.actionType ?? 'category';
    _templateType = widget.banner?.templateType ?? 'theme1';
    _isActive = widget.banner?.isActive ?? true;
    _order = widget.banner?.order ?? 0;

    _titleController.addListener(() => setState(() {}));
    _subtitleController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.removeListener(() {});
    _subtitleController.removeListener(() {});
    _titleController.dispose();
    _subtitleController.dispose();
    _actionValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null &&
        (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a banner image')),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      final performerId = auth.currentUser?.uid ?? 'unknown';

      String finalImageUrl = _existingImageUrl ?? '';

      // Upload new image if selected
      if (_imageFile != null) {
        finalImageUrl = await _firebaseService.uploadBannerImage(_imageFile!);
      }

      final banner = AppBanner(
        id: widget.banner?.id ?? '',
        imageUrl: finalImageUrl,
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        subtitle: _subtitleController.text.trim().isEmpty
            ? null
            : _subtitleController.text.trim(),
        actionType: _actionType,
        actionValue: _actionValueController.text.trim().isEmpty
            ? null
            : _actionValueController.text.trim(),
        templateType: _templateType,
        isActive: _isActive,
        order: _order,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
      );

      if (widget.banner == null) {
        await _firebaseService.addBanner(banner, performerId);
      } else {
        await _firebaseService.updateBanner(banner, performerId);
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.banner == null ? 'Add New Banner' : 'Edit Banner',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Live Preview',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              _buildLivePreview(),
              const SizedBox(height: 24),

              // Image Picker Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.5),
                    ),
                    image: _imageFile != null
                        ? DecorationImage(
                            image: FileImage(_imageFile!),
                            fit: BoxFit.cover,
                          )
                        : (_existingImageUrl != null &&
                              _existingImageUrl!.isNotEmpty)
                        ? DecorationImage(
                            image: NetworkImage(_existingImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      (_imageFile == null &&
                          (_existingImageUrl == null ||
                              _existingImageUrl!.isEmpty))
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_photo_alternate,
                              size: 48,
                              color: AppColors.gold,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload banner image',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        )
                      : Align(
                          alignment: Alignment.topRight,
                          child: Container(
                            margin: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              icon: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 20,
                              ),
                              onPressed: _pickImage,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Template Type Selection
              const Text(
                'Select Template Layout',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildTemplateOption('theme1', 'Classic'),
                    _buildTemplateOption('theme2', 'Modern'),
                    _buildTemplateOption('full_image', 'Full Image'),
                    _buildTemplateOption('blank', 'Blank'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Only show text fields if template isn't full_image
              if (_templateType != 'full_image') ...[
                TextFormField(
                  controller: _titleController,
                  maxLength: 50,
                  decoration: const InputDecoration(
                    labelText: 'Title (Optional)',
                    counterStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _subtitleController,
                  maxLength: 100,
                  decoration: const InputDecoration(
                    labelText: 'Subtitle (Optional)',
                    counterStyle: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                    ),
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 16),
              ],

              DropdownButtonFormField<String>(
                initialValue: _actionType,
                dropdownColor: AppColors.surface,
                decoration: const InputDecoration(labelText: 'Action Type'),
                items: ['category', 'subcategory', 'product', 'external']
                    .map(
                      (t) => DropdownMenuItem(
                        value: t,
                        child: Text(
                          t,
                          style: const TextStyle(color: AppColors.textPrimary),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _actionType = v!;
                    _actionValueController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              if (_actionType == 'external')
                TextFormField(
                  controller: _actionValueController,
                  decoration: const InputDecoration(
                    labelText: 'URL Link',
                    hintText: 'https://...',
                  ),
                  style: const TextStyle(color: AppColors.textPrimary),
                )
              else
                StreamBuilder<QuerySnapshot>(
                  stream: _actionType == 'category'
                      ? _firebaseService.getCategories()
                      : _actionType == 'subcategory'
                      ? _firebaseService.getSubcategories(null)
                      : _firebaseService.getProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    }

                    final items =
                        snapshot.data?.docs.where((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = (data['name'] ?? data['title'] ?? doc.id)
                              .toString()
                              .toLowerCase();
                          return name.contains(_searchTerm.toLowerCase());
                        }).toList() ??
                        [];

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Search $_actionType...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.gold,
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _searchTerm = val;
                            });
                          },
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          initialValue:
                              items.any(
                                (doc) => doc.id == _actionValueController.text,
                              )
                              ? _actionValueController.text
                              : null,
                          dropdownColor: AppColors.surface,
                          decoration: InputDecoration(
                            labelText:
                                'Select ${_actionType.substring(0, 1).toUpperCase()}${_actionType.substring(1)}',
                          ),
                          items: items.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            return DropdownMenuItem(
                              value: doc.id,
                              child: Text(
                                data['name'] ?? data['title'] ?? doc.id,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              _actionValueController.text = val ?? '';
                            });
                          },
                        ),
                      ],
                    );
                  },
                ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Active',
                    style: TextStyle(color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  Switch(
                    value: _isActive,
                    onChanged: (v) => setState(() => _isActive = v),
                    activeThumbColor: AppColors.gold,
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
                        widget.banner == null ? 'Add Banner' : 'Update Banner',
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
      ),
    );
  }

  Widget _buildLivePreview() {
    return Container(
      height: 180,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: _buildMockBannerContent(),
      ),
    );
  }

  Widget _buildMockBannerContent() {
    ImageProvider? imageProvider;
    if (_imageFile != null) {
      imageProvider = FileImage(_imageFile!);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageProvider = NetworkImage(_existingImageUrl!);
    } else {
      // Placeholder if no image is present
      return Center(
        child: Text(
          'Preview Area',
          style: TextStyle(
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      );
    }

    final title = _titleController.text.isNotEmpty
        ? _titleController.text
        : null;
    final subtitle = _subtitleController.text.isNotEmpty
        ? _subtitleController.text
        : null;

    switch (_templateType) {
      case 'theme2':
        return Row(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (title != null)
                      Text(
                        title,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.gold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Image(
                image: imageProvider,
                fit: BoxFit.cover,
                height: double.infinity,
                width: double.infinity,
              ),
            ),
          ],
        );
      case 'full_image':
        return Image(
          image: imageProvider,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        );
      case 'blank':
        return Image(
          image: imageProvider,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
        );
      case 'theme1':
      default:
        return Stack(
          children: [
            Image(
              image: imageProvider,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
            if (title != null || subtitle != null)
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.7),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (title != null)
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
    }
  }

  Widget _buildTemplateOption(String type, String label) {
    final isSelected = _templateType == type;
    return GestureDetector(
      onTap: () => setState(() => _templateType = type),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.gold.withValues(alpha: 0.1)
              : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.gold
                : AppColors.gold.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildMiniTemplatePreview(type),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppColors.gold : AppColors.textSecondary,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniTemplatePreview(String type) {
    return Container(
      width: 60,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
      ),
      child: _buildMiniContent(type),
    );
  }

  Widget _buildMiniContent(String type) {
    switch (type) {
      case 'theme1':
        return Stack(
          children: [
            Container(color: AppColors.gold.withValues(alpha: 0.3)),
            Align(
              alignment: Alignment.bottomLeft,
              child: Container(
                height: 10,
                width: 30,
                margin: const EdgeInsets.all(4),
                color: Colors.white,
              ),
            ),
          ],
        );
      case 'theme2':
        return Row(
          children: [
            Expanded(
              flex: 2,
              child: Center(
                child: Container(height: 5, width: 20, color: AppColors.gold),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(color: AppColors.gold.withValues(alpha: 0.3)),
            ),
          ],
        );
      case 'full_image':
        return Container(
          color: AppColors.gold.withValues(alpha: 0.5),
          child: const Center(
            child: Icon(Icons.image, size: 20, color: Colors.white70),
          ),
        );
      case 'blank':
        return const Center(
          child: Icon(
            Icons.crop_free,
            size: 20,
            color: AppColors.textSecondary,
          ),
        );
      default:
        return Container();
    }
  }
}
