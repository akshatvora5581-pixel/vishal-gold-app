import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/widgets/common/shimmer_widget.dart';

class CategoryCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final VoidCallback onTap;

  const CategoryCard({
    super.key,
    required this.name,
    required this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
                child: _buildImage(),
              ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: const EdgeInsets.all(8),
                alignment: Alignment.center,
                child: Text(
                  name,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    // Empty URL → placeholder icon
    if (imagePath.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.category_outlined, color: AppColors.textSecondary),
        ),
      );
    }

    // Local asset path
    if (imagePath.toLowerCase().contains('assets/')) {
      return Image.asset(
        imagePath,
        fit: BoxFit.cover,
        width: double.infinity,
        cacheWidth: 300,
        errorBuilder: (_, _, _) => _brokenImagePlaceholder(),
      );
    }

    // Network URL (Firestore image_url) — matches View All screen
    return CachedNetworkImage(
      imageUrl: imagePath,
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: 300,
      memCacheHeight: 300,
      placeholder: (context, url) =>
          ShimmerWidget.rectangular(height: double.infinity),
      errorWidget: (_, _, _) => _brokenImagePlaceholder(),
    );
  }

  Widget _brokenImagePlaceholder() {
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(Icons.broken_image, color: AppColors.grey),
      ),
    );
  }
}
