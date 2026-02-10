import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/models/product.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/providers/wishlist_provider.dart';
import 'package:vishal_gold/screens/cart/cart_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _quantity = 1;

  void _incrementQuantity() => setState(() => _quantity++);
  void _decrementQuantity() {
    if (_quantity > 1) setState(() => _quantity--);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Full Screen Image Slider
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            width: double.infinity,
            child: widget.product.imageUrls.isNotEmpty
                ? PageView.builder(
                    itemCount: widget.product.imageUrls.length,
                    itemBuilder: (context, index) {
                      final url = widget.product.imageUrls[index];
                      return url.toLowerCase().contains('assets/')
                          ? Image.asset(url.trim(), fit: BoxFit.cover)
                          : CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: AppColors.black,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AppColors.gold,
                                  ),
                                ),
                              ),
                            );
                    },
                  )
                : Container(color: AppColors.black),
          ),

          // Custom Back Button & Actions
          Positioned(
            top: 50,
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

          // Sliding Sheet Content
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: MediaQuery.of(context).size.height * 0.55,
              padding: const EdgeInsets.fromLTRB(24, 30, 24, 20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(40),
                  topRight: Radius.circular(40),
                ),
                boxShadow: [
                  BoxShadow(
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
                        color: AppColors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title & Purity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                          color: AppColors.gold.withOpacity(0.15),
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

                  // Specs Grid
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
                      _buildSpecItem('Purity', '${widget.product.purity}%'),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Actions
                  const Spacer(),
                  _buildBottomActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback onPressed,
    Color color = AppColors.black,
  }) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.white.withOpacity(0.9), // Glassy effect on image
          shape: BoxShape.circle,
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        child: Icon(icon, color: color, size: 22),
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
            border: Border.all(color: AppColors.grey.withOpacity(0.1)),
          ),
          child: Row(
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
        // Add to Cart Button
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
                  for (int i = 0; i < _quantity; i++)
                    await cartProvider.addToCart(widget.product);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
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
