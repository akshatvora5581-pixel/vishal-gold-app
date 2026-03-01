import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/models/category.dart' as app_category;
import 'package:vishal_gold/models/market_settings.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/providers/wishlist_provider.dart';
import 'package:vishal_gold/screens/cart/cart_screen.dart';
import 'package:vishal_gold/screens/product/full_screen_photo_viewer.dart';
import 'package:vishal_gold/services/firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:vishal_gold/widgets/common/shimmer_widget.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;
  int _currentImageIndex = 0;
  static const int _maxQuantity = 99; // BUG-004: bounded quantity

  late PageController _imagePageController;

  void _incrementQuantity() {
    if (_quantity < _maxQuantity) setState(() => _quantity++);
  }

  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  void initState() {
    super.initState();
    _imagePageController = PageController();
    _imagePageController.addListener(() {
      final page = _imagePageController.page?.round() ?? 0;
      if (page != _currentImageIndex) {
        setState(() => _currentImageIndex = page);
      }
    });
  }

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: AppColors.surface,
      // ── Sticky Action Bar ──────────────────────────────────────────────────
      bottomNavigationBar: _buildStickyActionBar(context),
      body: Stack(
        children: [
          // ── Main Scrollable Content ──────────────────────────────────────
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Image gallery block
              SliverToBoxAdapter(child: _buildImageGallery()),

              // Details block
              SliverToBoxAdapter(child: _buildDetailsSection()),
            ],
          ),

          // ── Back Button & Wishlist (floating overlay) ─────────────────
          Positioned(
            top: topPad + 10,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildCircularButton(
                  icon: Icons.arrow_back_ios_new,
                  onPressed: () => Navigator.pop(context),
                ),
                Consumer<WishlistProvider>(
                  builder: (context, wishlistProvider, child) {
                    final isInWishlist = wishlistProvider.isInWishlist(
                      widget.product.id,
                    );
                    return _buildCircularButton(
                      icon: isInWishlist
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: isInWishlist
                          ? AppColors.errorRed
                          : AppColors.black,
                      onPressed: () =>
                          wishlistProvider.toggleWishlist(widget.product),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Image Gallery ────────────────────────────────────────────────────────────

  Widget _buildImageGallery() {
    final imageUrls = widget.product.imageUrls;

    return Stack(
      children: [
        // Square image frame — BoxFit.contain keeps entire image visible
        AspectRatio(
          aspectRatio: 1.0,
          child: imageUrls.isNotEmpty
              ? PageView.builder(
                  controller: _imagePageController,
                  itemCount: imageUrls.length,
                  itemBuilder: (context, index) {
                    final url = imageUrls[index];
                    final imageWidget = url.toLowerCase().contains('assets/')
                        ? Image.asset(
                            url.trim(),
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                            width: double.infinity,
                            height: double.infinity,
                            placeholder: (context, url) =>
                                const ShimmerWidget.rectangular(
                                  height: double.infinity,
                                ),
                            errorWidget: (context, url, err) =>
                                Container(color: AppColors.black),
                          );

                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder:
                                (context, animation, secondaryAnimation) =>
                                    FullScreenPhotoViewer(
                                      imageUrls: imageUrls,
                                      initialIndex: index,
                                    ),
                            transitionsBuilder:
                                (
                                  context,
                                  animation,
                                  secondaryAnimation,
                                  child,
                                ) {
                                  return FadeTransition(
                                    opacity: animation,
                                    child: child,
                                  );
                                },
                            transitionDuration: const Duration(
                              milliseconds: 300,
                            ),
                          ),
                        );
                      },
                      child: imageWidget,
                    );
                  },
                )
              : Container(color: AppColors.black),
        ),

        // ── Nav Arrows (only with multiple images) ───────────────────────
        if (imageUrls.length > 1) ..._buildGalleryArrows(),

        // ── Pagination Dots ──────────────────────────────────────────────
        if (imageUrls.length > 1)
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                imageUrls.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeInOut,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentImageIndex == i ? 18 : 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: _currentImageIndex == i
                        ? AppColors.gold
                        : AppColors.white.withValues(alpha: 0.50),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ── Details Section ──────────────────────────────────────────────────────────

  Widget _buildDetailsSection() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title & Purity badge ─────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  widget.product.tagNumber,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.gold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.gold, width: 1),
                ),
                child: Text(
                  widget.product.purityDisplay,
                  style: GoogleFonts.outfit(
                    color: AppColors.gold,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 6),
          Text(
            widget.product.categoryDisplay.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: AppColors.textSecondary,
              letterSpacing: 2.0,
            ),
          ),

          const SizedBox(height: 28),

          // ── Spec chips ───────────────────────────────────────────────
          Row(
            children: [
              _buildSpecItem('Gross Weight', '${widget.product.grossWeight}g'),
              _buildSpecItem('Net Weight', '${widget.product.netWeight}g'),
              _buildSpecItem('Purity', '${widget.product.purity}%'),
            ],
          ),

          const SizedBox(height: 28),

          // ── Estimated Price ──────────────────────────────────────────
          _buildEstimatedPriceSection(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStickyActionBar(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad > 0 ? bottomPad : 16),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.97),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: _buildBottomActions(context),
    );
  }

  // ── Gallery Navigation Helpers ───────────────────────────────────────────────

  void _goToImage(int index) {
    final count = widget.product.imageUrls.length;
    final target = ((index % count) + count) % count;
    setState(() => _currentImageIndex = target);
    _imagePageController.animateToPage(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  List<Widget> _buildGalleryArrows() {
    return [
      // Left arrow — vertically centred inside the AspectRatio block
      Positioned(
        left: 14,
        top: 0,
        bottom: 0,
        child: Center(
          child: _buildNavArrow(
            icon: Icons.chevron_left_rounded,
            onTap: () => _goToImage(_currentImageIndex - 1),
          ),
        ),
      ),
      // Right arrow
      Positioned(
        right: 14,
        top: 0,
        bottom: 0,
        child: Center(
          child: _buildNavArrow(
            icon: Icons.chevron_right_rounded,
            onTap: () => _goToImage(_currentImageIndex + 1),
          ),
        ),
      ),
    ];
  }

  Widget _buildNavArrow({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.38),
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.25),
            width: 1,
          ),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  // ── Helper Widgets ───────────────────────────────────────────────────────────

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = AppColors.black,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.white.withValues(alpha: 0.90),
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _buildSpecItem(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              color: AppColors.textSecondary,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final isInCart = cartProvider.isInCart(widget.product.id);

    return Row(
      children: [
        // Quantity Selector
        Container(
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.15)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: _decrementQuantity,
                icon: const Icon(Icons.remove, color: AppColors.gold),
              ),
              Text(
                '$_quantity',
                style: GoogleFonts.outfit(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: _incrementQuantity,
                icon: const Icon(Icons.add, color: AppColors.gold),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // WhatsApp Query button
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF25D366).withValues(alpha: 0.3),
            ),
          ),
          child: IconButton(
            onPressed: () => _launchWhatsApp(context),
            icon: const FaIcon(
              FontAwesomeIcons.whatsapp,
              color: Color(0xFF25D366),
            ),
            tooltip: 'Query on WhatsApp',
          ),
        ),
        const SizedBox(width: 12),
        // Add to Cart / View Cart
        Expanded(
          child: SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: () async {
                if (isInCart) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CartScreen()),
                  );
                } else {
                  for (int i = 0; i < _quantity; i++) {
                    await cartProvider.addToCart(widget.product);
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to Cart'),
                        backgroundColor: AppColors.gold,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(
                isInCart ? 'VIEW CART' : 'ADD TO CART',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _launchWhatsApp(BuildContext context) async {
    final firebaseService = FirebaseService();
    final support = await firebaseService.getSupportContact();
    final number = support['whatsapp'];

    if (number == null || number.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Support contact not available')),
        );
      }
      return;
    }

    final message =
        'Hi, I am interested in this product:\n'
        'Tag: ${widget.product.tagNumber}\n'
        'Category: ${widget.product.categoryDisplay}\n'
        'Gross Weight: ${widget.product.grossWeight}g\n'
        'Purity: ${widget.product.purity}%';

    final whatsappUrl = Uri.parse(
      'whatsapp://send?phone=$number&text=${Uri.encodeComponent(message)}',
    );

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        final webUrl = Uri.parse(
          'https://wa.me/$number?text=${Uri.encodeComponent(message)}',
        );
        await launchUrl(webUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch WhatsApp: $e')),
        );
      }
    }
  }

  Widget _buildEstimatedPriceSection() {
    final firebaseService = FirebaseService();

    return StreamBuilder<MarketSettings?>(
      stream: firebaseService.getMarketSettings(),
      builder: (context, marketSnapshot) {
        if (!marketSnapshot.hasData || marketSnapshot.data == null) {
          return const SizedBox.shrink();
        }

        final settings = marketSnapshot.data!;

        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection(FirebaseService.categoriesCollection)
              .doc(widget.product.category)
              .get(),
          builder: (context, catSnapshot) {
            if (!catSnapshot.hasData || !catSnapshot.data!.exists) {
              return const SizedBox.shrink();
            }

            final categoryData =
                catSnapshot.data!.data() as Map<String, dynamic>;
            final category = app_category.Category.fromJson(
              categoryData,
              catSnapshot.data!.id,
            );

            double baseRate = settings.goldRate24K;
            if (widget.product.purityDisplay.contains('22K') ||
                widget.product.purity == 92) {
              baseRate = settings.goldRate22K;
            } else if (widget.product.purityDisplay.contains('18K')) {
              baseRate = settings.goldRate18K;
            }

            final estimatedPrice = widget.product.calculateEstimatedPrice(
              baseRatePerGram: baseRate,
              makingChargePerGram: category.makingChargePerGram,
              makingChargeFlat: category.makingChargeFlat,
            );

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.gold.withValues(alpha: 0.30),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Today's Estimated Price",
                        style: GoogleFonts.outfit(
                          color: AppColors.gold,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Icon(
                        Icons.info_outline,
                        color: AppColors.gold,
                        size: 16,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '₹ ${estimatedPrice.toStringAsFixed(0)}*',
                    style: GoogleFonts.outfit(
                      color: AppColors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '*Includes making charges. Final price may vary at the time of purchase.',
                    style: GoogleFonts.outfit(
                      color: AppColors.textSecondary,
                      fontSize: 10,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
