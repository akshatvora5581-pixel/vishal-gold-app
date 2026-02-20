import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/providers/wishlist_provider.dart';
import 'package:vishal_gold/screens/cart/cart_screen.dart';
import 'package:vishal_gold/screens/product/full_screen_photo_viewer.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;

  /// 0.0 → details visible (image = 55% height)
  /// 1.0 → image fully expanded (full-screen), details hidden
  late AnimationController _controller;

  late PageController _imagePageController;

  // Cached sizes (set in build)
  double _screenHeight = 0;
  double _dragAnchorY = 0;

  void _incrementQuantity() => setState(() => _quantity++);
  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _imagePageController = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  // ── Gesture handlers ────────────────────────────────────────────────────────

  void _onDragStart(DragStartDetails d) {
    _controller.stop();
    _dragAnchorY = d.globalPosition.dy;
  }

  void _onDragUpdate(DragUpdateDetails d) {
    final delta = d.globalPosition.dy - _dragAnchorY;
    _dragAnchorY = d.globalPosition.dy;
    // Map screen-pixels → controller value (downward drag = positive = expand)
    _controller.value = (_controller.value + delta / (_screenHeight * 0.6))
        .clamp(0.0, 1.0);
  }

  void _onDragEnd(DragEndDetails d) {
    const threshold = 0.35;
    final velocity = d.primaryVelocity ?? 0; // positive = downward

    if (velocity > 400 || _controller.value > threshold) {
      // Snap to expanded image
      _controller.animateTo(
        1.0,
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOut,
      );
    } else if (velocity < -400 || _controller.value < (1.0 - threshold)) {
      // Snap to details visible — use a spring-like curve
      _controller.animateTo(
        0.0,
        duration: const Duration(milliseconds: 500),
        curve: _ElasticOutClamped(),
      );
    } else {
      // Snap back to whichever state is closer
      if (_controller.value >= 0.5) {
        _controller.animateTo(
          1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      } else {
        _controller.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    }
  }

  void _showDetails() {
    _controller.animateTo(
      0.0,
      duration: const Duration(milliseconds: 480),
      curve: _ElasticOutClamped(),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    _screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        // Use onPanXxx so we are not competing with PageView's horizontal scroll
        onPanStart: _onDragStart,
        onPanUpdate: (d) {
          // Only respond to predominantly vertical movement
          final dy = d.delta.dy.abs();
          final dx = d.delta.dx.abs();
          if (dy > dx) {
            _onDragUpdate(
              DragUpdateDetails(
                globalPosition: d.globalPosition,
                delta: d.delta,
                sourceTimeStamp: d.sourceTimeStamp,
              ),
            );
          }
        },
        onPanEnd: (d) {
          _onDragEnd(
            DragEndDetails(primaryVelocity: d.velocity.pixelsPerSecond.dy),
          );
        },
        behavior: HitTestBehavior.translucent,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value; // 0 = details, 1 = full image

            // Image height: 55% → 100%
            final imageHeight = _screenHeight * (0.55 + 0.45 * t);
            // Panel offset: 0 → panelHeight (slides off screen)
            final panelHeight = _screenHeight * 0.55;
            final panelOffset = panelHeight * t;
            // Details opacity: 1 → 0 (fades in first half of drag)
            final detailsOpacity = (1.0 - t * 2.0).clamp(0.0, 1.0);
            // Peek strip opacity: fades in in second half of drag
            final peekOpacity = ((t - 0.6) / 0.4).clamp(0.0, 1.0);

            return Stack(
              clipBehavior: Clip.none,
              children: [
                // ── Product Image ──────────────────────────────────────────────
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: widget.product.imageUrls.isNotEmpty
                      ? PageView.builder(
                          controller: _imagePageController,
                          physics: t < 0.05
                              ? const BouncingScrollPhysics()
                              : const NeverScrollableScrollPhysics(),
                          itemCount: widget.product.imageUrls.length,
                          itemBuilder: (context, index) {
                            final url = widget.product.imageUrls[index];
                            final imageWidget =
                                url.toLowerCase().contains('assets/')
                                ? Image.asset(
                                    url.trim(),
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: url,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    placeholder: (context, url) => Container(
                                      color: AppColors.black,
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          color: AppColors.gold,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, err) =>
                                        Container(color: AppColors.black),
                                  );

                            // Tap on image → open full-screen viewer
                            return GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  PageRouteBuilder(
                                    pageBuilder:
                                        (
                                          context,
                                          animation,
                                          secondaryAnimation,
                                        ) => FullScreenPhotoViewer(
                                          imageUrls: widget.product.imageUrls,
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

                // ── Gradient at bottom of image ────────────────────────────────
                if (t > 0.3)
                  Positioned(
                    top: imageHeight - 120,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            // ignore: deprecated_member_use
                            AppColors.background.withOpacity(0.6),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ── Details Panel ──────────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, panelOffset),
                    child: Opacity(
                      opacity: detailsOpacity,
                      child: IgnorePointer(
                        ignoring: detailsOpacity < 0.05,
                        child: Container(
                          height: panelHeight,
                          padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(40),
                              topRight: Radius.circular(40),
                            ),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 30,
                                offset: const Offset(0, -10),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Drag Handle
                              Center(
                                child: Container(
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    // ignore: deprecated_member_use
                                    color: AppColors.grey.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),

                              // Title & Purity badge
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      widget.product.tagNumber,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      // ignore: deprecated_member_use
                                      color: AppColors.gold.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: AppColors.gold,
                                        width: 1,
                                      ),
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

                              const SizedBox(height: 8),
                              Text(
                                widget.product.categoryDisplay.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 2.0,
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Specs row
                              Row(
                                children: [
                                  _buildSpecItem(
                                    'Gross Weight',
                                    '${widget.product.grossWeight}g',
                                  ),
                                  _buildSpecItem(
                                    'Net Weight',
                                    '${widget.product.netWeight}g',
                                  ),
                                  _buildSpecItem(
                                    'Purity',
                                    '${widget.product.purity}%',
                                  ),
                                ],
                              ),

                              const Spacer(),
                              _buildBottomActions(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Peek Strip (tap to bring details back) ─────────────────────
                if (peekOpacity > 0)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Opacity(
                      opacity: peekOpacity,
                      child: GestureDetector(
                        onTap: _showDetails,
                        child: Container(
                          height: 60,
                          decoration: BoxDecoration(
                            // ignore: deprecated_member_use
                            color: AppColors.surface.withOpacity(0.92),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                            boxShadow: [
                              BoxShadow(
                                // ignore: deprecated_member_use
                                color: AppColors.gold.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, -4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  // ignore: deprecated_member_use
                                  color: AppColors.gold.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '⬆  SWIPE UP FOR DETAILS',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  // ignore: deprecated_member_use
                                  color: AppColors.gold.withOpacity(0.85),
                                  letterSpacing: 1.4,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                // ── Back Button & Wishlist ─────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 10,
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
            );
          },
        ),
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
            // ignore: deprecated_member_use
            color: AppColors.white.withOpacity(0.90),
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
            border: Border.all(
              // ignore: deprecated_member_use
              color: AppColors.grey.withOpacity(0.15),
            ),
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
        const SizedBox(width: 16),
        // Add to Cart
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
}

/// A custom curve that applies `elasticOut` but clamps the output to [0, 1]
/// so the AnimationController never goes out of bounds.
class _ElasticOutClamped extends Curve {
  @override
  double transformInternal(double t) {
    return Curves.elasticOut.transform(t).clamp(0.0, 1.0);
  }
}
