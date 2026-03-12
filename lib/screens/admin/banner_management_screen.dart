import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';

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
        elevation: 0,
        title: Text(
          'Banner Management',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              icon: const Icon(Icons.add_circle_outline, color: AppColors.gold),
              onPressed: () => _openAddEditBanner(context),
              tooltip: 'Add New Banner',
            ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading banners: ${snapshot.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }
          final banners = snapshot.data ?? [];
          if (banners.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.filter_frames_outlined,
                    size: 80,
                    color: AppColors.gold.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No banners created yet',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _openAddEditBanner(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add Your First Banner'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return _buildBannerCard(banner);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddEditBanner(context),
        backgroundColor: AppColors.gold,
        foregroundColor: AppColors.black,
        icon: const Icon(Icons.add),
        label: const Text('Add Banner'),
      ),
    );
  }

  Widget _buildBannerCard(AppBanner banner) {
    final auth = context.read<AuthProvider>();
    final performerId = auth.currentUser?.uid ?? 'unknown';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Image Preview
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                children: [
                  Image.network(
                    banner.imageUrl,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: AppColors.gold),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.background,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_outlined, color: Colors.white24, size: 40),
                          SizedBox(height: 8),
                          Text('Image load failed', style: TextStyle(color: Colors.white24, fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  // Active Badge
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: banner.isActive 
                            ? Colors.green.withValues(alpha: 0.9) 
                            : Colors.grey.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        banner.isActive ? 'ACTIVE' : 'INACTIVE',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        banner.title ?? 'Untitled Banner',
                        style: GoogleFonts.playfairDisplay(
                          color: AppColors.gold,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Switch.adaptive(
                      value: banner.isActive,
                      activeColor: AppColors.gold,
                      onChanged: (val) {
                        _firebaseService.updateBanner(
                          banner.copyWith(isActive: val),
                          performerId,
                        );
                      },
                    ),
                  ],
                ),
                if (banner.subtitle != null && banner.subtitle!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      banner.subtitle!,
                      style: GoogleFonts.outfit(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                  ),
                const Divider(height: 24, color: AppColors.cardBorder),
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.link,
                      label: banner.actionType.toUpperCase(),
                      color: Colors.blueAccent,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.layers_outlined,
                      label: banner.templateType.toUpperCase().replaceAll('_', ' '),
                      color: AppColors.gold,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _openAddEditBanner(context, banner: banner),
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmDelete(banner),
                        icon: const Icon(Icons.delete_outline, size: 18),
                        label: const Text('Delete'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.redAccent,
                          side: BorderSide(color: Colors.redAccent.withValues(alpha: 0.2)),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
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
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Delete Banner',
          style: GoogleFonts.playfairDisplay(color: Colors.redAccent, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'This action cannot be undone. Are you sure you want to delete this banner?',
          style: GoogleFonts.outfit(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              _firebaseService.deleteBanner(banner.id, performerId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Banner deleted successfully'),
                  backgroundColor: Colors.redAccent,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _openAddEditBanner(BuildContext context, {AppBanner? banner}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Flexible(
              child: _AddEditBannerSheet(banner: banner),
            ),
          ],
        ),
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
  final FirebaseService _firebaseService = FirebaseService();

  File? _imageFile;
  String? _existingImageUrl;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.banner?.imageUrl;
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleController = TextEditingController(text: widget.banner?.subtitle ?? '');
    _actionValueController = TextEditingController(text: widget.banner?.actionValue ?? '');
    _actionType = widget.banner?.actionType ?? 'category';
    _templateType = widget.banner?.templateType ?? 'theme1';
    _isActive = widget.banner?.isActive ?? true;
    _order = widget.banner?.order ?? 0;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _actionValueController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      imageQuality: 80,
    );
    if (pickedFile != null) {
      setState(() {
        _imageFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_imageFile == null && (_existingImageUrl == null || _existingImageUrl!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a banner image'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final auth = context.read<AuthProvider>();
      final performerId = auth.currentUser?.uid ?? 'unknown';

      String? finalImageUrl = _existingImageUrl;

      if (_imageFile != null) {
        finalImageUrl = await _firebaseService.uploadBannerImage(_imageFile!);
      }

      final newBanner = AppBanner(
        id: widget.banner?.id ?? '',
        title: _titleController.text.trim(),
        subtitle: _subtitleController.text.trim(),
        imageUrl: finalImageUrl!,
        actionType: _actionType,
        actionValue: _actionValueController.text.trim(),
        isActive: _isActive,
        order: _order,
        templateType: _templateType,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
      );

      if (widget.banner == null) {
        await _firebaseService.addBanner(newBanner, performerId);
      } else {
        await _firebaseService.updateBanner(newBanner, performerId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.banner == null ? 'Banner added!' : 'Banner updated!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.redAccent),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.banner == null ? 'Create New Banner' : 'Edit Banner',
                  style: GoogleFonts.playfairDisplay(
                    color: AppColors.gold,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // Image Picker Area
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder, style: BorderStyle.values[1]), // Dashed would be better if available
                ),
                child: _imageFile != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_imageFile!, fit: BoxFit.cover),
                      )
                    : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.gold.withValues(alpha: 0.5)),
                              const SizedBox(height: 12),
                              Text('Tap to select banner image', style: TextStyle(color: AppColors.textSecondary)),
                              Text('(16:9 aspect ratio recommended)', style: TextStyle(color: AppColors.textTertiary, fontSize: 10)),
                            ],
                          ),
              ),
            ),
            const SizedBox(height: 24),

            _buildTextField(
              controller: _titleController,
              label: 'Title',
              hint: 'e.g. MEGA SUMMER SALE',
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _subtitleController,
              label: 'Subtitle',
              hint: 'e.g. Get up to 50% OFF on all Gold items',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    label: 'Action Type',
                    value: _actionType,
                    items: [
                      const DropdownMenuItem(value: 'category', child: Text('Category Link')),
                      const DropdownMenuItem(value: 'product', child: Text('Specific Product')),
                      const DropdownMenuItem(value: 'url', child: Text('External Website')),
                      const DropdownMenuItem(value: 'none', child: Text('No Action')),
                    ],
                    onChanged: (val) => setState(() => _actionType = val!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    controller: _actionValueController,
                    label: 'Action Value',
                    hint: _actionType == 'url' ? 'https://...' : 'ID or Slug',
                    enabled: _actionType != 'none',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            const Text(
              'Layout Template',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildTemplateOption('theme1', 'Elegant Overlay'),
                  _buildTemplateOption('theme2', 'Side Content'),
                  _buildTemplateOption('full_image', 'Full Image Only'),
                  _buildTemplateOption('blank', 'Clean Minimalism'),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Active Status', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Text('Visibility on User App', style: TextStyle(color: Colors.white38, fontSize: 12)),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _isActive,
                  activeColor: AppColors.gold,
                  onChanged: (val) => setState(() => _isActive = val),
                ),
              ],
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _loading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: AppColors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                      )
                    : Text(
                        widget.banner == null ? 'CREATE BANNER' : 'UPDATE BANNER',
                        style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
                      ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool enabled = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
            fillColor: AppColors.cardBorder.withValues(alpha: 0.1),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          isExpanded: true,
          value: value,
          items: items,
          onChanged: onChanged,
          dropdownColor: AppColors.surface,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            fillColor: AppColors.cardBorder.withValues(alpha: 0.1),
            filled: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateOption(String type, String label) {
    final isSelected = _templateType == type;
    return GestureDetector(
      onTap: () => setState(() => _templateType = type),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : AppColors.cardBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             _buildMiniTemplatePreview(type),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.gold : Colors.white54,
                fontSize: 9,
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
      width: 50,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: Stack(
          children: [
            if (type == 'theme1') ...[
              Container(color: AppColors.gold.withValues(alpha: 0.2)),
              Align(
                alignment: Alignment.bottomLeft,
                child: Container(height: 8, width: 25, margin: const EdgeInsets.all(2), color: Colors.white30),
              ),
            ] else if (type == 'theme2') ...[
              Row(
                children: [
                  Expanded(flex: 3, child: Container(color: Colors.black12)),
                  Expanded(flex: 2, child: Container(color: AppColors.gold.withValues(alpha: 0.3))),
                ],
              ),
            ] else if (type == 'full_image') ...[
              Container(color: AppColors.gold.withValues(alpha: 0.4)),
              const Center(child: Icon(Icons.image, size: 14, color: Colors.white30)),
            ] else ...[
              const Center(child: Icon(Icons.crop_free, size: 14, color: Colors.white24)),
            ],
          ],
        ),
      ),
    );
  }
}
