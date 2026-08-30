import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/providers/wishlist_provider.dart';
import 'package:vishal_jewelers/utils/app_layout.dart';
import 'package:vishal_jewelers/widgets/product/product_card.dart';

class FavouriteProductsScreen extends StatelessWidget {
  const FavouriteProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        title: Text(
          'Favourite Products',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.gold),
      ),
      body: Consumer<WishlistProvider>(
        builder: (context, wishlistProvider, child) {
          final items = wishlistProvider.items.where((item) => item.product != null).toList();

          if (wishlistProvider.isLoading && items.isEmpty) {
            return Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.gold),
              ),
            );
          }

          if (items.isEmpty) {
            return Center(
              child: Text(
                'No favourite products yet.',
                style: GoogleFonts.outfit(
                  color: AppColors.grey,
                  fontSize: 16,
                ),
              ),
            );
          }

          final layout = AppLayout.of(context);

          return AnimationLimiter(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              physics: const BouncingScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: layout.productGridColumns,
                childAspectRatio: layout.productCardAspectRatio,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final product = items[index].product!;
                return AnimationConfiguration.staggeredGrid(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  columnCount: layout.productGridColumns,
                  child: ScaleAnimation(
                    child: FadeInAnimation(
                      child: RepaintBoundary(
                        child: ProductCard(product: product),
                      ),
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
