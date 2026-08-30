import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/models/category.dart' as app_models;
import 'package:vishal_jewelers/models/subcategory.dart';
import 'package:vishal_jewelers/utils/app_layout.dart';
import 'package:vishal_jewelers/widgets/common/custom_app_bar.dart';
import 'package:vishal_jewelers/widgets/common/shimmer_widget.dart';
import 'package:vishal_jewelers/screens/product/product_listing_screen.dart';

class AllSubcategoriesScreen extends StatelessWidget {
  final app_models.Category category;
  final List<Subcategory> subcategories;

  const AllSubcategoriesScreen({
    super.key,
    required this.category,
    required this.subcategories,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AppLayout.of(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: category.name.toUpperCase()),
      body: GridView.builder(
        padding: EdgeInsets.all(layout.horizontalPadding),
        physics: const BouncingScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: layout.subcategoryGridColumns,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.85,
        ),
        itemCount: subcategories.length,
        itemBuilder: (context, index) {
          final subcategory = subcategories[index];
          return RepaintBoundary(
            child: _SubcategoryCard(
              name: subcategory.name,
              imageUrl: subcategory.imageUrl,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductListingScreen(
                      category: category.id,
                      subcategory: subcategory.id, // Pass ID for querying
                      subcategoryName: subcategory.name, // Pass Name for display
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _SubcategoryCard extends StatelessWidget {
  final String name;
  final String imageUrl;
  final VoidCallback onTap;

  const _SubcategoryCard({
    required this.name,
    required this.imageUrl,
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
    if (imageUrl.isEmpty) {
      return Container(
        color: AppColors.background,
        child: Center(
          child: Icon(Icons.category_outlined, color: AppColors.textTertiary),
        ),
      );
    }

    if (imageUrl.toLowerCase().contains('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        cacheWidth: 300,
        errorBuilder: (_, _, _) => Container(
          color: AppColors.background,
          child: Center(
            child: Icon(Icons.broken_image, color: AppColors.grey),
          ),
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      memCacheWidth: 300,
      memCacheHeight: 300,
      placeholder: (context, url) =>
          ShimmerWidget.rectangular(height: double.infinity),
      errorWidget: (_, _, _) => Container(
        color: AppColors.background,
        child: Center(
          child: Icon(Icons.broken_image, color: AppColors.grey),
        ),
      ),
    );
  }
}
