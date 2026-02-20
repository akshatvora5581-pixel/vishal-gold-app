import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/providers/auth_provider.dart';
import 'package:vishal_gold/providers/cart_provider.dart';
import 'package:vishal_gold/providers/order_provider.dart';
import 'package:vishal_gold/screens/order/order_confirmation_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<void> _placeOrder(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    if (authProvider.currentUser == null) return;

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          'Confirm Order',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'You are about to place an order for ${cartProvider.itemCount} item(s).\n\nAdmin will be notified and will contact you soon.',
          style: GoogleFonts.outfit(color: AppColors.textPrimary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'CANCEL',
              style: GoogleFonts.outfit(color: AppColors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: AppColors.black,
            ),
            child: Text(
              'CONFIRM',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final orderId = await orderProvider.createOrder(
      userId: authProvider.currentUser!.uid,
      cartItems: cartProvider.items,
    );

    if (!context.mounted) return;

    if (orderId != null) {
      await cartProvider.clearCart();
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => OrderConfirmationScreen(orderId: orderId),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(orderProvider.error ?? 'Failed to place order'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'MY CART',
          style: GoogleFonts.playfairDisplay(
            color: AppColors.gold,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: AppColors.white),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, child) {
          if (cartProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.gold),
            );
          }

          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_bag_outlined,
                    size: 80,
                    // ignore: deprecated_member_use
                    color: AppColors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Your Cart is Empty',
                    style: GoogleFonts.playfairDisplay(
                      color: AppColors.textSecondary,
                      fontSize: 24,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Explore our exclusive collection',
                    style: GoogleFonts.outfit(
                      color: AppColors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 30),
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.gold),
                      foregroundColor: AppColors.gold,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 15,
                      ),
                    ),
                    child: const Text('BROWSE DESIGNS'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: cartProvider.items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final cartItem = cartProvider.items[index];
                    final product = cartItem.product;

                    if (product == null) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          // ignore: deprecated_member_use
                          color: AppColors.grey.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: product.imageUrls.isNotEmpty
                                ? (product.imageUrls.first
                                          .toLowerCase()
                                          .contains('assets/')
                                      ? Image.asset(
                                          product.imageUrls.first.trim(),
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                        )
                                      : CachedNetworkImage(
                                          imageUrl: product.imageUrls.first,
                                          width: 90,
                                          height: 90,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(color: AppColors.black),
                                        ))
                                : Container(
                                    width: 90,
                                    height: 90,
                                    color: AppColors.black,
                                  ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.tagNumber,
                                  style: GoogleFonts.playfairDisplay(
                                    color: AppColors.gold,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.categoryDisplay,
                                  style: GoogleFonts.outfit(
                                    color: AppColors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      decoration: BoxDecoration(
                                        color: AppColors.black,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          IconButton(
                                            onPressed: () =>
                                                cartProvider.updateQuantity(
                                                  cartItem.productId,
                                                  cartItem.quantity - 1,
                                                ),
                                            icon: const Icon(
                                              Icons.remove,
                                              color: AppColors.gold,
                                              size: 16,
                                            ),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                          Text(
                                            '${cartItem.quantity}',
                                            style: GoogleFonts.outfit(
                                              color: AppColors.white,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          IconButton(
                                            onPressed: () =>
                                                cartProvider.updateQuantity(
                                                  cartItem.productId,
                                                  cartItem.quantity + 1,
                                                ),
                                            icon: const Icon(
                                              Icons.add,
                                              color: AppColors.gold,
                                              size: 16,
                                            ),
                                            constraints: const BoxConstraints(),
                                            padding: const EdgeInsets.all(8),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      onPressed: () => cartProvider
                                          .removeFromCart(cartItem.productId),
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.errorRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      // ignore: deprecated_member_use
                      color: Colors.black.withOpacity(0.5),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'TOTAL ITEMS',
                            style: GoogleFonts.outfit(
                              color: AppColors.grey,
                              letterSpacing: 1.2,
                            ),
                          ),
                          Text(
                            '${cartProvider.itemCount}',
                            style: GoogleFonts.playfairDisplay(
                              color: AppColors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () => _placeOrder(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.gold,
                            foregroundColor: AppColors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                          ),
                          child: Text(
                            'PLACE ORDER',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
