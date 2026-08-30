import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';

import 'package:vishal_jewelers/models/app_banner.dart';
import 'package:vishal_jewelers/providers/auth_provider.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';
import 'package:vishal_jewelers/providers/preview_provider.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final FirebaseService _firebaseService = FirebaseService();

  @override
  Widget build(BuildContext context) {
    return Consumer<PreviewProvider>(
      builder: (context, previewProvider, _) {
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
              icon: Icon(Icons.arrow_back_ios, color: AppColors.gold, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (previewProvider.pendingChangesCount > 0)
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                  child: TextButton.icon(
                    onPressed: () => _publishAllChanges(context),
                    icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                    label: Text(
                      'Publish (${previewProvider.pendingChangesCount})',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: AppColors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: IconButton(
                  icon: Icon(Icons.add_circle_outline, color: AppColors.gold),
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
                return Center(
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
                        style: TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                );
              }

              return StreamBuilder<QuerySnapshot>(
                stream: _firebaseService.getStagingChanges(),
                builder: (context, stagingSnapshot) {
                  final liveBanners = snapshot.data ?? [];
                  final stagedDocs = stagingSnapshot.data?.docs ?? [];
                  
                  // Filter staging docs to only include 'banners' collection
                  final bannerStagedDocs = stagedDocs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['collection_name'] == FirebaseService.bannersCollection;
                  }).toList();

                  // Use PreviewProvider to merge
                  final banners = previewProvider.mergeWithStaging<AppBanner>(
                    liveBanners,
                    bannerStagedDocs,
                    (data, id) => AppBanner.fromJson(data, id),
                    (item) => item.id,
                    force: true, // Always show staged changes in Admin panel
                  );

                  // Sort in memory for consistency
                  banners.sort((a, b) => a.order.compareTo(b.order));

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
      },
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
                      return Center(
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
                        style: TextStyle(
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
                      activeTrackColor: AppColors.gold,
                      onChanged: (val) {
                        _firebaseService.stageChange(
                          adminId: performerId,
                          collectionName: FirebaseService.bannersCollection,
                          docId: banner.id,
                          data: banner.copyWith(isActive: val).toJson(),
                          changeType: 'update',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Status change staged')),
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
                Divider(height: 24, color: AppColors.cardBorder),
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
          side: BorderSide(color: AppColors.cardBorder),
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
              _firebaseService.stageChange(
                adminId: performerId,
                collectionName: FirebaseService.bannersCollection,
                docId: banner.id,
                changeType: 'delete',
              );
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Banner deletion staged'),
                  backgroundColor: Colors.orange,
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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

  Future<void> _publishAllChanges(BuildContext context) async {
    final auth = context.read<AuthProvider>();
    final adminId = auth.currentUser?.uid ?? 'unknown';

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );

      await _firebaseService.publishAllChanges(adminId);
      
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('All changes published successfully!'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publish failed: $e'), backgroundColor: Colors.redAccent),
        );
      }
    }
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
  late TextEditingController _termsController;
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

  // Category and Subcategory lists for selection
  List<DocumentSnapshot> _categories = [];
  List<DocumentSnapshot> _subcategories = [];

  @override
  void initState() {
    super.initState();
    _existingImageUrl = widget.banner?.imageUrl;
    _titleController = TextEditingController(text: widget.banner?.title ?? '');
    _subtitleController = TextEditingController(text: widget.banner?.subtitle ?? '');
    _termsController = TextEditingController(text: widget.banner?.termsAndConditions ?? '*T&C Applied');
    _actionValueController = TextEditingController(text: widget.banner?.actionValue ?? '');
    _actionType = widget.banner?.actionType ?? 'category';
    _templateType = widget.banner?.templateType ?? 'theme1';
    _isActive = widget.banner?.isActive ?? true;
    _order = widget.banner?.order ?? 0;
    
    _fetchLists();
    
    // Add listeners for live preview updates
    _titleController.addListener(() => setState(() {}));
    _subtitleController.addListener(() => setState(() {}));
    _termsController.addListener(() => setState(() {}));
  }

  Future<void> _fetchLists() async {
    try {
      final categorySnap = await FirebaseFirestore.instance.collection('categories').get();
      final subcategorySnap = await FirebaseFirestore.instance.collection('subcategories').get();
      setState(() {
        _categories = categorySnap.docs;
        _subcategories = subcategorySnap.docs;
      });
    } catch (e) {
      debugPrint('Error fetching lists: $e');
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _termsController.dispose();
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

  Widget _buildBannerPreview() {
    final title = _titleController.text;
    final subtitle = _subtitleController.text;
    final terms = _termsController.text;
    
    Widget imageWidget;
    if (_imageFile != null) {
      imageWidget = Image.file(_imageFile!, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      imageWidget = CachedNetworkImage(
        imageUrl: _existingImageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        placeholder: (context, url) => Container(color: AppColors.surface),
        errorWidget: (context, url, error) => const Icon(Icons.error),
      );
    } else {
      imageWidget = Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.gold.withValues(alpha: 0.5)),
              const SizedBox(height: 12),
              Text('Tap to select image', style: TextStyle(color: AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Container(
      height: 180,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: _buildTemplateContent(imageWidget, title, subtitle, terms),
      ),
    );
  }

  Widget _buildTemplateContent(Widget image, String title, String subtitle, String terms) {
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
                    Text(
                      title.isEmpty ? 'PREVIEW TITLE' : title,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                      maxLines: 2,
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        maxLines: 2,
                      ),
                    ],
                    const SizedBox(height: 4),
                    Text(
                      terms,
                      style: TextStyle(
                        fontSize: 7,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(flex: 2, child: image),
          ],
        );
      case 'full_image':
        return Stack(
          children: [
            image,
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  terms,
                  style: TextStyle(
                    fontSize: 7,
                    color: Colors.white.withValues(alpha: 0.7),
                    fontStyle: FontStyle.italic,
                    backgroundColor: Colors.black26,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'blank':
        return Stack(
          children: [
            Center(child: image),
            Align(
              alignment: Alignment.bottomRight,
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Text(
                   terms,
                  style: TextStyle(
                    fontSize: 6,
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ),
          ],
        );
      case 'theme1':
      default:
        return Stack(
          children: [
            image,
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    title.isEmpty ? 'PREVIEW TITLE' : title,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: AppColors.white.withValues(alpha: 0.9)),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    terms,
                    style: TextStyle(
                      fontSize: 8,
                      color: AppColors.white.withValues(alpha: 0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
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
        termsAndConditions: _termsController.text.trim(),
        imageUrl: finalImageUrl!,
        actionType: _actionType,
        actionValue: _actionValueController.text.trim(),
        isActive: _isActive,
        order: _order,
        templateType: _templateType,
        createdAt: widget.banner?.createdAt ?? DateTime.now(),
      );

      if (widget.banner == null) {
        // Generate a new ID
        final newDocRef = FirebaseFirestore.instance.collection(FirebaseService.bannersCollection).doc();
        await _firebaseService.stageChange(
          adminId: performerId,
          collectionName: FirebaseService.bannersCollection,
          docId: newDocRef.id,
          data: newBanner.toJson(),
          changeType: 'create',
        );
      } else {
        await _firebaseService.stageChange(
          adminId: performerId,
          collectionName: FirebaseService.bannersCollection,
          docId: widget.banner!.id,
          data: newBanner.toJson(),
          changeType: 'update',
        );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.banner == null ? 'Banner creation staged!' : 'Banner update staged!'),
            backgroundColor: AppColors.gold,
            duration: const Duration(seconds: 3),
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
            
            const Text(
              'Banner Preview (Live)',
              style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _pickImage,
              child: _buildBannerPreview(),
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
            _buildTextField(
              controller: _termsController,
              label: 'Terms & Conditions',
              hint: '*T&C Applied',
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: _buildDropdown(
                    label: 'Action Type',
                    value: _actionType,
                    items: [
                      const DropdownMenuItem(value: 'category', child: Text('Category')),
                      const DropdownMenuItem(value: 'product', child: Text('Product')),
                      const DropdownMenuItem(value: 'url', child: Text('URL')),
                      const DropdownMenuItem(value: 'none', child: Text('None')),
                    ],
                    onChanged: (val) => setState(() => _actionType = val!),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildTextField(
                    controller: TextEditingController(text: _order.toString()),
                    label: 'Order',
                    hint: '0',
                    keyboardType: TextInputType.number,
                    onChanged: (val) {
                      if (val.isNotEmpty) {
                        _order = int.tryParse(val) ?? 0;
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_actionType == 'category' || _actionType == 'product')
              _buildDropdown(
                label: _actionType == 'category' ? 'Select Category' : 'Select Subcategory',
                value: (_actionType == 'category' 
                        ? _categories.any((d) => d.id == _actionValueController.text)
                        : _subcategories.any((d) => d.id == _actionValueController.text))
                    ? _actionValueController.text
                    : null,
                items: _actionType == 'category'
                    ? _categories.map((doc) => DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['name'] ?? 'Unnamed'),
                      )).toList()
                    : _subcategories.map((doc) => DropdownMenuItem(
                        value: doc.id,
                        child: Text(doc['name'] ?? 'Unnamed'),
                      )).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => _actionValueController.text = val);
                  }
                },
                isExpanded: true,
              )
            else
              _buildTextField(
                controller: _actionValueController,
                label: 'Action Value',
                hint: _actionType == 'url' ? 'https://...' : 'ID or Slug',
                enabled: _actionType != 'none',
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
                  activeTrackColor: AppColors.gold,
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
                    ? SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: AppColors.black, strokeWidth: 2),
                      )
                    : Text(
                        widget.banner == null ? 'CREATE BANNER' : 'UPDATE BANNER',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1),
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
    TextInputType keyboardType = TextInputType.text,
    Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          enabled: enabled,
          keyboardType: keyboardType,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white24),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
            ),
          ),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdown({
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    bool isExpanded = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty) ...[
          Text(label, style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(height: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items,
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              style: TextStyle(color: Colors.white),
              isExpanded: isExpanded,
              hint: Text('Select...', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTemplateOption(String template, String label) {
    bool isSelected = _templateType == template;
    return GestureDetector(
      onTap: () => setState(() => _templateType = template),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.white10,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              template == 'theme1' ? Icons.crop_original :
              template == 'theme2' ? Icons.splitscreen :
              template == 'full_image' ? Icons.image : Icons.border_all,
              color: isSelected ? AppColors.gold : Colors.white38,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white38,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
