import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/app_banner.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:vishal_gold/screens/home/all_subcategories_screen.dart';
import 'package:vishal_gold/screens/product/product_detail_screen.dart';
import 'package:vishal_gold/config/category_data.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();

  Future<void> _onBannerTap(AppBanner banner) async {
    if (banner.actionValue == null || banner.actionValue!.isEmpty) return;

    try {
      switch (banner.actionType) {
        case 'category':
          final category = banner.actionValue!;
          final subs = CategoryData.getSubcategories(category);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AllSubcategoriesScreen(
                title: category.replaceAll('_', ' ').toUpperCase(),
                category: category,
                subcategories: subs,
              ),
            ),
          );
          break;
        case 'subcategory':
          // We don't have a direct subcategory screen yet, usually navigating to product listing with filters
          break;
        case 'product':
          final product = await _firebaseService.getProductById(
            banner.actionValue!,
          );
          if (product != null && mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProductDetailScreen(product: product),
              ),
            );
          }
          break;
        case 'external':
          final url = Uri.parse(banner.actionValue!);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error navigating from banner: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppBanner>>(
      stream: _firebaseService.getActiveBanners(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 180,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            ),
          );
        }

        final banners = snapshot.data ?? [];
        if (banners.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            CarouselSlider(
              options: CarouselOptions(
                height: 180.0,
                autoPlay: true,
                autoPlayInterval: const Duration(seconds: 4),
                enlargeCenterPage: false,
                viewportFraction: 1.0,
                onPageChanged: (index, reason) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
              ),
              items: banners.map((banner) {
                return Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      onTap: () => _onBannerTap(banner),
                      child: Container(
                        width: MediaQuery.of(context).size.width,
                        margin: const EdgeInsets.symmetric(horizontal: 16.0),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          image: DecorationImage(
                            image: NetworkImage(banner.imageUrl),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Overlay for readability if title exists
                            if (banner.title != null)
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      Colors.black.withValues(alpha: 0.6),
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
                                  if (banner.title != null)
                                    Text(
                                      banner.title!,
                                      style: const TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  if (banner.subtitle != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      banner.subtitle!,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.white.withValues(
                                          alpha: 0.9,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: banners.length,
              effect: const WormEffect(
                dotColor: AppColors.lightGrey,
                activeDotColor: AppColors.gold,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
          ],
        );
      },
    );
  }
}
