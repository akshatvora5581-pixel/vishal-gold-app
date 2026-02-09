import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/providers/wishlist_provider.dart';
import 'package:vishal_gold/screens/product/product_detail_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.cardBorder, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image Area
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    child: _buildProductImage(),
                  ),
                  // Subtle Gradient Overlay
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.3),
                          ],
                          stops: const [0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Wishlist Button (Minimal)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Consumer<WishlistProvider>(
                      builder: (context, wishlistProvider, child) {
                        final isInWishlist = wishlistProvider.isInWishlist(
                          product.id,
                        );
                        return GestureDetector(
                          onTap: () => wishlistProvider.toggleWishlist(product),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.background.withOpacity(0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isInWishlist
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: isInWishlist
                                  ? AppColors.errorRed
                                  : AppColors.white,
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            // Details Area
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.tagNumber,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: AppColors.gold,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.grossWeight}g  •  ${product.purity}K',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: AppColors.textSecondary,
                                fontSize: 10,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImage() {
    if (product.imageUrls.isEmpty) {
      return Container(
        color: AppColors.background,
        child: const Center(
          child: Icon(Icons.diamond_outlined, color: AppColors.textTertiary),
        ),
      );
    }

    final imageUrl = product.imageUrls.first;
    if (imageUrl.toLowerCase().contains('assets/')) {
      return Image.asset(
        imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (_, __, ___) => Container(
          color: AppColors.background,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: imageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        placeholder: (_, __) => Container(
          color: AppColors.background,
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.gold.withOpacity(0.5),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: AppColors.background,
          child: const Center(
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.textTertiary,
            ),
          ),
        ),
      );
    }
  }
}
