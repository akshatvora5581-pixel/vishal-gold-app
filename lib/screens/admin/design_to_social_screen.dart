import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vishal_gold/constants/app_colors.dart';

/// A sealed-class-style wrapper so we can hold either a local File or a URL.
class _ImageSource {
  final File? file;
  final String? url;

  const _ImageSource.file(File f) : file = f, url = null;
  const _ImageSource.url(String u) : file = null, url = u;

  bool get isFile => file != null;
  ImageProvider get provider =>
      isFile ? FileImage(file!) : NetworkImage(url!) as ImageProvider;
}

class DesignToSocialScreen extends StatefulWidget {
  const DesignToSocialScreen({super.key});

  @override
  State<DesignToSocialScreen> createState() => _DesignToSocialScreenState();
}

class _DesignToSocialScreenState extends State<DesignToSocialScreen>
    with SingleTickerProviderStateMixin {
  final ScreenshotController _screenshotController = ScreenshotController();
  final ImagePicker _imagePicker = ImagePicker();
  late final TabController _tabController;

  _ImageSource? _selectedSource;
  String _selectedBadge = 'New Arrival';
  bool _isSharing = false;

  final List<String> _badges = [
    'New Arrival',
    'Flash Sale',
    'Best Seller',
    'Limited Edition',
    'Diwali Special',
    'Wedding Collection',
  ];

  final List<Map<String, String>> _presets = [
    {
      'label': 'Ring',
      'url':
          'https://images.unsplash.com/photo-1515562141207-7a88fb7ce338?q=80&w=800&auto=format&fit=crop',
    },
    {
      'label': 'Necklace',
      'url':
          'https://images.unsplash.com/photo-1601121141461-9d6647bca1ed?q=80&w=800&auto=format&fit=crop',
    },
    {
      'label': 'Bracelet',
      'url':
          'https://images.unsplash.com/photo-1573408302355-4e0b735fb54c?q=80&w=800&auto=format&fit=crop',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _selectedSource = _ImageSource.url(_presets[0]['url']!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Pickers ──────────────────────────────────────────────────────────────

  Future<void> _pickFromGallery() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      setState(() => _selectedSource = _ImageSource.file(File(picked.path)));
    }
  }

  Future<void> _pickFromCamera() async {
    final XFile? picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked != null && mounted) {
      setState(() => _selectedSource = _ImageSource.file(File(picked.path)));
    }
  }

  // ── Share ────────────────────────────────────────────────────────────────

  Future<void> _shareImage() async {
    if (_selectedSource == null) return;
    setState(() => _isSharing = true);
    try {
      final Uint8List? imageBytes = await _screenshotController.capture();
      if (imageBytes == null) return;
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/vishal_gold_promo.png');
      await file.writeAsBytes(imageBytes);
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '✨ Check out our $_selectedBadge collection at Vishal Gold!');
    } catch (e) {
      debugPrint('Error sharing image: $e');
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F0F),
      appBar: AppBar(
        title: Text(
          'Design-to-Social',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        actions: [
          TextButton.icon(
            onPressed: _isSharing ? null : _shareImage,
            icon: _isSharing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.gold,
                    ),
                  )
                : const Icon(
                    Icons.share_rounded,
                    color: AppColors.gold,
                    size: 18,
                  ),
            label: Text(
              'Share',
              style: GoogleFonts.outfit(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPreview(),
            const SizedBox(height: 32),
            _buildBadgeSelector(),
            const SizedBox(height: 28),
            _buildImageSourcePanel(),
            const SizedBox(height: 36),
            _buildShareButton(),
          ],
        ),
      ),
    );
  }

  // ── Preview Card ─────────────────────────────────────────────────────────

  Widget _buildPreview() {
    return Center(
      child: Screenshot(
        controller: _screenshotController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Main image
              Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: const Color(0xFF1A1A1A),
                ),
                child: _selectedSource != null
                    ? Image(
                        image: _selectedSource!.provider,
                        width: 300,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: Colors.white30,
                            size: 60,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          color: Colors.white30,
                          size: 60,
                        ),
                      ),
              ),

              // Badge
              Positioned(
                top: 14,
                left: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withValues(alpha: 0.4),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Text(
                    _selectedBadge.toUpperCase(),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),

              // Brand watermark
              Positioned(
                bottom: 12,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Vishal Gold',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Badge Selector ───────────────────────────────────────────────────────

  Widget _buildBadgeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Choose Badge'),
        const SizedBox(height: 12),
        SizedBox(
          height: 42,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _badges.length,
            itemBuilder: (context, index) {
              final badge = _badges[index];
              final isSelected = _selectedBadge == badge;
              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: ChoiceChip(
                  label: Text(badge),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _selectedBadge = badge),
                  selectedColor: AppColors.gold,
                  backgroundColor: Colors.white10,
                  labelStyle: GoogleFonts.outfit(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    fontSize: 13,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── Image Source Panel ───────────────────────────────────────────────────

  Widget _buildImageSourcePanel() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionLabel('Choose Image'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            children: [
              // Tab bar
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.gold,
                  labelColor: AppColors.gold,
                  unselectedLabelColor: Colors.white38,
                  labelStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  unselectedLabelStyle: GoogleFonts.outfit(fontSize: 13),
                  tabs: const [
                    Tab(
                      icon: Icon(Icons.photo_library_outlined, size: 18),
                      text: 'Gallery',
                    ),
                    Tab(
                      icon: Icon(Icons.storefront_outlined, size: 18),
                      text: 'Products',
                    ),
                    Tab(
                      icon: Icon(Icons.auto_awesome_outlined, size: 18),
                      text: 'Presets',
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 160,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGalleryTab(),
                    _buildProductsTab(),
                    _buildPresetsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGalleryTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _galleryButton(
            icon: Icons.photo_rounded,
            label: 'From Gallery',
            onTap: _pickFromGallery,
          ),
          _galleryButton(
            icon: Icons.camera_alt_rounded,
            label: 'From Camera',
            onTap: _pickFromCamera,
          ),
          if (_selectedSource?.isFile == true)
            _galleryButton(
              icon: Icons.check_circle_rounded,
              label: 'Change',
              color: AppColors.gold,
              onTap: _pickFromGallery,
            ),
        ],
      ),
    );
  }

  Widget _galleryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withValues(alpha: 0.07),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: (color ?? Colors.white).withValues(alpha: 0.15),
              ),
            ),
            child: Icon(icon, color: color ?? Colors.white60, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              color: color ?? Colors.white54,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('products')
          .where('imageUrl', isGreaterThan: '')
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.gold),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No products with images found',
              style: GoogleFonts.outfit(color: Colors.white38),
            ),
          );
        }
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;
            final url = data['imageUrl'] as String? ?? '';
            if (url.isEmpty) return const SizedBox.shrink();
            final isSelected = _selectedSource?.url == url;
            return GestureDetector(
              onTap: () =>
                  setState(() => _selectedSource = _ImageSource.url(url)),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                width: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.gold : Colors.transparent,
                    width: 2.5,
                  ),
                  image: DecorationImage(
                    image: NetworkImage(url),
                    fit: BoxFit.cover,
                  ),
                ),
                alignment: Alignment.topRight,
                child: isSelected
                    ? Padding(
                        padding: const EdgeInsets.all(4),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: const BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 12,
                          ),
                        ),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildPresetsTab() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(12),
      itemCount: _presets.length,
      itemBuilder: (context, index) {
        final preset = _presets[index];
        final url = preset['url']!;
        final isSelected = _selectedSource?.url == url;
        return GestureDetector(
          onTap: () => setState(() => _selectedSource = _ImageSource.url(url)),
          child: Container(
            margin: const EdgeInsets.only(right: 10),
            width: 110,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF252525)),
                  ),
                ),
                if (isSelected)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.gold,
                        size: 32,
                      ),
                    ),
                  ),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.gold : Colors.transparent,
                        width: 2.5,
                        strokeAlign: BorderSide.strokeAlignOutside,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        preset['label']!,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Share Button ─────────────────────────────────────────────────────────

  Widget _buildShareButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: (_selectedSource == null || _isSharing) ? null : _shareImage,
        icon: _isSharing
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Icon(Icons.share_rounded),
        label: Text(
          _isSharing ? 'Preparing...' : 'Share Promotion',
          style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.gold,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.white10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionLabel(String text) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 18,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: GoogleFonts.outfit(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
