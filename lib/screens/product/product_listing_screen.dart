import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/product_provider.dart';
import 'package:vishal_gold/widgets/product/product_card.dart';

class ProductListingScreen extends StatefulWidget {
  final String? category;
  final String? subcategory;

  const ProductListingScreen({super.key, this.category, this.subcategory});

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final productProvider = context.read<ProductProvider>();
      if (widget.category != null) {
        productProvider.loadProductsByCategory(
          widget.category!,
          subcategory: widget.subcategory,
        );
      } else {
        productProvider.loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final title =
        widget.subcategory ??
        widget.category?.replaceAll('_', ' ').toUpperCase() ??
        'ALL DESIGNS';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 120.0,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
              title: Text(
                title.toUpperCase(),
                style: GoogleFonts.playfairDisplay(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  fontSize: 18, // Adjusted for collapsed state
                  letterSpacing: 1.2,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.surface, AppColors.background],
                  ),
                ),
              ),
            ),
            leading: IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.white,
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_list, color: AppColors.gold),
                onPressed: () {
                  // TODO: Implement Filter
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, color: AppColors.white),
                onPressed: () {
                  // TODO: Implement Search
                },
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: CircularProgressIndicator(color: AppColors.gold),
                    ),
                  );
                }

                final products = productProvider.products;

                if (products.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.diamond_outlined,
                            size: 64,
                            color: AppColors.grey.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No designs found',
                            style: GoogleFonts.outfit(
                              color: AppColors.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return AnimationLimiter(
                  child: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                    delegate: SliverChildBuilderDelegate((
                      BuildContext context,
                      int index,
                    ) {
                      return AnimationConfiguration.staggeredGrid(
                        position: index,
                        duration: const Duration(milliseconds: 500),
                        columnCount: 2,
                        child: ScaleAnimation(
                          child: FadeInAnimation(
                            child: ProductCard(product: products[index]),
                          ),
                        ),
                      );
                    }, childCount: products.length),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
