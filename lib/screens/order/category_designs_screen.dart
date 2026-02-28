import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/widgets/common/custom_app_bar.dart';

/// Displays customer-uploaded sample designs for a given [categoryName],
/// streamed in real-time from Firestore's `sample_orders` collection.
class CategoryDesignsScreen extends StatelessWidget {
  final String categoryName;

  const CategoryDesignsScreen({super.key, required this.categoryName});

  @override
  Widget build(BuildContext context) {
    final Stream<QuerySnapshot> stream = FirebaseFirestore.instance
        .collection('sample_orders')
        .where('category', isEqualTo: categoryName)
        .snapshots();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: '${categoryName.toUpperCase()} DESIGNS'),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snapshot) {
          // ── Loading ─────────────────────────────────────────────────────────
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          // ── Error ────────────────────────────────────────────────────────────
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: AppColors.errorRed,
                    size: 48,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Something went wrong.\nPlease try again.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Empty ────────────────────────────────────────────────────────────
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.grey.withValues(alpha: 0.35),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No designs uploaded yet',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Designs for "$categoryName" will appear here.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          // ── Grid ─────────────────────────────────────────────────────────────
          // Flatten all imageUrls from all matched orders into a single list
          final allImages = <String>[];
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final urls = data['imageUrls'];
            if (urls is List) {
              for (final url in urls) {
                if (url is String && url.isNotEmpty) {
                  allImages.add(url);
                }
              }
            } else if (urls is String && urls.isNotEmpty) {
              // Fallback: handle if stored as a single string
              allImages.add(urls);
            }
          }

          if (allImages.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.image_not_supported_outlined,
                    color: AppColors.grey.withValues(alpha: 0.35),
                    size: 64,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No designs uploaded yet',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.textSecondary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Designs for "$categoryName" will appear here.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.82,
              ),
              itemCount: allImages.length,
              itemBuilder: (context, index) {
                final imageUrl = allImages[index];

                return _DesignCard(
                  imageUrl: imageUrl,
                  index: index,
                  onTap: () => _showFullImage(context, imageUrl, index),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showFullImage(BuildContext context, String imageUrl, int index) {
    if (imageUrl.isEmpty) return;
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black87,
        pageBuilder: (_, __, ___) =>
            _FullImageViewer(imageUrl: imageUrl, heroTag: 'design_$index'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Design Card
// ─────────────────────────────────────────────────────────────────────────────

class _DesignCard extends StatelessWidget {
  final String imageUrl;
  final int index;
  final VoidCallback onTap;

  const _DesignCard({
    required this.imageUrl,
    required this.index,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Hero(
        tag: 'design_$index',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: imageUrl.isEmpty
                ? const _PlaceholderTile()
                : Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    // ── Loading shimmer ───────────────────────────────────────
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return _LoadingShimmer(
                        progress: progress.expectedTotalBytes != null
                            ? progress.cumulativeBytesLoaded /
                                  progress.expectedTotalBytes!
                            : null,
                      );
                    },
                    // ── Error fallback ────────────────────────────────────────
                    errorBuilder: (_, __, ___) => const _PlaceholderTile(),
                  ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading Shimmer
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingShimmer extends StatefulWidget {
  final double? progress;
  const _LoadingShimmer({this.progress});

  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}

class _LoadingShimmerState extends State<_LoadingShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = Tween<double>(
      begin: 0.4,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        color: AppColors.surface,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Opacity(
                opacity: _anim.value,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.gold,
                  size: 36,
                ),
              ),
              if (widget.progress != null) ...[
                const SizedBox(height: 10),
                SizedBox(
                  width: 60,
                  child: LinearProgressIndicator(
                    value: widget.progress,
                    backgroundColor: AppColors.cardBorder,
                    valueColor: const AlwaysStoppedAnimation(AppColors.gold),
                    minHeight: 2,
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error / Placeholder Tile
// ─────────────────────────────────────────────────────────────────────────────

class _PlaceholderTile extends StatelessWidget {
  const _PlaceholderTile();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.broken_image_outlined,
              color: AppColors.grey.withValues(alpha: 0.4),
              size: 32,
            ),
            const SizedBox(height: 6),
            Text(
              'Image unavailable',
              style: GoogleFonts.outfit(
                color: AppColors.textTertiary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Full-screen Image Viewer (Hero animated)
// ─────────────────────────────────────────────────────────────────────────────

class _FullImageViewer extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullImageViewer({required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Stack(
            children: [
              // ── Image ──────────────────────────────────────────────────────
              Center(
                child: Hero(
                  tag: heroTag,
                  child: InteractiveViewer(
                    minScale: 0.8,
                    maxScale: 4.0,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.gold,
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => const Center(
                        child: Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.grey,
                          size: 64,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Close button ──────────────────────────────────────────────
              Positioned(
                top: 12,
                right: 12,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.55),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.white,
                      size: 22,
                    ),
                  ),
                ),
              ),

              // ── Hint label ────────────────────────────────────────────────
              Positioned(
                bottom: 20,
                left: 0,
                right: 0,
                child: Text(
                  'Tap anywhere to close  •  Pinch to zoom',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
