import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/product/product_listing_screen.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentIndex = 0;

  final List<Map<String, String>> _banners = [
    {
      'title': '84 ORNAMENTS',
      'category': '84_ornaments',
      'description': '20K Gold Jewelry',
    },
    {
      'title': '92 ORNAMENTS',
      'category': '92_ornaments',
      'description': '22K Gold Jewelry',
    },
    {
      'title': '92 CHAINS',
      'category': '92_chains',
      'description': 'Premium Gold Chains',
    },
  ];

  @override
  Widget build(BuildContext context) {
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
          items: _banners.map((banner) {
            return Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProductListingScreen(category: banner['category']!),
                      ),
                    );
                  },
                  child: Container(
                    width: MediaQuery.of(context).size.width,
                    margin: const EdgeInsets.symmetric(horizontal: 0.0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.oliveGreen,
                          // ignore: deprecated_member_use
                          AppColors.oliveGreen.withOpacity(0.7),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          // ignore: deprecated_member_use
                          color: AppColors.grey.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        // Decorative elements
                        Positioned(
                          top: -20,
                          right: -20,
                          child: Icon(
                            Icons.diamond,
                            size: 120,
                            // ignore: deprecated_member_use
                            color: AppColors.softGold.withOpacity(0.2),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                banner['title']!,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.white,
                                  letterSpacing: 1.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                banner['description']!,
                                style: TextStyle(
                                  fontSize: 13,
                                  // ignore: deprecated_member_use
                                  color: AppColors.white.withOpacity(0.9),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: AppColors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: AppColors.white,
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'Browse Collection',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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

        // Page Indicator
        AnimatedSmoothIndicator(
          activeIndex: _currentIndex,
          count: _banners.length,
          effect: const WormEffect(
            dotColor: AppColors.lightGrey,
            activeDotColor: AppColors.oliveGreen,
            dotHeight: 8,
            dotWidth: 8,
          ),
        ),
      ],
    );
  }
}
