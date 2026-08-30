import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:vishal_jewelers/providers/preview_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vishal_jewelers/constants/app_colors.dart';
import 'package:vishal_jewelers/models/app_banner.dart';
import 'package:vishal_jewelers/services/firebase_service.dart';
import 'package:vishal_jewelers/utils/app_layout.dart';
import 'package:vishal_jewelers/screens/home/all_subcategories_screen.dart';
import 'package:vishal_jewelers/screens/product/product_detail_screen.dart';
import 'package:vishal_jewelers/widgets/common/shimmer_widget.dart';

class BannerCarousel extends StatefulWidget {
  const BannerCarousel({super.key});

  @override
  State<BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<BannerCarousel> {
  int _currentIndex = 0;
  final FirebaseService _firebaseService = FirebaseService();
  Stream<List<AppBanner>>? _bannerStream;
  bool? _lastIsPreviewMode;

  @override
  void initState() {
    super.initState();
    // Initialize stream early
    _bannerStream = _firebaseService.getActiveBanners();
  }

  void _updateStream(bool isPreview) {
    if (_lastIsPreviewMode == isPreview) return;
    _lastIsPreviewMode = isPreview;
    
    // In preview mode, we might want a different stream 
    // or we might need to combine with staging, but the StreamBuilder 
    // handles staging already. The core issue is the live stream.
    _bannerStream = _firebaseService.getActiveBanners();
  }

  Future<void> _onBannerTap(AppBanner banner) async {
    if (banner.actionValue == null || banner.actionValue!.isEmpty) return;

    try {
      switch (banner.actionType) {
        case 'category':
          final categoryId = banner.actionValue!;
          final category = await _firebaseService.getCategoryById(categoryId);
          if (category != null && mounted) {
            final subs = await _firebaseService.getSubcategoriesList(
              categoryId,
            );
            if (mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllSubcategoriesScreen(
                    category: category,
                    subcategories: subs,
                  ),
                ),
              );
            }
          }
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
    return Consumer<PreviewProvider>(
      builder: (context, preview, _) {
        _updateStream(preview.isPreviewMode);
        
        if (preview.isPreviewMode) {
          return StreamBuilder<QuerySnapshot>(
            stream: _firebaseService.getStagingChanges(),
            builder: (context, stagingSnapshot) {
              return StreamBuilder<List<AppBanner>>(
                stream: _bannerStream,
                builder: (context, liveSnapshot) {
                  if (liveSnapshot.connectionState == ConnectionState.waiting && !liveSnapshot.hasData) {
                    return _buildLoading();
                  }

                  final liveItems = liveSnapshot.data ?? [];
                  final stagedDocs = (stagingSnapshot.data?.docs ?? [])
                      .where((doc) =>
                          (doc.data() as Map<String, dynamic>)['collection_name'] ==
                          FirebaseService.bannersCollection)
                      .toList();

                  final banners = preview.mergeWithStaging<AppBanner>(
                    liveItems,
                    stagedDocs,
                    (data, id) => AppBanner.fromJson(data, id),
                    (item) => item.id,
                  );

                  // Filter for active ones in preview too, if not already filtered
                  final activeBanners = banners.where((b) => b.isActive).toList();

                  if (activeBanners.isEmpty) return const SizedBox.shrink();
                  return _buildCarousel(activeBanners);
                },
              );
            },
          );
        }

        return StreamBuilder<List<AppBanner>>(
          stream: _bannerStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return _buildLoading();
            }

            if (snapshot.hasError) {
              return Container(
                height: AppLayout.of(context).bannerHeight,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text(
                      snapshot.error.toString(),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              );
            }

            final banners = snapshot.data ?? [];
            if (banners.isEmpty) return const SizedBox.shrink();

            return _buildCarousel(banners);
          },
        );
      },
    );
  }

  Widget _buildLoading() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ShimmerWidget.rectangular(
        height: AppLayout.of(context).bannerHeight,
      ),
    );
  }

  Widget _buildCarousel(List<AppBanner> banners) {
    return RepaintBoundary(
      child: Column(
        children: [
          CarouselSlider(
            options: CarouselOptions(
              height: AppLayout.of(context).bannerHeight,
              autoPlay: banners.length > 1,
              autoPlayInterval: const Duration(seconds: 5),
              autoPlayAnimationDuration: const Duration(milliseconds: 1000),
              autoPlayCurve: Curves.easeInOutCubic,
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
                      child: _buildBannerContent(banner),
                    ),
                  );
                },
              );
            }).toList(),
          ),
          if (banners.length > 1) ...[
            const SizedBox(height: 16),
            AnimatedSmoothIndicator(
              activeIndex: _currentIndex,
              count: banners.length,
              effect: WormEffect(
                dotColor: AppColors.lightGrey,
                activeDotColor: AppColors.gold,
                dotHeight: 8,
                dotWidth: 8,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBannerContent(AppBanner banner) {
    switch (banner.templateType) {
      case 'theme2':
        return _buildTheme2(banner);
      case 'full_image':
        return _buildFullImage(banner);
      case 'blank':
        return _buildBlank(banner);
      case 'theme1':
      default:
        return _buildTheme1(banner);
    }
  }

  Widget _buildTheme1(AppBanner banner) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: CachedNetworkImageProvider(banner.imageUrl),
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
          if (banner.title != null || banner.subtitle != null)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
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
                    style: TextStyle(
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
                      color: AppColors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                Text(
                  banner.termsAndConditions,
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
      ),
    );
  }

  Widget _buildTheme2(AppBanner banner) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (banner.title != null)
                    Text(
                      banner.title!,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (banner.subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      banner.subtitle!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    banner.termsAndConditions,
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
          Expanded(
            flex: 2,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: CachedNetworkImage(
                imageUrl: banner.imageUrl,
                fit: BoxFit.cover,
                height: double.infinity,
                placeholder: (context, url) =>
                    Container(color: AppColors.surface),
                errorWidget: (context, url, error) => const Icon(Icons.error),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullImage(AppBanner banner) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: CachedNetworkImageProvider(banner.imageUrl),
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
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            banner.termsAndConditions,
            style: TextStyle(
              fontSize: 7,
              color: AppColors.white.withValues(alpha: 0.6),
              fontStyle: FontStyle.italic,
              backgroundColor: Colors.black26,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBlank(AppBanner banner) {
    // Blank custom allows full design control from the image itself
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        image: DecorationImage(
          image: CachedNetworkImageProvider(banner.imageUrl),
          fit: BoxFit.contain, // Contain rather than cover to prevent cropping
        ),
      ),
      child: Align(
        alignment: Alignment.bottomRight,
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Text(
            banner.termsAndConditions,
            style: TextStyle(
              fontSize: 6,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ),
    );
  }
}
