import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vishal_gold/constants/app_colors.dart';
import 'package:vishal_gold/screens/home/home_screen.dart';
import 'package:vishal_gold/screens/order/order_detail_screen.dart';

class OrderConfirmationScreen extends StatelessWidget {
  final String orderId;

  const OrderConfirmationScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Success Icon
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    size: 60,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // Success Message
                Text(
                  'Order Placed Successfully!',
                  style: GoogleFonts.montserrat(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.oliveGreen,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // Order Number
                Text(
                  'Order ID:',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  orderId.substring(0, 8).toUpperCase(),
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.black,
                  ),
                ),
                const SizedBox(height: 24),

                // Message
                Text(
                  'Our admin will contact you shortly to confirm the order.',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: AppColors.grey,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                // View Order Details Button
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            OrderDetailScreen(orderId: orderId),
                      ),
                    );
                  },
                  child: const Text('View Order Details'),
                ),
                const SizedBox(height: 12),

                // Continue Shopping Button
                OutlinedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.oliveGreen),
                    minimumSize: const Size(double.infinity, 50),
                  ),
                  child: const Text(
                    'Continue Shopping',
                    style: TextStyle(color: AppColors.oliveGreen),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
